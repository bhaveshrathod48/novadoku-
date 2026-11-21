import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/constants/app_assets.dart';

/// One native animated-image stream for all board portraits. Each cell listens
/// only to its current image; game state and the silhouette tab never rebuild.
class GameplayNovaPlayback extends StatefulWidget {
  const GameplayNovaPlayback({super.key, required this.child});
  final Widget child;

  @override
  State<GameplayNovaPlayback> createState() => _GameplayNovaPlaybackState();
}

class _GameplayNovaPlaybackState extends State<GameplayNovaPlayback> {
  final _frame = ValueNotifier<ImageInfo?>(null);
  late final AppLifecycleListener _lifecycle;
  late final ImageStreamListener _listener;
  ImageStream? _stream;
  ImageStreamCompleterHandle? _keepAlive;
  bool _attached = false, _foreground = true;
  bool _reduced = false;

  @override
  void initState() {
    super.initState();
    _foreground =
        (WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed) ==
        AppLifecycleState.resumed;
    _listener = ImageStreamListener(
      (image, _) {
        // Asset manifest/key resolution can be asynchronous on a cold launch.
        // Retain the decoder only once the stream actually has a completer.
        _keepAlive ??= _stream?.completer?.keepAlive();
        final previous = _frame.value;
        _frame.value = image;
        previous?.dispose();
        _sync();
      },
      onError: (Object error, StackTrace? stack) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stack,
            library: 'novadoku Gameplay alpha playback',
          ),
        );
      },
    );
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        _foreground = state == AppLifecycleState.resumed;
        if (mounted) _sync();
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context);
    final next = const AssetImage(AppAssets.gameplayNovaLoop)
        .resolve(createLocalImageConfiguration(context));
    if (_stream?.key != next.key) {
      _detach();
      _keepAlive?.dispose();
      _keepAlive = next.completer?.keepAlive();
      _stream = next;
      unawaited(
        precacheImage(const AssetImage(AppAssets.gameplayNovaStill), context),
      );
    }
    _sync();
  }

  void _detach() {
    if (_attached) _stream?.removeListener(_listener);
    _attached = false;
  }

  void _sync() {
    _keepAlive ??= _stream?.completer?.keepAlive();
    final active =
        _foreground &&
        !_reduced &&
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true);
    // While unresolved, keep one bootstrap listener even if already paused.
    // Its first callback retains the decoder and immediately detaches again,
    // so cache eviction cannot leave resume pointing at a disposed completer.
    final listen = active || (_stream != null && _keepAlive == null);
    if (listen && !_attached) {
      _attached = true;
      _stream?.addListener(_listener);
    } else if (!listen) {
      _detach();
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _detach();
    _keepAlive?.dispose();
    _frame.value?.dispose();
    _frame.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _NovaFrames(frames: _frame, reduced: _reduced, child: widget.child);
}

class _NovaFrames extends InheritedWidget {
  const _NovaFrames({
    required this.frames,
    required this.reduced,
    required super.child,
  });
  final ValueNotifier<ImageInfo?> frames;
  final bool reduced;

  @override
  bool updateShouldNotify(_NovaFrames oldWidget) =>
      frames != oldWidget.frames || reduced != oldWidget.reduced;
}

class GameplayNovaImage extends StatelessWidget {
  const GameplayNovaImage({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_NovaFrames>()!;
    final still = Image.asset(
      AppAssets.gameplayNovaStill,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      excludeFromSemantics: true,
    );
    if (scope.reduced) return Transform.scale(scale: .92, child: still);
    return ValueListenableBuilder<ImageInfo?>(
      valueListenable: scope.frames,
      child: still,
      builder: (context, frame, poster) => Transform.scale(
        scale: .92,
        child: RepaintBoundary(
          child: frame == null
              ? poster
              : RawImage(
                  image: frame.image,
                  fit: BoxFit.contain,
                  debugImageLabel: 'Gameplay Nova shared loop',
                ),
        ),
      ),
    );
  }
}
