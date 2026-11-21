import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../l10n/nova_localizations.dart';

import '../../core/animations/app_motion.dart';
import '../../core/services/feedback_scope.dart';
import '../../core/services/feedback_services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

/// The common pointer, keyboard and accessibility behavior of Nova controls.
class NovaPressable extends StatefulWidget {
  const NovaPressable({
    super.key,
    required this.label,
    required this.child,
    required this.onPressed,
    required this.radius,
    this.selected,
    this.toggled,
    this.busy = false,
    this.feedback = FeedbackEvent.button,
    this.button = true,
    this.onDoubleTap,
    this.doubleTapLabel,
    this.pointerInput = true,
    this.pressScale = AppMotion.pressScale,
    this.pressOffset = Offset.zero,
  });

  final String label;
  final Widget child;
  final VoidCallback? onPressed;
  final BorderRadius radius;
  final bool? selected;
  final bool? toggled;
  final bool busy;
  final FeedbackEvent? feedback;
  final bool button;
  final VoidCallback? onDoubleTap;
  final String? doubleTapLabel;
  final bool pointerInput;
  final double pressScale;
  final Offset pressOffset;

  @override
  State<NovaPressable> createState() => _NovaPressableState();
}

class _NovaPressableState extends State<NovaPressable> {
  bool _pressed = false;
  bool _showFocus = false;

  @override
  void didUpdateWidget(covariant NovaPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.onPressed == null) _pressed = false;
  }

  void _setPressed(bool pressed) {
    if (_pressed != pressed) setState(() => _pressed = pressed);
  }

  void _activate() {
    final callback = widget.onPressed;
    if (callback == null) return;
    if (widget.feedback case final event?) FeedbackScope.play(context, event);
    callback();
  }

  Widget _motion(Widget child, Duration duration) {
    final scaled = AnimatedScale(
      scale: _pressed && duration != Duration.zero ? widget.pressScale : 1,
      duration: duration,
      curve: _pressed ? AppMotion.pressCurve : AppMotion.springCurve,
      child: child,
    );
    // Grid cells and compact controls do not need a second implicit ticker.
    if (widget.pressOffset == Offset.zero) return scaled;
    return AnimatedSlide(
      offset: _pressed && duration != Duration.zero
          ? widget.pressOffset
          : Offset.zero,
      duration: duration,
      curve: _pressed ? AppMotion.pressCurve : AppMotion.enterCurve,
      child: scaled,
    );
  }

  @override
  Widget build(BuildContext context) {
    final callback = widget.onPressed == null ? null : _activate;
    final enabled = callback != null;
    final duration = AppMotion.durationOf(
      context,
      _pressed ? AppMotion.pressDuration : AppMotion.pressRelease,
    );
    return Semantics(
      label: localize(context, widget.label),
      button: widget.button,
      enabled: enabled,
      selected: widget.selected,
      toggled: widget.toggled,
      liveRegion: widget.busy,
      onTap: callback,
      customSemanticsActions:
          widget.onDoubleTap == null || widget.doubleTapLabel == null
          ? null
          : {
              CustomSemanticsAction(
                label: localize(context, widget.doubleTapLabel!),
              ): widget.onDoubleTap!,
            },
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowFocusHighlight: (show) {
          if (_showFocus != show) setState(() => _showFocus = show);
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              callback?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: widget.pointerInput ? callback : null,
          onDoubleTap: enabled && widget.pointerInput
              ? widget.onDoubleTap
              : null,
          onTapDown: enabled && widget.pointerInput
              ? (_) => _setPressed(true)
              : null,
          onTapUp: enabled && widget.pointerInput
              ? (_) => _setPressed(false)
              : null,
          onTapCancel: enabled && widget.pointerInput
              ? () => _setPressed(false)
              : null,
          child: _motion(
            DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: widget.radius,
                border: _showFocus && enabled
                    ? Border.all(
                        color: AppColors.focus,
                        width: AppTokens.accentBorderWidth,
                      )
                    : null,
              ),
              child: ExcludeSemantics(child: widget.child),
            ),
            duration,
          ),
        ),
      ),
    );
  }
}
