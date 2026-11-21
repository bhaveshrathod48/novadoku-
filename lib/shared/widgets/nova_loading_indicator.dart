import 'package:flutter/material.dart';

import '../../l10n/nova_localizations.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

class NovaLoadingIndicator extends StatelessWidget {
  const NovaLoadingIndicator({
    super.key,
    this.color = AppColors.primary,
    this.label = 'Loading',
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: localize(context, label),
    liveRegion: true,
    child: ExcludeSemantics(
      child: SizedBox.square(
        dimension: AppTokens.loadingSize,
        child: CircularProgressIndicator(
          value: MediaQuery.disableAnimationsOf(context) ? 0.7 : null,
          strokeWidth: AppTokens.loadingStroke,
          color: color,
        ),
      ),
    ),
  );
}
