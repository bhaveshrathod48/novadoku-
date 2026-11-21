import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/animations/app_motion.dart';
import '../../core/theme/app_colors.dart';

/// Plays a single burst without changing the result dialog's geometry.
class NovaCelebration extends StatefulWidget {
  const NovaCelebration({super.key});

  @override
  State<NovaCelebration> createState() => _NovaCelebrationState();
}

class _NovaCelebrationState extends State<NovaCelebration>
    with SingleTickerProviderStateMixin {
  late final _clock = AnimationController(
    vsync: this,
    duration: AppMotion.celebration,
  );
  late final _painter = _BurstPainter(_clock);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _started = true;
      _clock.value = 1;
    } else if (!_started) {
      _started = true;
      _clock.forward();
    }
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return const SizedBox.shrink();
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          key: const ValueKey('victory particles'),
          painter: _painter,
        ),
      ),
    );
  }
}

typedef _Particle = ({
  double angle,
  double speed,
  double rotation,
  double scale,
  double delay,
  Color color,
  int shape,
});

class _BurstPainter extends CustomPainter {
  _BurstPainter(this.clock) : super(repaint: clock);

  final Animation<double> clock;
  final Paint _ink = Paint();
  final _star = Path()
    ..moveTo(0, -1)
    ..quadraticBezierTo(.17, -.17, 1, 0)
    ..quadraticBezierTo(.17, .17, 0, 1)
    ..quadraticBezierTo(-.17, .17, -1, 0)
    ..quadraticBezierTo(-.17, -.17, 0, -1)
    ..close();
  static final List<_Particle> _particles = _buildParticles();

  static List<_Particle> _buildParticles() {
    final random = math.Random(71);
    const colors = [
      AppColors.decorStar,
      AppColors.primaryLight,
      AppColors.decorGold,
      AppColors.decorMint,
      AppColors.heart,
      AppColors.gridHighlight,
    ];
    return List.generate(
      36,
      (index) => (
        angle: index * math.pi * 2 / 36 + random.nextDouble() * 0.28,
        speed: 0.18 + random.nextDouble() * 0.23,
        rotation: (random.nextDouble() - .5) * 8,
        scale: .012 + random.nextDouble() * .018,
        delay: random.nextDouble() * .22,
        color: colors[index % colors.length],
        shape: index % 3,
      ),
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final time = clock.value;
    if (time <= 0 || time >= 1 || size.isEmpty) return;
    final middle = size.center(Offset.zero);
    final unit = size.shortestSide;
    for (final particle in _particles) {
      final life = (time - particle.delay) / (1 - particle.delay);
      if (life <= 0 || life >= 1) continue;
      final travel =
          unit * (.29 + particle.speed * AppMotion.enterCurve.transform(life));
      final direction = Offset(
        math.cos(particle.angle),
        math.sin(particle.angle),
      );
      final position =
          middle + direction * travel + Offset(0, unit * .22 * life * life);
      final fadeIn = (life * 11).clamp(0.0, 1.0);
      final fadeOut = 1 - Curves.easeIn.transform(life);
      _ink.color = particle.color.withValues(alpha: fadeIn * fadeOut);
      final diameter = unit * particle.scale * (1 - life * .24);
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(particle.rotation * life);
      switch (particle.shape) {
        case 0:
          canvas.scale(diameter, diameter);
          canvas.drawPath(_star, _ink);
        case 1:
          final ribbon = Rect.fromCenter(
            center: Offset.zero,
            width: diameter * .72,
            height: diameter * 1.8,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(ribbon, const Radius.circular(1.2)),
            _ink,
          );
        default:
          canvas.drawCircle(Offset.zero, diameter * .36, _ink);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) =>
      oldDelegate.clock != clock;
}
