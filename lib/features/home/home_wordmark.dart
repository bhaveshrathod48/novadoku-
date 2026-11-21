import 'package:flutter/widgets.dart';

import '../../core/constants/app_info.dart';
import '../../core/theme/app_colors.dart';

class HomeWordmark extends StatelessWidget {
  const HomeWordmark({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppInfo.name,
    header: true,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 236),
      child: const AspectRatio(
        aspectRatio:
            _HomeWordmarkPainter.designWidth /
            _HomeWordmarkPainter.designHeight,
        child: CustomPaint(painter: _HomeWordmarkPainter()),
      ),
    ),
  );
}

class _HomeWordmarkPainter extends CustomPainter {
  const _HomeWordmarkPainter();

  static const designWidth = 215.0;
  static const designHeight = 36.0;

  // Outlines traced from the approved Home wordmark, in reference pixels.
  static final _letters = Path()
    ..fillType = PathFillType.evenOdd
    ..moveTo(-0.03, 32.00)
    ..lineTo(0.10, 13.00)
    ..lineTo(0.84, 11.00)
    ..lineTo(8.00, 10.75)
    ..lineTo(11.00, 12.41)
    ..lineTo(13.00, 10.99)
    ..lineTo(17.00, 10.14)
    ..lineTo(20.00, 10.94)
    ..lineTo(23.00, 13.37)
    ..lineTo(24.38, 18.00)
    ..lineTo(24.59, 32.00)
    ..lineTo(24.00, 33.48)
    ..lineTo(16.00, 33.67)
    ..lineTo(14.72, 33.00)
    ..lineTo(14.65, 21.00)
    ..lineTo(13.00, 18.43)
    ..lineTo(11.00, 18.84)
    ..lineTo(10.14, 21.00)
    ..lineTo(10.00, 33.00)
    ..lineTo(8.00, 33.66)
    ..lineTo(2.00, 33.64)
    ..lineTo(0.12, 33.00)
    ..close()
    ..moveTo(26.37, 22.00)
    ..lineTo(27.38, 17.00)
    ..lineTo(30.00, 13.38)
    ..lineTo(35.00, 10.61)
    ..lineTo(40.00, 9.91)
    ..lineTo(44.69, 11.00)
    ..lineTo(49.25, 14.00)
    ..lineTo(51.55, 18.00)
    ..lineTo(52.36, 23.00)
    ..lineTo(51.39, 27.00)
    ..lineTo(48.65, 31.00)
    ..lineTo(45.00, 33.37)
    ..lineTo(39.00, 34.55)
    ..lineTo(34.00, 33.50)
    ..lineTo(29.00, 30.14)
    ..lineTo(26.88, 26.00)
    ..close()
    ..moveTo(35.42, 22.00)
    ..lineTo(36.14, 20.00)
    ..lineTo(39.00, 18.37)
    ..lineTo(41.00, 18.74)
    ..lineTo(43.06, 22.00)
    ..lineTo(41.83, 25.00)
    ..lineTo(39.00, 26.10)
    ..lineTo(36.00, 24.26)
    ..close()
    ..moveTo(51.83, 12.00)
    ..lineTo(53.00, 10.85)
    ..lineTo(62.00, 10.92)
    ..lineTo(62.83, 12.00)
    ..lineTo(64.95, 21.00)
    ..lineTo(66.00, 21.82)
    ..lineTo(68.78, 12.00)
    ..lineTo(69.67, 11.00)
    ..lineTo(79.14, 11.00)
    ..lineTo(79.03, 13.00)
    ..lineTo(71.00, 33.14)
    ..lineTo(70.00, 33.68)
    ..lineTo(61.00, 33.64)
    ..lineTo(60.00, 33.03)
    ..close()
    ..moveTo(78.58, 26.00)
    ..lineTo(80.00, 23.15)
    ..lineTo(82.60, 21.00)
    ..lineTo(91.73, 19.00)
    ..lineTo(91.00, 17.25)
    ..lineTo(90.00, 17.02)
    ..lineTo(84.00, 18.31)
    ..lineTo(80.18, 14.00)
    ..lineTo(82.00, 12.36)
    ..lineTo(87.00, 10.29)
    ..lineTo(92.50, 10.00)
    ..lineTo(96.00, 10.92)
    ..lineTo(99.53, 14.00)
    ..lineTo(101.00, 17.64)
    ..lineTo(101.37, 21.00)
    ..lineTo(101.00, 33.32)
    ..lineTo(94.00, 33.66)
    ..lineTo(92.00, 32.56)
    ..lineTo(87.00, 34.26)
    ..lineTo(83.00, 33.50)
    ..lineTo(79.82, 31.00)
    ..close()
    ..moveTo(87.16, 26.00)
    ..lineTo(88.00, 24.89)
    ..lineTo(90.00, 24.25)
    ..lineTo(92.00, 24.28)
    ..lineTo(92.61, 25.00)
    ..lineTo(92.10, 27.00)
    ..lineTo(90.00, 28.18)
    ..lineTo(88.00, 27.79)
    ..close()
    ..moveTo(102.91, 22.00)
    ..lineTo(104.00, 16.16)
    ..lineTo(108.00, 11.66)
    ..lineTo(113.00, 10.17)
    ..lineTo(119.00, 11.84)
    ..lineTo(119.30, 2.00)
    ..lineTo(120.00, 0.87)
    ..lineTo(128.00, 0.89)
    ..lineTo(129.00, 1.61)
    ..lineTo(129.00, 33.12)
    ..lineTo(121.00, 33.62)
    ..lineTo(120.00, 32.10)
    ..lineTo(114.00, 34.29)
    ..lineTo(109.00, 33.40)
    ..lineTo(105.00, 29.93)
    ..lineTo(103.59, 27.00)
    ..close()
    ..moveTo(111.96, 22.00)
    ..lineTo(112.52, 20.00)
    ..lineTo(116.00, 18.23)
    ..lineTo(119.00, 19.86)
    ..lineTo(119.73, 22.00)
    ..lineTo(118.66, 25.00)
    ..lineTo(116.00, 26.20)
    ..lineTo(113.10, 25.00)
    ..close()
    ..moveTo(131.28, 22.00)
    ..lineTo(131.71, 18.00)
    ..lineTo(135.00, 13.20)
    ..lineTo(139.00, 10.83)
    ..lineTo(145.00, 9.93)
    ..lineTo(150.00, 11.12)
    ..lineTo(153.91, 14.00)
    ..lineTo(156.35, 18.00)
    ..lineTo(156.83, 23.00)
    ..lineTo(156.07, 27.00)
    ..lineTo(153.00, 31.35)
    ..lineTo(150.00, 33.32)
    ..lineTo(143.00, 34.48)
    ..lineTo(138.00, 33.27)
    ..lineTo(134.00, 30.40)
    ..lineTo(131.61, 26.00)
    ..close()
    ..moveTo(140.09, 22.00)
    ..lineTo(141.00, 19.91)
    ..lineTo(144.00, 18.29)
    ..lineTo(147.00, 19.74)
    ..lineTo(147.78, 22.00)
    ..lineTo(146.62, 25.00)
    ..lineTo(144.00, 26.19)
    ..lineTo(141.34, 25.00)
    ..close()
    ..moveTo(158.75, 32.00)
    ..lineTo(158.80, 3.00)
    ..lineTo(160.00, 0.87)
    ..lineTo(168.00, 0.99)
    ..lineTo(168.85, 2.00)
    ..lineTo(169.00, 18.26)
    ..lineTo(170.00, 18.08)
    ..lineTo(175.00, 10.92)
    ..lineTo(194.30, 11.00)
    ..lineTo(195.23, 13.00)
    ..lineTo(195.30, 24.00)
    ..lineTo(197.00, 26.05)
    ..lineTo(199.00, 25.29)
    ..lineTo(199.62, 24.00)
    ..lineTo(199.90, 12.00)
    ..lineTo(200.59, 11.00)
    ..lineTo(208.00, 10.74)
    ..lineTo(209.60, 12.00)
    ..lineTo(209.71, 32.00)
    ..lineTo(209.00, 33.47)
    ..lineTo(201.00, 33.56)
    ..lineTo(200.00, 31.96)
    ..lineTo(194.00, 34.22)
    ..lineTo(189.00, 33.23)
    ..lineTo(185.86, 29.00)
    ..lineTo(185.22, 14.00)
    ..lineTo(184.00, 13.51)
    ..lineTo(178.97, 21.00)
    ..lineTo(185.55, 33.00)
    ..lineTo(185.00, 33.59)
    ..lineTo(175.00, 33.51)
    ..lineTo(173.45, 32.00)
    ..lineTo(170.00, 25.44)
    ..lineTo(169.00, 25.33)
    ..lineTo(168.68, 33.00)
    ..lineTo(168.00, 33.58)
    ..lineTo(160.00, 33.69)
    ..lineTo(158.89, 33.00)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.scale(size.width / designWidth, size.height / designHeight);
    final ink = Paint()..color = AppColors.text;
    canvas.drawPath(_letters, ink);
    canvas.drawCircle(
      const Offset(210.2, 4.3),
      3.6,
      ink..color = AppColors.wordmarkAccent,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HomeWordmarkPainter oldDelegate) => false;
}
