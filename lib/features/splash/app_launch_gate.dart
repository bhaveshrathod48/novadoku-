import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/startup_providers.dart';
import '../../core/animations/app_motion.dart';
import '../home/home_launch_motion.dart';
import 'splash_screen.dart';

/// Splash is outside the route history. Completion is latched for this app
/// instance, so navigation, locale changes and resume never replay it.
class AppLaunchGate extends ConsumerStatefulWidget {
  const AppLaunchGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AppLaunchGate> createState() => _AppLaunchGateState();
}

class _AppLaunchGateState extends ConsumerState<AppLaunchGate> {
  Timer? _minimum;
  bool _musicScheduled = false;
  bool _elapsed = false, _complete = false;

  void _painted() {
    if (!mounted || _minimum != null) return;
    _minimum = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _elapsed = true);
    });
  }

  @override
  void dispose() {
    _minimum?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final startup = ref.watch(appStartupProvider);
    if (_elapsed && !startup.isLoading) _complete = true;
    return AnimatedSwitcher(
      duration: AppMotion.durationOf(
        context,
        const Duration(milliseconds: 460),
      ),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      transitionBuilder: (child, opacity) =>
          child.key == const ValueKey('launch-home')
          ? child
          : FadeTransition(
              opacity: opacity,
              child: IgnorePointer(child: child),
            ),
      layoutBuilder: (current, previous) {
        if (_complete && previous.isEmpty && !_musicScheduled) {
          _musicScheduled = true;
          // The outgoing Splash has actually left the tree. Unlock music
          // after this Home frame paints, rather than guessing at a timer.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted)
              ref.read(musicLaunchReadyProvider.notifier).homeVisible();
          });
        }
        // Home's opaque background is revealed beneath the fading Splash,
        // avoiding transparent/blank frames during the crossfade.
        return Stack(fit: StackFit.expand, children: [?current, ...previous]);
      },
      child: _complete
          ? KeyedSubtree(
              key: const ValueKey('launch-home'),
              child: HomeLaunchMotion(child: widget.child),
            )
          : SplashScreen(
              key: const ValueKey('launch-splash'),
              onPainted: _painted,
            ),
    );
  }
}
