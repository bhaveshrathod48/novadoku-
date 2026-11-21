import 'package:flutter/widgets.dart';

import '../../core/constants/app_assets.dart';
import '../../shared/characters/result_nova_loop.dart';

/// Keep the original header slot while painting a tightly framed portrait.
/// Its visible height is approximately 1.5x the previous padded atlas pose.
class HintNova extends StatelessWidget {
  const HintNova({super.key, required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    final artworkSize = size * 92 / 72;
    return SizedBox.square(
      dimension: size,
      child: OverflowBox(
        alignment: Alignment.center,
        minWidth: artworkSize,
        maxWidth: artworkSize,
        minHeight: artworkSize,
        maxHeight: artworkSize,
        child: ResultNovaLoop(
          size: artworkSize,
          image: const ResultNovaImage(
            asset: AppAssets.hintNovaLoop,
            debugLabel: 'Hint Nova 1.15x',
          ),
          posterAsset: AppAssets.hintNovaStill,
        ),
      ),
    );
  }
}
