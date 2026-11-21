import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Silent alpha loop for result-dialog characters. Flutter shares the decoder
/// and releases the widget's stream listeners/images when the dialog closes.
class ResultNovaLoop extends StatefulWidget {
  const ResultNovaLoop({
    super.key,
    required this.size,
    required this.image,
    required this.posterAsset,
  });
  final double size;
  final ImageProvider image;
  final String posterAsset;

  @override
  State<ResultNovaLoop> createState() => _ResultNovaLoopState();
}

class _ResultNovaLoopState extends State<ResultNovaLoop> {
  late final AppLifecycleListener _lifecycle;
  bool _foreground = true;
  AssetBundle? _bundle;

  @override
  void initState() {
    super.initState();
    _foreground =
        (WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed) ==
        AppLifecycleState.resumed;
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        final foreground = state == AppLifecycleState.resumed;
        if (mounted && foreground != _foreground) {
          setState(() => _foreground = foreground);
        }
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bundle = DefaultAssetBundle.of(context);
    if (!identical(_bundle, bundle)) {
      _bundle = bundle;
      unawaited(precacheImage(AssetImage(widget.posterAsset), context));
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final poster = Image.asset(
      widget.posterAsset,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      excludeFromSemantics: true,
    );
    return SizedBox.square(
      dimension: widget.size,
      child: RepaintBoundary(
        child: TickerMode(
          enabled:
              _foreground &&
              TickerMode.valuesOf(context).enabled &&
              (ModalRoute.isCurrentOf(context) ?? true),
          child: reduced
              ? poster
              : Image(
                  image: widget.image,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                  excludeFromSemantics: true,
                  frameBuilder: (context, child, frame, synchronous) =>
                      frame == null ? poster : child,
                ),
        ),
      ),
    );
  }
}

/// Asset and speed form a distinct cache key for each result loop. The original
/// pixels, frame order, repeat count and native decoder ownership are retained.
class ResultNovaImage
    extends ImageProvider<({AssetBundleImageKey asset, double speed})> {
  const ResultNovaImage({required this.asset, required this.debugLabel});
  final String asset;
  final String debugLabel;

  @override
  Future<({AssetBundleImageKey asset, double speed})> obtainKey(
    ImageConfiguration configuration,
  ) =>
      AssetImage(asset)
          .obtainKey(configuration)
          .then((asset) => (asset: asset, speed: 1.15));

  @override
  ImageStreamCompleter loadImage(
    ({AssetBundleImageKey asset, double speed}) key,
    ImageDecoderCallback decode,
  ) => MultiFrameImageStreamCompleter(
    codec: _load(key, decode),
    scale: key.asset.scale,
    debugLabel: debugLabel,
  );

  Future<ui.Codec> _load(
    ({AssetBundleImageKey asset, double speed}) key,
    ImageDecoderCallback decode,
  ) async {
    final buffer = await key.asset.bundle.loadBuffer(key.asset.name);
    return _TimedCodec(await decode(buffer), key.speed);
  }
}

class _TimedCodec implements ui.Codec {
  _TimedCodec(this.source, this.speed);
  final ui.Codec source;
  final double speed;

  @override
  int get frameCount => source.frameCount;
  @override
  int get repetitionCount => source.repetitionCount;
  @override
  Future<ui.FrameInfo> getNextFrame() async =>
      _TimedFrame(await source.getNextFrame(), speed);
  @override
  void dispose() => source.dispose();
}

class _TimedFrame implements ui.FrameInfo {
  _TimedFrame(this.source, this.speed);
  final ui.FrameInfo source;
  final double speed;

  @override
  ui.Image get image => source.image;
  @override
  Duration get duration =>
      Duration(microseconds: (source.duration.inMicroseconds / speed).round());
}
