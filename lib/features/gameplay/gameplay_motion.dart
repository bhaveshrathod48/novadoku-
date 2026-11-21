import 'package:flutter/widgets.dart';

/// Gameplay-only timings. These do not change route, character or audio timing.
abstract final class GameplayMotion {
  static const entrance = Duration(milliseconds: 580);
  static const clear = Duration(milliseconds: 90);
  static const crossIn = Duration(milliseconds: 170);
  static const markOut = Duration(milliseconds: 90);
  static const novaReveal = Duration(milliseconds: 360);

  /// A compact lower-left to upper-right wave, including on 10x10 boards.
  static double cellProgress(double time, int row, int column, int size) {
    final delay = (size - 1 - row + column) / (2 * (size - 1)) * 300;
    return ((time * entrance.inMilliseconds - delay) / 280).clamp(0.0, 1.0);
  }
}

/// All cells listen to one board clock. The tile subtree is retained, and input
/// coordinates remain those of the untransformed board.
class GameplayCellEntrance extends AnimatedWidget {
  const GameplayCellEntrance({
    super.key,
    required Animation<double> animation,
    required this.row,
    required this.column,
    required this.size,
    required this.restarting,
    required this.child,
  }) : super(listenable: animation);

  final int row;
  final int column;
  final int size;
  final bool restarting;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final value = (listenable as Animation<double>).value;
    double opacity;
    double scale;
    final clearPart =
        GameplayMotion.clear.inMilliseconds /
        (GameplayMotion.clear + GameplayMotion.entrance).inMilliseconds;
    if (restarting && value < clearPart) {
      final progress = value / clearPart;
      opacity = 1 - Curves.easeInCubic.transform(progress);
      scale = 1 - .08 * progress;
    } else {
      final time = restarting ? (value - clearPart) / (1 - clearPart) : value;
      final progress = GameplayMotion.cellProgress(time, row, column, size);
      opacity = Curves.easeOutCubic.transform(progress);
      scale = .12 + .88 * Curves.easeOutCubic.transform(progress);
    }
    return Opacity(
      opacity: opacity,
      child: Transform.scale(
        scale: scale,
        transformHitTests: false,
        child: child,
      ),
    );
  }
}
