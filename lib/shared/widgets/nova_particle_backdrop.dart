import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/theme/app_colors.dart';

enum NovaParticleMood { comforting, victory, daily, tutorial, home }

/// Paints only inside the existing hero slot; the video child is never rebuilt
/// by particle ticks, transformed or clipped by this decoration.
class NovaParticleBackdrop extends StatefulWidget {
  const NovaParticleBackdrop({
    super.key,
    required this.mood,
    required this.child,
    this.intensified = false,
  });
  final NovaParticleMood mood;
  final Widget child;
  final bool intensified;
  @override
  State<NovaParticleBackdrop> createState() => _NovaParticleBackdropState();
}

class _NovaParticleBackdropState extends State<NovaParticleBackdrop>
    with TickerProviderStateMixin {
  late final _energy = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    reverseDuration: const Duration(milliseconds: 500),
  );
  late final _clock = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );
  late final AppLifecycleListener _lifecycle;
  bool _foreground = true, _reduced = false;
  @override
  void initState() {
    super.initState();
    _clock.duration = switch (widget.mood) {
      NovaParticleMood.comforting => const Duration(seconds: 10),
      NovaParticleMood.victory => const Duration(seconds: 7),
      NovaParticleMood.daily => const Duration(seconds: 6),
      NovaParticleMood.tutorial => const Duration(seconds: 8),
      NovaParticleMood.home => const Duration(seconds: 9),
    };
    _foreground =
        (WidgetsBinding.instance.lifecycleState ?? AppLifecycleState.resumed) ==
        AppLifecycleState.resumed;
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
    _sync();
  }

  void _sync() {
    final active =
        _foreground &&
        !_reduced &&
        TickerMode.valuesOf(context).enabled &&
        (ModalRoute.isCurrentOf(context) ?? true);
    if (active && !_clock.isAnimating) {
      _clock.repeat();
    }
    if (!active) _clock.stop();
    if (active) {
      _energy.animateTo(
        widget.intensified ? 1 : 0,
        duration: Duration(milliseconds: widget.intensified ? 280 : 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _energy.stop();
      if (_reduced) _energy.value = 0;
    }
  }

  @override
  void didUpdateWidget(covariant NovaParticleBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.intensified != widget.intensified) _sync();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _clock.dispose();
    _energy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: NovaAmbientPainter(
        _clock,
        widget.mood,
        reduced: _reduced,
        energy: _energy,
      ),
      child: widget.child,
    ),
  );
}

typedef _AmbientParticle = ({
  double angle,
  double phase,
  double size,
  double sway,
});

