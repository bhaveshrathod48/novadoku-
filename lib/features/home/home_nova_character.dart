import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../core/constants/app_assets.dart';
import '../../shared/characters/nova_assets.dart';
import '../../shared/characters/nova_character.dart';

/// Home-only alpha WebP playback. Both codecs are primed before motion starts;
/// each keeps only its displayed and next decoded frame, never a frame list.
class HomeNovaCharacter extends StatefulWidget {
  const HomeNovaCharacter({
    super.key,
    required this.controller,
    required this.size,
    this.onBusyChanged,
  });
  final NovaCharacterController controller;
  final double size;
  final ValueChanged<bool>? onBusyChanged;

  @override
  State<HomeNovaCharacter> createState() => _HomeNovaCharacterState();
}

typedef _Frame = ({ui.Image image, bool jump, int index, int count});

class _HomeNovaCharacterState extends State<HomeNovaCharacter> {
  final _frame = ValueNotifier<_Frame?>(null);
  late final AppLifecycleListener _lifecycle;
  AssetBundle? _bundle;
  _Clip? _idle, _jump, _active;
  Timer? _timer;
  int _loadEpoch = 0, _clockEpoch = 0;
  bool _foreground = true, _visible = true, _reduced = false;
  bool _pending = false, _jumping = false, _reportedBusy = false;
  bool _advancing = false, _happy = false, _failed = false;
  double? _idleRushSpeed;

  Duration _frameDuration() {
    final clip = _active!;
    var speed = _jumping ? 1.20 : 1.15;
    if (_pending && !_jumping) {
      // Finish the remaining poses in about 300 ms. Near the cycle boundary,
      // keep normal speed rather than slowing down to manufacture a delay.
      speed = _idleRushSpeed ??=
          ((clip.codec.frameCount - clip.index) *
                  clip.current.duration.inMicroseconds /
                  300000)
              .clamp(1.15, double.infinity);
    }
    return Duration(
      microseconds: (clip.current.duration.inMicroseconds / speed).round(),
    );
  }

