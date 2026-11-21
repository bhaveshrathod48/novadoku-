import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/providers/game_providers.dart';
import 'app/providers/progress_providers.dart';
import 'app/providers/startup_providers.dart';
import 'core/constants/app_assets.dart';
import 'core/services/progress_journal.dart';
import 'core/services/progress_storage_web.dart'
    if (dart.library.io) 'core/services/progress_storage_io.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  LicenseRegistry.addLicense(() async* {
    for (final family in ['NotoSans', 'NotoSansDevanagari', 'NotoSansJP']) {
      yield LicenseEntryWithLineBreaks([
        family,
      ], await rootBundle.loadString('assets/fonts/OFL-$family.txt'));
    }
    yield LicenseEntryWithLineBreaks(const [
      'DynaPuff',
    ], await rootBundle.loadString(AppAssets.headingFontLicense));
    yield LicenseEntryWithLineBreaks(const [
      'Nunito Sans',
    ], await rootBundle.loadString(AppAssets.supportingFontLicense));
  });
  final journal = ProgressJournal(createProgressStorage());
  final worker = BackgroundPuzzleWork();
  runApp(
    ProviderScope(
      overrides: [
        progressJournalProvider.overrideWithValue(journal),
        launchSplashProvider.overrideWithValue(true),
        campaignRestoreProvider.overrideWith((ref) {
          final startup = ref.watch(appStartupProvider);
          if (startup.hasError) {
            return AsyncError(startup.error!, startup.stackTrace!);
          }
          return startup.value?.campaign ?? const AsyncLoading();
        }),
        puzzleWorkProvider.overrideWithValue(worker),
      ],
      child: const NovaApp(),
    ),
  );
}