/// Reuses the existing celebration's seeded paths, rings and palette approach,
/// but with gentle looping motion and a protected central portrait area.
class NovaAmbientPainter extends CustomPainter {
  NovaAmbientPainter(
    this.clock,
    this.mood, {
    this.reduced = false,
    this.energy = const AlwaysStoppedAnimation(0),
  }) : super(repaint: Listenable.merge([clock, energy]));
  final Animation<double> energy;
  final Animation<double> clock;
  final NovaParticleMood mood;
  final bool reduced;
  static final List<_AmbientParticle> _particles = List.generate(
    20,
    (i) => (
      angle: i * 2.399963,
      phase: (i * .381966) % 1,
      size: .016 + (i % 3) * .003,
      sway: .03 + (i % 4) * .008,
    ),
  );
  static final _heart = Path()
    ..moveTo(0, .9)
    ..cubicTo(-.25, .7, -1, .1, -1, -.35)
    ..cubicTo(-1, -1, -.3, -1.15, 0, -.65)
    ..cubicTo(.3, -1.15, 1, -1, 1, -.35)
    ..cubicTo(1, .1, .25, .7, 0, .9)
    ..close();
  static final _brokenHeart = Path.combine(
    PathOperation.difference,
    _heart,
    Path()
      ..moveTo(-.04, -1)
      ..lineTo(-.21, -.35)
      ..lineTo(.04, -.03)
      ..lineTo(-.18, .4)
      ..lineTo(-.04, 1)
      ..lineTo(.14, 1)
      ..lineTo(.02, .4)
      ..lineTo(.22, -.03)
      ..lineTo(-.02, -.35)
      ..lineTo(.14, -1)
      ..close(),
  );
  static final _sparkle = Path()
    ..moveTo(0, -1)
    ..quadraticBezierTo(.18, -.18, 1, 0)
    ..quadraticBezierTo(.18, .18, 0, 1)
    ..quadraticBezierTo(-.18, .18, -1, 0)
    ..quadraticBezierTo(-.18, -.18, 0, -1)
    ..close();
  static final _star = _starPath();
  static Path _starPath() {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      final r = i.isEven ? 1.0 : .45;
      if (i == 0) {
        path.moveTo(math.cos(angle) * r, math.sin(angle) * r);
      } else {
        path.lineTo(math.cos(angle) * r, math.sin(angle) * r);
      }
    }
    return path..close();
  }

  static final _paw = Path()
    ..addOval(const Rect.fromLTWH(-.65, -.08, 1.3, .98))
    ..addOval(const Rect.fromLTWH(-1, -.7, .48, .67))
    ..addOval(const Rect.fromLTWH(-.52, -1.1, .48, .7))
    ..addOval(const Rect.fromLTWH(.04, -1.1, .48, .7))
    ..addOval(const Rect.fromLTWH(.52, -.7, .48, .67));
  static const _colors = [
    AppColors.decorGold,
    AppColors.decorStar,
    AppColors.decorMint,
    AppColors.heart,
    AppColors.primaryLight,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final t = reduced ? .35 : clock.value;
    final bounds = Offset.zero & size;
    final unit = size.shortestSide;
    final boost = mood == NovaParticleMood.home && !reduced
        ? energy.value
        : 0.0;
    canvas.save();
    canvas.clipRect(bounds);
    if (mood == NovaParticleMood.victory || mood == NovaParticleMood.home) {
      final home = mood == NovaParticleMood.home;
      final glow = reduced
          ? .1
          : .12 + .035 * math.sin(t * math.pi * 2) + boost * .08;
      canvas.drawOval(
        bounds.deflate(unit * .02),
        Paint()
          ..shader = RadialGradient(
            colors: [
              (home ? AppColors.primaryLight : AppColors.decorGold).withValues(
                alpha: glow,
              ),
              AppColors.primaryEdge.withValues(alpha: glow * .6),
              AppColors.transparent,
            ],
            stops: const [0, .64, 1],
          ).createShader(bounds),
      );
    }
    // Decorative glyphs stay outside the portrait's central silhouette. This
    // clip applies only to paint, never to the character or its moving tail.
    canvas.clipPath(
      Path()
        ..fillType = PathFillType.evenOdd
        ..addRect(bounds)
        ..addOval(
          Rect.fromCenter(
            center: bounds.center,
            width: size.width * .66,
            height: size.height * .8,
          ),
        ),
    );
    final count = switch (mood) {
      NovaParticleMood.comforting => 12,
      NovaParticleMood.victory => 20,
      NovaParticleMood.daily => 16,
      NovaParticleMood.tutorial => 14,
      NovaParticleMood.home => 20,
    };
    final ink = Paint();
    for (var i = 0; i < count; i++) {
      final particle = _particles[i];
      final life = (t + particle.phase) % 1;
      final wave = math.sin(life * math.pi * 2);
      final fade = math.pow(math.sin(life * math.pi), 2).toDouble();
      final angle = particle.angle + wave * .07;
      final point =
          bounds.center +
          Offset(
            math.cos(angle) * size.width * (.44 + wave * particle.sway * .2),
            math.sin(angle) * size.height * .43 - unit * .05 * (life - .5),
          );
      final radius =
          (unit * particle.size).clamp(1.8, 6.0) *
          (.8 + .2 * math.sin(life * math.pi)) *
          (1 + boost * .3);
      final color = switch (mood) {
        NovaParticleMood.comforting =>
          i % 3 == 0 ? AppColors.heart : AppColors.decorStar,
        NovaParticleMood.daily =>
          i.isEven ? AppColors.decorGold : AppColors.primaryLight,
        _ => _colors[i % _colors.length],
      };
      ink
        ..style = PaintingStyle.fill
        ..color = color.withValues(
          alpha:
              fade *
              (reduced
                  ? .35
                  : mood == NovaParticleMood.comforting
                  ? .45
                  : .66) *
              (1 + boost * .45),
        );
      canvas.save();
      canvas.translate(point.dx, point.dy);
      canvas.rotate(wave * .18 + i * .12);
      canvas.scale(radius);
      switch (mood) {
        case NovaParticleMood.home:
          switch (i % 4) {
            case 0:
              canvas.drawPath(_star, ink);
            case 1:
              canvas.drawPath(_sparkle, ink);
            case 2:
              canvas.drawPath(_paw, ink);
            default:
              canvas.drawCircle(
                Offset.zero,
                1.25,
                ink..color = color.withValues(alpha: fade * (.1 + boost * .06)),
              );
              canvas.drawCircle(
                Offset.zero,
                .45,
                ink..color = color.withValues(alpha: fade * (.5 + boost * .25)),
              );
          }
        case NovaParticleMood.comforting:
          if (i % 3 == 0) {
            canvas.drawPath(_brokenHeart, ink);
          } else if (i % 3 == 1) {
            canvas.drawPath(_sparkle, ink);
          } else {
            canvas.drawCircle(Offset.zero, .5, ink);
          }
        case NovaParticleMood.victory:
          switch (i % 4) {
            case 0:
              canvas.drawPath(_star, ink);
            case 1:
              canvas.drawRRect(
                RRect.fromRectAndRadius(
                  const Rect.fromLTWH(-.45, -1, .9, 2),
                  const Radius.circular(.18),
                ),
                ink,
              );
            case 2:
              canvas.drawPath(_sparkle, ink);
            default:
              canvas.drawCircle(Offset.zero, .4, ink);
          }
        case NovaParticleMood.daily:
          switch (i % 4) {
            case 0:
              canvas.drawPath(_star, ink);
            case 1:
              canvas.drawCircle(
                Offset.zero,
                1.1,
                ink
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = .18,
              );
            case 2:
              canvas.drawPath(_sparkle, ink);
            default:
              canvas.drawCircle(
                Offset.zero,
                1,
                ink..color = color.withValues(alpha: fade * .12),
              );
              canvas.drawCircle(
                Offset.zero,
                .4,
                ink..color = color.withValues(alpha: fade * .6),
              );
          }
        case NovaParticleMood.tutorial:
          switch (i % 4) {
            case 0:
              for (final offset in [
                const Offset(-.6, -.6),
                const Offset(.5, -.6),
                const Offset(-.6, .5),
              ]) {
                canvas.drawRRect(
                  RRect.fromRectAndRadius(
                    Rect.fromCenter(center: offset, width: .85, height: .85),
                    const Radius.circular(.2),
                  ),
                  ink,
                );
              }
            case 1:
              canvas.drawPath(_paw, ink);
            case 2:
              canvas.drawPath(_star, ink);
            default:
              canvas.drawCircle(Offset.zero, .4, ink);
          }
      }
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool? hitTest(Offset position) => false;
  @override
  bool shouldRepaint(NovaAmbientPainter old) =>
      clock != old.clock ||
      mood != old.mood ||
      reduced != old.reduced ||
      energy != old.energy;
}
