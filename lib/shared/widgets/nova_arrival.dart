import 'package:flutter/widgets.dart';

import '../../core/animations/app_motion.dart';

/// A finite arrival for branding and instructional content, never an input gate.
/// Locale/provider rebuilds retain the clock; reduced motion finishes it.
class NovaArrival extends StatefulWidget {
  const NovaArrival({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });
  final Widget child;
  final Duration delay;

  @override
  State<NovaArrival> createState() => _NovaArrivalState();
}

class _NovaArrivalState extends State<NovaArrival>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: AppMotion.brandArrival + widget.delay,
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
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _clock,
    child: widget.child,
    builder: (context, child) {
      final delay =
          widget.delay.inMicroseconds /
          (AppMotion.brandArrival + widget.delay).inMicroseconds;
      final progress = AppMotion.enterCurve.transform(
        ((_clock.value - delay) / (1 - delay)).clamp(0.0, 1.0),
      );
      return Opacity(
        opacity: progress,
        child: Transform.translate(
          offset: Offset(0, (1 - progress) * 8),
          transformHitTests: false,
          child: child,
        ),
      );
    },
  );
}
