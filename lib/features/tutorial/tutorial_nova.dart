import '../../core/constants/app_assets.dart';
import '../../shared/characters/result_nova_loop.dart';

/// Only the header mascot uses this loop; rule diagrams keep their own art.
class TutorialNova extends ResultNovaLoop {
  const TutorialNova({super.key, required super.size})
    : super(
        image: const ResultNovaImage(
          asset: AppAssets.tutorialNovaLoop,
          debugLabel: 'Tutorial Nova 1.15x',
        ),
        posterAsset: AppAssets.tutorialNovaStill,
      );
}
