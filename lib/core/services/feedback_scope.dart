import 'package:flutter/widgets.dart';

import 'feedback_services.dart';

class FeedbackScope extends InheritedWidget {
  const FeedbackScope({
    super.key,
    required this.onFeedback,
    required super.child,
  });

  final ValueChanged<FeedbackEvent> onFeedback;

  static void play(BuildContext context, FeedbackEvent event) =>
      context.getInheritedWidgetOfExactType<FeedbackScope>()?.onFeedback(event);

  @override
  bool updateShouldNotify(FeedbackScope oldWidget) =>
      onFeedback != oldWidget.onFeedback;
}
