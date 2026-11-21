import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import 'nova_background.dart';

export 'nova_background.dart' show NovaBackgroundStyle;

class NovaScaffold extends StatelessWidget {
  const NovaScaffold({
    super.key,
    required this.body,
    this.background = NovaBackgroundStyle.calm,
    this.scrollable = false,
    this.scrollController,
    this.horizontalGutter,
    this.contentAlignment = Alignment.center,
  });

  final Widget body;
  final NovaBackgroundStyle background;
  final bool scrollable;
  final ScrollController? scrollController;
  final double? horizontalGutter;
  final AlignmentGeometry contentAlignment;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: const SystemUiOverlayStyle(
      statusBarColor: AppColors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.transparent,
      systemNavigationBarDividerColor: AppColors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,
    ),
    child: NovaBackground(
      style: background,
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final gutter =
                  horizontalGutter ??
                  AppTokens.screenGutter(constraints.maxWidth);
              final content = Align(
                alignment: contentAlignment,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppTokens.contentMaxWidth,
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: gutter),
                    child: SizedBox(width: double.infinity, child: body),
                  ),
                ),
              );
              if (!scrollable) return content;
              return SingleChildScrollView(
                controller: scrollController,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: content,
                ),
              );
            },
          ),
        ),
      ),
    ),
  );
}