  bool get _busy => _pending || _jumping;
  bool get _canPlay =>
      mounted && _visible && !_reduced && !_failed && _active != null;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onCommand);
    _foreground =
        (WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed) ==
        AppLifecycleState.resumed;
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        final foreground = state == AppLifecycleState.resumed;
        if (mounted && foreground != _foreground) {
          setState(() => _foreground = foreground);
          _refreshVisibility();
        }
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced && !_reduced) _cancelReaction();
    _reduced = reduced;
    if (!reduced) _happy = false;
    final bundle = DefaultAssetBundle.of(context);
    if (!identical(bundle, _bundle)) {
      _bundle = bundle;
      unawaited(
        precacheImage(const AssetImage(AppAssets.homeNovaStill), context),
      );
      unawaited(_load(bundle));
    }
    _refreshVisibility();
  }

  Future<void> _load(AssetBundle bundle) async {
    final epoch = ++_loadEpoch;
    final opened = <_Clip>[];
    try {
      final clips = await Future.wait([
        for (final asset in [AppAssets.homeNovaLoop, AppAssets.homeNovaJump])
          _Clip.open(bundle, asset).then((clip) {
            opened.add(clip);
            return clip;
          }),
      ]);
      if (!mounted || epoch != _loadEpoch) {
        for (final clip in opened) {
          clip.dispose();
        }
        return;
      }
      _stopClock();
      _idle?.dispose();
      _jump?.dispose();
      _idle = clips[0];
      _jump = clips[1];
      _active = _idle;
      _failed = false;
      _publish();
      _schedule();
    } catch (error, stack) {
      for (final clip in opened) {
        clip.dispose();
      }
      if (mounted && epoch == _loadEpoch) _fail(error, stack);
    }
  }

  void _refreshVisibility() {
    _visible =
        _foreground &&
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true);
    if (!_canPlay) {
      _stopClock();
    } else {
      _schedule();
    }
  }

  void _stopClock() {
    _timer?.cancel();
    _timer = null;
    _clockEpoch++;
  }

  void _schedule() {
    if (!_canPlay || _timer != null || _advancing) return;
    final epoch = _clockEpoch;
    _timer = Timer(_frameDuration(), () {
      _timer = null;
      unawaited(_advance(epoch));
    });
  }

  Future<void> _advance(int epoch) async {
    _advancing = true;
    final clip = _active!;
    try {
      await clip.prepareNext();
      if (!_canPlay || epoch != _clockEpoch || !identical(clip, _active)) {
        return;
      }
      if (clip.last && !_jumping && _pending && _jump == null) return;
      final boundary = clip.last;
      clip.advance();
      _prefetch(clip);
      if (boundary && _jumping) {
        // Both clips park on frame zero while the other plays, so returning
        // never needs an asset read, seek or decoder creation at the boundary.
        _jumping = false;
        _active = _idle;
        _notifyBusy();
      } else if (boundary && _pending) {
        _pending = false;
        _idleRushSpeed = null;
        _jumping = true;
        _active = _jump;
      }
      _publish();
    } catch (error, stack) {
      if (mounted && epoch == _clockEpoch) _fail(error, stack);
    } finally {
      _advancing = false;
      _schedule();
    }
  }

  void _prefetch(_Clip clip) {
    unawaited(
      clip.prepareNext().catchError((Object error, StackTrace stack) {
        if (mounted && (identical(clip, _idle) || identical(clip, _jump))) {
          _fail(error, stack);
        }
      }),
    );
  }

  void _publish() {
    final clip = _active;
    if (clip != null) {
      _frame.value = (
        image: clip.current.image,
        jump: _jumping,
        index: clip.index,
        count: clip.codec.frameCount,
      );
    }
  }

  void _onCommand() {
    if (_failed ||
        _busy ||
        widget.controller.value.expression == NovaExpression.idle) {
      return;
    }
    if (_reduced) {
      setState(() => _happy = true);
    } else {
      _happy = false;
      _pending = true;
      _notifyBusy();
      // Replace the current normal-speed hold immediately, without changing
      // its frame or queuing a second clock if a decode is already in flight.
      _stopClock();
      _schedule();
    }
  }

  void _notifyBusy() {
    final busy = _busy;
    if (busy == _reportedBusy) return;
    _reportedBusy = busy;
    void notify() {
      if (mounted && _busy == busy) widget.onBusyChanged?.call(busy);
    }

    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => notify());
    } else {
      notify();
    }
  }

  void _cancelReaction() {
    _stopClock();
    _pending = false;
    _idleRushSpeed = null;
    if (_jumping) {
      _jumping = false;
      _active = _idle;
      _publish();
      final old = _jump;
      _jump = null;
      old?.dispose();
      final epoch = _loadEpoch;
      final bundle = _bundle;
      if (bundle != null) {
        unawaited(
          _Clip.open(bundle, AppAssets.homeNovaJump)
              .then((clip) {
                if (!mounted || epoch != _loadEpoch) {
                  clip.dispose();
                } else {
                  _jump = clip;
                }
              })
              .catchError((Object error, StackTrace stack) {
                if (mounted && epoch == _loadEpoch) _fail(error, stack);
              }),
        );
      }
    }
    _notifyBusy();
  }

  void _fail(Object error, StackTrace stack) {
    _failed = true;
    _stopClock();
    _pending = false;
    _jumping = false;
    _notifyBusy();
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'novadoku Home alpha playback',
      ),
    );
  }

  @override
  void didUpdateWidget(covariant HomeNovaCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onCommand);
      _cancelReaction();
      widget.controller.addListener(_onCommand);
      _refreshVisibility();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onCommand);
    _lifecycle.dispose();
    _loadEpoch++;
    _stopClock();
    _idle?.dispose();
    _jump?.dispose();
    _frame.dispose();
    super.dispose();
  }

  Rect _idleRect() {
    final side = widget.size;
    final fitted = applyBoxFit(
      BoxFit.contain,
      const Size(432, 512),
      Size.square(side * .865),
    );
    return Rect.fromCenter(
      center: Offset(side / 2, side * (.5 - .016)),
      width: fitted.destination.width,
      height: fitted.destination.height,
    );
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: widget.size,
    child: TickerMode(
      enabled: _visible,
      child: _reduced && _happy
          ? NovaCharacter(
              expression: NovaExpression.happy,
              size: widget.size,
              loadingArtwork: NovaArtwork.fullBody,
            )
          : ValueListenableBuilder<_Frame?>(
              valueListenable: _frame,
              builder: (context, frame, _) {
                final idle = _idleRect();
                // Extend the jump canvas, not the character scale. Both video
                // crops use the same original source coordinates and baseline.
                final scale = idle.height / 1108;
                final destination = frame?.jump == true && !_reduced
                    ? Rect.fromLTWH(
                        idle.left - 8 * scale,
                        idle.top - 282 * scale,
                        1080 * scale,
                        1392 * scale,
                      )
                    : idle;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fromRect(
                      rect: destination,
                      child: RepaintBoundary(
                        child: frame == null || _reduced
                            ? Image.asset(
                                AppAssets.homeNovaStill,
                                fit: BoxFit.contain,
                                gaplessPlayback: true,
                                excludeFromSemantics: true,
                              )
                            : RawImage(
                                key: ValueKey(
                                  frame.jump
                                      ? 'Home Nova jump'
                                      : 'Home Nova idle',
                                ),
                                image: frame.image,
                                fit: BoxFit.fill,
                                debugImageLabel:
                                    'Home Nova ${frame.jump ? 'jump' : 'idle'} frame ${frame.index}/${frame.count}',
                              ),
                      ),
                    ),
                  ],
                );
              },
            ),
    ),
  );
}

