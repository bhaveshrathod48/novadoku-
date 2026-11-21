import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/home/profile/profile_provider.dart';
import 'game_providers.dart';
import 'progress_providers.dart';
import 'settings_providers.dart';

/// Production bootstrap enables this. Already-initialized embedded/test app
/// hosts retain the existing direct-router entry without repeating startup.
final launchSplashProvider = Provider<bool>((ref) => false);

/// Music is unlocked once per launch, after Splash has completely faded away.
/// Later navigation never resets this latch or interrupts the existing loop.
final musicLaunchReadyProvider = NotifierProvider<MusicLaunchReady, bool>(
  MusicLaunchReady.new,
);

class MusicLaunchReady extends Notifier<bool> {
  @override
  bool build() => !ref.read(launchSplashProvider);

  void homeVisible() => state = true;
}

final appStartupProvider = FutureProvider<StartupResult>((ref) async {
  final journal = ref.watch(progressJournalProvider);
  final worker = ref.watch(puzzleWorkProvider);
  final campaign = AsyncValue.guard(
    () => journal.read(
      CampaignProgress.key,
      (json) => CampaignProgress.decode(json, worker.restore),
    ),
  );
  // Start together and reuse the existing providers' caches in Home. Errors
  // remain in those providers; startup never resets or overwrites saved data.
  final settings = AsyncValue.guard(() => ref.read(appSettingsProvider.future));
  final profile = AsyncValue.guard(
    () => ref.read(playerProfileProvider.future),
  );
  await Future.wait([settings, profile]);
  return StartupResult(await campaign);
});

class StartupResult {
  const StartupResult(this.campaign);
  final AsyncValue<CampaignProgress?> campaign;
}
