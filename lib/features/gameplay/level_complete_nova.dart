import '../../core/constants/app_assets.dart';
import '../../shared/characters/result_nova_loop.dart';

class LevelCompleteNova extends ResultNovaLoop {
  const LevelCompleteNova({super.key, required super.size})
    : super(
        image: const ResultNovaImage(
          asset: AppAssets.levelCompleteNovaLoop,
          debugLabel: 'Level Complete Nova 1.15x',
        ),
        posterAsset: AppAssets.levelCompleteNovaStill,
      );
}