/// One incremental decoder with two owned images. Disposal waits for an
/// in-flight decode; its stale result is released rather than published.
class _Clip {
  _Clip(this.codec, this.current);
  final ui.Codec codec;
  ui.FrameInfo current;
  ui.FrameInfo? _next;
  Future<void>? _work;
  int index = 0;
  bool _disposed = false;
  bool get last => index == codec.frameCount - 1;

  static Future<_Clip> open(AssetBundle bundle, String asset) async {
    final data = await bundle.load(asset);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    _Clip? clip;
    try {
      if (codec.frameCount < 2) {
        throw FormatException('Expected animated Home asset: $asset');
      }
      clip = _Clip(codec, await codec.getNextFrame());
      if (clip.current.duration <= Duration.zero) {
        throw FormatException('Invalid Home frame duration: $asset');
      }
      await clip.prepareNext();
      return clip;
    } catch (_) {
      if (clip == null) {
        codec.dispose();
      } else {
        clip.dispose();
      }
      rethrow;
    }
  }

  Future<void> prepareNext() {
    if (_disposed || _next != null) return Future.value();
    return _work ??= _decode();
  }

  Future<void> _decode() async {
    try {
      final frame = await codec.getNextFrame();
      if (_disposed) {
        frame.image.dispose();
      } else {
        if (frame.duration <= Duration.zero) {
          frame.image.dispose();
          throw const FormatException('Invalid Home frame duration.');
        }
        _next = frame;
      }
    } finally {
      _work = null;
    }
  }

  void advance() {
    final previous = current;
    current = _next!;
    _next = null;
    index = (index + 1) % codec.frameCount;
    previous.image.dispose();
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    current.image.dispose();
    _next?.image.dispose();
    final pending = _work;
    if (pending == null) {
      codec.dispose();
    } else {
      unawaited(
        pending.then(
          (_) => codec.dispose(),
          onError: (Object _, StackTrace _) => codec.dispose(),
        ),
      );
    }
  }
}
