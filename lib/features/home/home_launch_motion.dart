import 'package:flutter/widgets.dart';

/// A single launch clock, mounted only by the Splash-to-Home handoff.
/// Routes visited later see its completed value and never replay the sequence.
class HomeLaunchMotion extends StatefulWidget {
  const HomeLaunchMotion({super.key, required this.child});
  final Widget child;
  static const duration = Duration(milliseconds: 1100);

  static Animation<double>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_LaunchClock>()?.clock;

  @override
  State<HomeLaunchMotion> createState() => _HomeLaunchMotionState();
}

class _HomeLaunchMotionState extends State<HomeLaunchMotion>
    with SingleTickerProviderStateMixin {
  late final _clock = AnimationController(
    vsync: this,
    duration: HomeLaunchMotion.duration,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _clock.value = 1;
    } else if (!_started) {
      _clock.forward();
    }
    _started = true;
  }

  @override
  void dispose() {
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _LaunchClock(clock: _clock, child: widget.child);
}

class _LaunchClock extends InheritedWidget {
  const _LaunchClock({required this.clock, required super.child});
  final Animation<double> clock;

  @override
  bool updateShouldNotify(_LaunchClock oldWidget) => clock != oldWidget.clock;
}

/// Paint-only motion keeps every existing layout box and child state intact.
class HomeLaunchPart extends StatelessWidget {
  const HomeLaunchPart({
    super.key,
    required this.child,
    required this.delay,
    this.duration = 400,
    this.startScale = .975,
  });
  final Widget child;
  final int delay, duration;
  final double startScale;

  @override
  Widget build(BuildContext context) {
    final clock = HomeLaunchMotion.maybeOf(context);
    if (clock == null) return child;
    final progress = clock.drive(
      CurveTween(
        curve: Interval(
          delay / 1100,
          (delay + duration) / 1100,
          curve: Curves.easeOutCubic,
        ),
      ),
    );
    return FadeTransition(
      opacity: progress,
      child: ScaleTransition(
        scale: progress.drive(Tween(begin: startScale, end: 1.0)),
        child: child,
      ),
    );
  }
}
