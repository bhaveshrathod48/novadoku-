import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../core/services/feedback_services.dart';

/// Actual route changes cover pointer, keyboard, system Back and dismissals.
/// The first route is silent, including restoration and the splash handoff.
class NavigationFeedbackObserver extends NavigatorObserver {
  NavigationFeedbackObserver(this.play);
  final ValueChanged<FeedbackEvent> play;
  bool _ready = false;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute == null) {
      // A restored deep link may install several initial pages together.
      scheduleMicrotask(() => _ready = true);
    } else if (_ready) {
      play(FeedbackEvent.navigationNext);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) play(FeedbackEvent.navigationBack);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) play(FeedbackEvent.navigationBack);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null && oldRoute != null) {
      play(FeedbackEvent.navigationNext);
    }
  }
}
