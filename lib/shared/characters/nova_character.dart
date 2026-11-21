import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../l10n/nova_localizations.dart';

import '../../core/animations/app_motion.dart';
import '../../core/theme/app_tokens.dart';
import 'nova_assets.dart';

@immutable
final class NovaPlayback {
  const NovaPlayback(this.expression, {this.then});

  final NovaExpression expression;
  final NovaExpression? then;
}

/// Each command starts a new playback, including repeated reactions.
final class NovaCharacterController extends ValueNotifier<NovaPlayback> {
  NovaCharacterController([NovaExpression initial = NovaExpression.idle])
    : super(NovaPlayback(initial));

  void play(NovaExpression expression, {NovaExpression? then}) {
    value = NovaPlayback(expression, then: then);
  }
}

class NovaCharacter extends StatefulWidget {
  const NovaCharacter({
    super.key,
    this.expression = NovaExpression.idle,
    this.controller,
    this.size = AppTokens.characterResultSize,
    this.animate = true,
    this.loadingArtwork,
    this.semanticLabel,
    this.onCompleted,
    this.onAssetError,
  });

  final NovaExpression expression;
  final NovaCharacterController? controller;
  final double size;
  final bool animate;
  final NovaArtwork? loadingArtwork;
  final String? semanticLabel;
  final ValueChanged<NovaExpression>? onCompleted;
  final ImageErrorListener? onAssetError;

  @override
  State<NovaCharacter> createState() => _NovaCharacterState();
}

typedef _Load = ({ImageStream stream, ImageStreamListener listener});
typedef _FrozenPose = ({ImageInfo image, int frame});

class _NovaCharacterState extends State<NovaCharacter>
    with TickerProviderStateMixin {
  late final AnimationController _timeline;
  late final AnimationController _fade;
  final _pose = ValueNotifier<NovaPose>((frame: 0, next: 0, blendStep: 0));
  late final Listenable _paintTicks = Listenable.merge([_pose, _fade]);

  late NovaPlayback _requested;
  NovaPlayback? _current;
  AssetBundle? _bundle;
  ImageInfo? _image;
  _FrozenPose? _outgoing;
  _Load? _load;
  bool _reduced = false;
  bool _finished = false;

  bool get _shouldAnimate => widget.animate && !_reduced;

  @override
  void initState() {
    super.initState();
    _timeline =
        AnimationController(
            vsync: this,
            animationBehavior: AnimationBehavior.preserve,
          )
          ..addListener(_onTimelineTick)
          ..addStatusListener(_onTimelineStatus);
    _fade = AnimationController(
      vsync: this,
      duration: AppMotion.fadeDuration,
      animationBehavior: AnimationBehavior.preserve,
    )..addStatusListener(_onFadeStatus);
    _requested = widget.controller?.value ?? NovaPlayback(widget.expression);
    widget.controller?.addListener(_onCommand);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bundle = DefaultAssetBundle.of(context);
    final reduced = MediaQuery.disableAnimationsOf(context);
    final motionChanged = reduced != _reduced;
    _reduced = reduced;
    if (!identical(bundle, _bundle)) {
      _bundle = bundle;
      _request(_requested);
    } else if (motionChanged) {
      _refreshMotion();
    }
  }

  @override
  void didUpdateWidget(covariant NovaCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onCommand);
      widget.controller?.addListener(_onCommand);
      _request(widget.controller?.value ?? NovaPlayback(widget.expression));
    } else if (widget.controller == null &&
        oldWidget.expression != widget.expression) {
      _request(NovaPlayback(widget.expression));
    }
    if (oldWidget.animate != widget.animate) _refreshMotion();
  }

  void _onCommand() => _request(widget.controller!.value);

  void _request(NovaPlayback playback) {
    _requested = playback;
    _detachLoad();
    final stream = playback.expression.image.resolve(
      createLocalImageConfiguration(context),
    );
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (!mounted || !identical(_load?.listener, listener)) {
          info.dispose();
          return;
        }
        _detachLoad();
        if (info.image.width != info.image.height || info.image.width.isOdd) {
          info.dispose();
          _reportAssetError(
            StateError('Invalid Nova atlas: ${playback.expression.asset}'),
            null,
          );
          return;
        }
        _show(playback, info);
      },
      onError: (error, trace) {
        if (!mounted || !identical(_load?.listener, listener)) return;
        _detachLoad();
        _reportAssetError(error, trace);
      },
    );
    _load = (stream: stream, listener: listener);
    stream.addListener(listener);
  }

  void _reportAssetError(Object error, StackTrace? trace) {
    _timeline.stop();
    _fade.stop();
    setState(() {
      _discardOutgoing();
      _image?.dispose();
      _image = null;
      _current = null;
    });
    final listener = widget.onAssetError;
    if (listener != null) {
      listener(error, trace);
    } else {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: trace,
          library: 'novadoku character assets',
          context: ErrorDescription(
            'while loading ${_requested.expression.asset}',
          ),
        ),
      );
    }
  }

  void _show(NovaPlayback playback, ImageInfo image) {
    _timeline.stop();
    _fade.stop();
    final previous = _image;
    final expression = _current?.expression;
    final blend =
        _shouldAnimate && previous != null && expression != playback.expression;
    setState(() {
      _discardOutgoing();
      if (previous != null) {
        if (blend) {
          final pose = _pose.value;
          final frame = pose.blendStep > NovaExpression.blendSteps / 2
              ? pose.next
              : pose.frame;
          _outgoing = (image: previous, frame: frame);
        } else {
          previous.dispose();
        }
      }
      _image = image;
      _current = playback;
      _finished = false;
    });
    if (blend) _fade.forward(from: 0);
    _startTimeline();
  }

  void _refreshMotion() {
    _fade.stop();
    _discardOutgoing();
    _startTimeline();
  }

  void _startTimeline() {
    _timeline.stop();
    final clip = _current?.expression;
    if (clip == null) return;
    if (!_shouldAnimate) {
      _showStill(clip.stillFrame);
      return;
    }
    if (_finished) {
      _showStill(clip.frameAt(clip.duration));
      return;
    }
    _showStill(0);
    _timeline.duration = clip.duration;
    if (clip.loop) {
      _timeline.value = 0;
      _timeline.repeat();
    } else {
      _timeline.forward(from: 0);
    }
  }

  void _showStill(int frame) =>
      _pose.value = (frame: frame, next: frame, blendStep: 0);

  void _onTimelineTick() {
    final clip = _current?.expression;
    if (clip != null) {
      final elapsed = Duration(
        microseconds: (_timeline.value * _timeline.duration!.inMicroseconds)
            .round(),
      );
      _pose.value = clip.poseAt(elapsed);
    }
  }

  void _onTimelineStatus(AnimationStatus status) {
    final playing = _current;
    if (status != AnimationStatus.completed ||
        playing == null ||
        playing.expression.loop ||
        !identical(playing, _requested)) {
      return;
    }
    _finished = true;
    widget.onCompleted?.call(playing.expression);
    final next = playing.then;
    if (next != null && mounted && identical(playing, _requested)) {
      _request(NovaPlayback(next));
    }
  }

  void _onFadeStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _outgoing != null) {
      setState(_discardOutgoing);
    }
  }

  void _discardOutgoing() {
    _outgoing?.image.dispose();
    _outgoing = null;
  }

  void _detachLoad() {
    final load = _load;
    _load = null;
    if (load != null) load.stream.removeListener(load.listener);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onCommand);
    _detachLoad();
    _timeline.dispose();
    _fade.dispose();
    _pose.dispose();
    _discardOutgoing();
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clip = _current?.expression;
    final loadingArtwork = widget.loadingArtwork;
    Widget sprite = SizedBox.square(
      dimension: widget.size,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _image == null || clip == null
              ? null
              : _NovaPainter(
                  image: _image!,
                  pose: _pose,
                  fade: _fade,
                  outgoing: _outgoing,
                  repaint: _paintTicks,
                ),
          child: _image == null && loadingArtwork != null
              ? NovaArtworkImage(artwork: loadingArtwork)
              : null,
        ),
      ),
    );
    if (widget.semanticLabel case final label?) {
      sprite = Semantics(
        image: true,
        label: localize(context, label),
        child: sprite,
      );
    }
    return sprite;
  }
}

