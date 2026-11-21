import 'package:novadoku/l10n/nova_localizations.dart';
import 'package:flutter/material.dart';

import '../../core/animations/app_motion.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/typography/app_type.dart';
import '../widgets/nova_buttons.dart';

enum NovaDialogPosition { center, lower }

class NovaDialog extends StatelessWidget {
  const NovaDialog({
    super.key,
    required this.title,
    required this.content,
    this.leading,
    this.actions = const [],
    this.closeLabel,
    this.onClose,
    this.titleGap = AppTokens.space12,
    this.actionGap = AppTokens.space24,
    this.bottomPadding = AppTokens.modalPadding,
    this.titleAlignment = TextAlign.center,
  });

  final String title;
  final Widget content;
  final Widget? leading;
  final List<Widget> actions;
  final String? closeLabel;
  final VoidCallback? onClose;
  final TextAlign titleAlignment;
  final double titleGap;
  final double actionGap;
  final double bottomPadding;

  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    NovaDialogPosition position = NovaDialogPosition.center,
    bool dismissible = true,
  }) {
    final barrierLabel = MaterialLocalizations.of(context)
        .modalBarrierDismissLabel;
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Navigator.of(context, rootNavigator: true).push<T>(
      _NovaDialogRoute<T>(
        barrierDismissible: dismissible,
        barrierLabel: barrierLabel,
        barrierColor: AppColors.overlay,
        transitionDuration: reduced ? Duration.zero : AppMotion.dialogEnter,
        reverseTransitionDuration: reduced
            ? Duration.zero
            : AppMotion.dialogExit,
        pageBuilder: (context, animation, secondaryAnimation) => SafeArea(
          child: Padding(
            padding: MediaQuery.viewInsetsOf(context),
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.modalGutter),
              child: Align(
                alignment: position == NovaDialogPosition.center
                    ? Alignment.center
                    : const Alignment(0, 0.26),
                child: builder(context),
              ),
            ),
          ),
        ),
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          if (MediaQuery.disableAnimationsOf(context)) return child;
          final eased = animation.drive(
            CurveTween(curve: AppMotion.enterCurve),
          );
          return FadeTransition(
            opacity: eased,
            child: ScaleTransition(
              alignment: position == NovaDialogPosition.center
                  ? Alignment.center
                  : const Alignment(0, 0.26),
              scale: eased.drive(
                Tween(begin: AppMotion.dialogStartScale, end: 1),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => _ModalSurface(
    maxWidth: AppTokens.dialogMaxWidth,
    bottomPadding: bottomPadding,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (leading case final artwork?) ...[
          artwork,
          const SizedBox(height: AppTokens.space16),
        ],
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: NovaText(
                  title,
                  style: AppType.dialogTitle,
                  textAlign: titleAlignment,
                ),
              ),
            ),
            if (closeLabel case final label?)
              NovaIconButton(
                icon: Icons.close_rounded,
                tone: NovaIconTone.lavender,
                label: label,
                onPressed: onClose ?? Navigator.of(context).pop,
              ),
          ],
        ),
        SizedBox(height: titleGap),
        content,
        if (actions.isNotEmpty) SizedBox(height: actionGap),
        for (final (index, action) in actions.indexed) ...[
          if (index > 0) const SizedBox(height: AppTokens.space12),
          action,
        ],
      ],
    ),
  );
}

class _NovaDialogRoute<T> extends RawDialogRoute<T> {
  _NovaDialogRoute({
    required super.barrierDismissible,
    required super.barrierLabel,
    required super.barrierColor,
    required super.transitionDuration,
    required super.pageBuilder,
    required super.transitionBuilder,
    required this.reverseTransitionDuration,
  }) : super(traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop);

  @override
  final Duration reverseTransitionDuration;
}

class NovaBottomSheet extends StatelessWidget {
  const NovaBottomSheet({
    super.key,
    required this.child,
    this.showGrabber = true,
  });

  final Widget child;
  final bool showGrabber;

  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool dismissible = true,
    bool enableDrag = true,
  }) => showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: dismissible,
    enableDrag: enableDrag,
    showDragHandle: false,
    backgroundColor: AppColors.transparent,
    barrierColor: AppColors.overlay,
    elevation: 0,
    sheetAnimationStyle: AnimationStyle(
      duration: AppMotion.durationOf(context, AppMotion.sheetEnter),
      reverseDuration: AppMotion.durationOf(context, AppMotion.sheetExit),
    ),
    builder: (context) => Padding(
      padding: MediaQuery.viewInsetsOf(context),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.all(AppTokens.modalGutter),
        child: builder(context),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Center(
    heightFactor: 1,
    child: _ModalSurface(
      maxWidth: AppTokens.sheetMaxWidth,
      leading: showGrabber
          ? Padding(
              padding: const EdgeInsets.only(top: AppTokens.space12),
              child: Center(
                child: Container(
                  width: AppTokens.grabberWidth,
                  height: AppTokens.grabberHeight,
                  decoration: const BoxDecoration(
                    color: AppColors.border,
                    borderRadius: AppTokens.pillRadius,
                  ),
                ),
              ),
            )
          : null,
      child: child,
    ),
  );
}

class _ModalSurface extends StatelessWidget {
  const _ModalSurface({
    required this.maxWidth,
    required this.child,
    this.leading,
    this.bottomPadding = AppTokens.modalPadding,
  });

  final double maxWidth;
  final Widget child;
  final Widget? leading;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(maxWidth: maxWidth),
    child: Material(
      color: AppColors.surface,
      borderRadius: AppTokens.modalRadius,
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?leading,
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppTokens.modalPadding,
                AppTokens.modalPadding,
                AppTokens.modalPadding,
                bottomPadding,
              ),
              child: child,
            ),
          ],
        ),
      ),
    ),
  );
}
