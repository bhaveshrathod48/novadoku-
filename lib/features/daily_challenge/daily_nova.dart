import '../../core/constants/app_assets.dart';
import '../../shared/characters/result_nova_loop.dart';

/// The padded video keeps the entire available tail motion inside the slot.
/// Missing tail pixels at the source video's left edge cannot be recovered.
class DailyNova extends ResultNovaLoop {
  const DailyNova({super.key, required super.size})
    : super(
        image: const ResultNovaImage(
          asset: AppAssets.dailyNovaLoop,
          debugLabel: 'Daily Nova 1.15x',
        ),
        posterAsset: AppAssets.dailyNovaStill,
      );
}