class _NovaPainter extends CustomPainter {
  _NovaPainter({
    required this.image,
    required this.pose,
    required this.fade,
    required this.outgoing,
    required super.repaint,
  });

  final ImageInfo image;
  final ValueListenable<NovaPose> pose;
  final AnimationController fade;
  final _FrozenPose? outgoing;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final destination = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: side,
      height: side,
    );
    final previous = outgoing;
    final progress = previous == null
        ? 1.0
        : AppMotion.enterCurve.transform(fade.value);
    if (previous != null && progress < 1) {
      _draw(canvas, previous.image, previous.frame, destination, 1 - progress);
    }
    final current = pose.value;
    // Keep expression handoffs to two draws. Resume pose interpolation once the
    // outgoing expression has faded.
    final blend = previous == null
        ? AppMotion.enterCurve.transform(
            current.blendStep / NovaExpression.blendSteps,
          )
        : 0.0;
    if (blend < 1) {
      _draw(canvas, image, current.frame, destination, progress * (1 - blend));
    }
    if (blend > 0) _draw(canvas, image, current.next, destination, blend);
  }

  void _draw(
    Canvas canvas,
    ImageInfo info,
    int frame,
    Rect destination,
    double opacity,
  ) {
    final side = info.image.width / 2;
    final source = Rect.fromLTWH(
      (frame % 2) * side,
      (frame ~/ 2) * side,
      side,
      side,
    );
    canvas.drawImageRect(
      info.image,
      source,
      destination,
      Paint()
        ..filterQuality = FilterQuality.low
        ..color = Color.fromRGBO(255, 255, 255, opacity),
    );
  }

  @override
  bool shouldRepaint(covariant _NovaPainter oldDelegate) =>
      image != oldDelegate.image || outgoing != oldDelegate.outgoing;
}
