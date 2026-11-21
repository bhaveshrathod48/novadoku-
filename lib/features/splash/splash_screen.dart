import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The supplied artwork is a single unchanged atlas. Clipped source bands
/// provide independent entrances without redrawing Nova or the lettering.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.onPainted});
  final VoidCallback onPainted;
  static const asset = 'assets/images/splash/welcome.png';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;
  late final AppLifecycleListener _lifecycle;
  late final ImageStreamListener _listener;
  ImageStream? _stream;
  ImageInfo? _image;
  bool _announced = false, _reduced = false;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        if (state == AppLifecycleState.resumed && !_reduced && _image != null) {
          _motion.forward();
        } else if (state != AppLifecycleState.resumed) {
          _motion.stop();
        }
      },
    );
    _listener = ImageStreamListener(
      (image, _) {
        final old = _image;
        setState(() => _image = image);
        old?.dispose();
        if (_reduced) {
          _motion.value = 1;
        } else {
          _motion.forward();
        }
        _announce();
      },
      onError: (Object error, StackTrace? stack) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stack,
            library: 'novadoku splash artwork',
          ),
        );
        _announce(); // A damaged install must not trap the app at startup.
      },
    );
  }

  void _announce() {
    if (_announced) return;
    _announced = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onPainted();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.disableAnimationsOf(context);
    if (_reduced) _motion.value = 1;
    final next = const AssetImage(SplashScreen.asset)
        .resolve(createLocalImageConfiguration(context));
    if (next.key != _stream?.key) {
      _stream?.removeListener(_listener);
      _stream = next;
      next.addListener(_listener);
    }
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _image?.dispose();
    _motion.dispose();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,
    ),
    child: Semantics(
      image: true,
      label: 'Welcome to Novadoku. Solve • Split • Relax.',
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _SplashPainter(_image?.image, _motion),
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );
}

class _SplashPainter extends CustomPainter {
  _SplashPainter(this.image, this.motion) : super(repaint: motion);
  final ui.Image? image;
  final Animation<double> motion;
  static const canvasSize = Size(941, 1670);

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const RadialGradient(
          radius: 1.1,
          colors: [Color(0xFFFAF1FF), Color(0xFFE3D3FC)],
        ).createShader(bounds),
    );
    final image = this.image;
    if (image == null) return;
    final scale = math.min(
      size.width / canvasSize.width,
      size.height / canvasSize.height,
    );
    final width = canvasSize.width * scale, height = canvasSize.height * scale;
    final origin = Offset((size.width - width) / 2, (size.height - height) / 2);
    final paint = Paint()..filterQuality = FilterQuality.medium;
    // Extend background edge pixels into extra-tall/wide screen space. The
    // supplied composition is always contained, never cropped or stretched.
    if (origin.dy > 0) {
      canvas.drawImageRect(
        image,
        const Rect.fromLTWH(0, 0, 941, 1),
        Rect.fromLTWH(origin.dx, 0, width, origin.dy),
        paint,
      );
      canvas.drawImageRect(
        image,
        const Rect.fromLTWH(0, 1669, 941, 1),
        Rect.fromLTWH(origin.dx, origin.dy + height, width, origin.dy),
        paint,
      );
    }
    if (origin.dx > 0) {
      canvas.drawImageRect(
        image,
        const Rect.fromLTWH(0, 0, 1, 1670),
        Rect.fromLTWH(0, origin.dy, origin.dx, height),
        paint,
      );
      canvas.drawImageRect(
        image,
        const Rect.fromLTWH(940, 0, 1, 1670),
        Rect.fromLTWH(origin.dx + width, origin.dy, origin.dx, height),
        paint,
      );
    }
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.scale(scale);
    final ms = motion.value * 2500;
    double entrance(double delay, double duration) => Curves.easeOutCubic
        .transform(((ms - delay) / duration).clamp(0.0, 1.0));
    final ribbon = entrance(0, 480),
        logo = entrance(130, 540),
        nova = entrance(260, 650);
    if (ms >= 1090) {
      canvas.drawImageRect(
        image,
        Offset.zero & canvasSize,
        Offset.zero & canvasSize,
        paint,
      );
    } else {
      _band(canvas, image, 0, 215, 1, 1, 0);
      _band(canvas, image, 195, 377, ribbon, 1, -24 * (1 - ribbon));
      _band(canvas, image, 353, 630, logo, .94 + .06 * logo, 0);
      _band(canvas, image, 606, 1374, nova, .98 + .02 * nova, 28 * (1 - nova));
      _band(canvas, image, 1350, 1670, 1, 1, 0);
      if (ms > 910) {
        canvas.drawImageRect(
          image,
          Offset.zero & canvasSize,
          Offset.zero & canvasSize,
          Paint()
            ..filterQuality = FilterQuality.medium
            ..color = Colors.white.withValues(alpha: entrance(910, 180)),
        );
      }
    }
    if (ms >= 1090 && motion.value < 1) {
      final float = math.sin(motion.value * math.pi * 2) * 2;
      _band(canvas, image, 0, 195, 1, 1, float);
      _band(canvas, image, 1374, 1670, 1, 1, -float);
    }
    canvas.restore();
  }

  void _band(
    Canvas canvas,
    ui.Image image,
    double top,
    double bottom,
    double opacity,
    double scale,
    double dy,
  ) {
    if (opacity <= 0) return;
    final rect = Rect.fromLTRB(0, top, canvasSize.width, bottom);
    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy + dy);
    canvas.scale(scale);
    canvas.translate(-rect.center.dx, -rect.center.dy);
    canvas.saveLayer(
      rect,
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
    canvas.drawImageRect(
      image,
      rect,
      rect,
      Paint()..filterQuality = FilterQuality.medium,
    );
    final feather = math.min(16 / rect.height, .2);
    canvas.drawRect(
      rect,
      Paint()
        ..blendMode = BlendMode.dstIn
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Colors.transparent,
            Colors.white,
            Colors.white,
            Colors.transparent,
          ],
          stops: [0, feather, 1 - feather, 1],
        ).createShader(rect),
    );
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SplashPainter oldDelegate) => image != oldDelegate.image;
}
