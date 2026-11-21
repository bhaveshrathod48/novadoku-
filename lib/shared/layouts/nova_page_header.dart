import 'package:flutter/widgets.dart';

import '../../core/theme/app_colors.dart';
import '../../core/animations/app_motion.dart';
import '../../core/theme/app_tokens.dart';
import '../widgets/nova_glyph.dart';
import '../widgets/nova_pressable.dart';
import '../widgets/nova_surfaces.dart';

class NovaPageHeader extends StatelessWidget {
  const NovaPageHeader({
    super.key,
    required this.label,
    required this.onBack,
    this.onSettings,
  });

  final String label;
  final VoidCallback onBack;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _button(NovaGlyphKind.back, 'Back', onBack),
      Expanded(
        child: Center(
          child: NovaBadge(label: label, tone: NovaBadgeTone.surface),
        ),
      ),
      if (onSettings case final open?)
        _button(NovaGlyphKind.settings, 'Settings', open)
      else
        const SizedBox(width: AppTokens.iconButtonSize),
    ],
  );

  Widget _button(NovaGlyphKind icon, String label, VoidCallback action) =>
      NovaPressable(
        label: label,
        onPressed: action,
        radius: AppTokens.controlRadius,
        pressScale: AppMotion.iconPressScale,
        child: Container(
          width: AppTokens.iconButtonSize,
          height: AppTokens.iconButtonSize,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppTokens.controlRadius,
            boxShadow: AppTokens.iconShadow,
          ),
          child: NovaGlyph(icon),
        ),
      );
}
