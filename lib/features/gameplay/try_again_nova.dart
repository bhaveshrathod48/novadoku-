import '../../core/constants/app_assets.dart';
import '../../shared/characters/result_nova_loop.dart';

class TryAgainNova extends ResultNovaLoop {
  const TryAgainNova({super.key, required super.size})
    : super(
        image: const TryAgainNovaImage(),
        posterAsset: AppAssets.tryAgainNovaStill,
      );
}

class TryAgainNovaImage extends ResultNovaImage {
  const TryAgainNovaImage()
    : super(
        asset: AppAssets.tryAgainNovaLoop,
        debugLabel: 'Try Again Nova 1.15x',
      );
}
