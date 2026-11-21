import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novadoku/app/app.dart';
import 'package:novadoku/app/providers/feedback_providers.dart';
import 'package:novadoku/app/providers/progress_providers.dart';
import 'package:novadoku/app/providers/settings_providers.dart';
import 'package:novadoku/app/providers/startup_providers.dart';
import 'package:novadoku/app/router/app_router.dart';
import 'package:novadoku/core/services/app_settings.dart';
import 'package:novadoku/core/services/feedback_services.dart';
import 'package:novadoku/core/services/progress_journal.dart';
import 'package:novadoku/core/services/settings_store.dart';
import 'package:novadoku/features/home/home_screen.dart';
import 'package:novadoku/features/settings/settings_dialog.dart';
import 'package:novadoku/features/splash/splash_screen.dart';
import 'package:novadoku/shared/dialogs/nova_modal.dart';

import 'support/feedback_fakes.dart';

void main() {
  for (final savedMusic in <bool?>[null, false, true]) {
    testWidgets(
      'music saved=$savedMusic stays silent through Splash and starts only after Home handoff',
      (tester) async {
        final journal = ProgressJournal(MemoryProgressStorage());
        final store = LocalSettingsStore(journal, readLegacy: () async => null);
        if (savedMusic != null)
          await store.write(AppSettings(music: savedMusic));
        final audio = RecordingAudio();
        final container = ProviderContainer(
          overrides: [
            launchSplashProvider.overrideWithValue(true),
            appStartupProvider.overrideWith(
              (ref) async => const StartupResult(AsyncData(null)),
            ),
            settingsStoreProvider.overrideWithValue(store),
            progressJournalProvider.overrideWithValue(journal),
            audioServiceProvider.overrideWithValue(audio),
            hapticServiceProvider.overrideWithValue(RecordingHaptics()),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const NovaApp(),
          ),
        );
        await tester.runAsync(
          () => precacheImage(
            const AssetImage(SplashScreen.asset),
            tester.element(find.byType(SplashScreen)),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 2500));
        await tester.pump();
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(audio.configurations.every((c) => !c.music), isTrue);
        await tester.pump(const Duration(milliseconds: 459));
        expect(audio.configurations.last.music, isFalse);
        await tester.pump(const Duration(milliseconds: 1));
        await tester.pump();
        // A ticker's first frame may begin after a large fake-clock jump.
        // Music must remain muted for as long as the outgoing Splash remains.
        for (
          var i = 0;
          i < 30 && find.byType(SplashScreen).evaluate().isNotEmpty;
          i++
        ) {
          expect(audio.configurations.last.music, isFalse);
          await tester.pump(const Duration(milliseconds: 20));
        }
        await tester.pump();
        expect(audio.configurations.last.music, savedMusic ?? false);
        expect(find.byType(SplashScreen), findsNothing);
        final configurations = audio.configurations.length;
        container.read(appRouterProvider).goNamed(AppRoute.settings.name);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        container.read(appRouterProvider).goNamed(AppRoute.home.name);
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(
          audio.configurations,
          hasLength(configurations),
          reason: 'Navigation must not restart or interrupt music',
        );
        final settings = container.read(appSettingsProvider.notifier);
        await settings.saveChanges((s) => s.copyWith(music: true));
        expect(audio.configurations.last.music, isTrue);
        expect((await store.read()).music, isTrue);
        await settings.saveChanges((s) => s.copyWith(music: false));
        expect(audio.configurations.last.music, isFalse);
        expect((await store.read()).music, isFalse);
        expect(
          container.read(appSettingsProvider).requireValue.soundEffects,
          isTrue,
        );
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final viewport in [const Size(390, 844), const Size(320, 568)]) {
    testWidgets(
      'Settings and Language share centered bounds and one opening sound at $viewport',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = viewport;
        tester.platformDispatcher.textScaleFactorTestValue =
            viewport.width < 350 ? 1.6 : 1;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(disableAnimations: true);
        addTearDown(tester.view.reset);
        addTearDown(
          tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
        );
        final audio = RecordingAudio();
        final journal = ProgressJournal(MemoryProgressStorage());
        final store = LocalSettingsStore(journal, readLegacy: () async => null);
        final container = ProviderContainer(
          overrides: [
            settingsStoreProvider.overrideWithValue(store),
            audioServiceProvider.overrideWithValue(audio),
            hapticServiceProvider.overrideWithValue(RecordingHaptics()),
          ],
        );
        addTearDown(container.dispose);
        container.read(appRouterProvider).goNamed(AppRoute.settings.name);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const NovaApp(),
          ),
        );
        await tester.pumpAndSettle();
        final original = tester.getRect(find.byType(NovaDialog));
        expect(original.center.dx, closeTo(viewport.width / 2, .01));
        expect(original.center.dy, closeTo(viewport.height / 2, .01));
        audio.events.clear();
        final languageAction = find.bySemanticsLabel('Language, English');
        await tester.ensureVisible(languageAction);
        await tester.tap(languageAction);
        await tester.pumpAndSettle();
        expect(audio.events, [FeedbackEvent.button]);
        final languageDialog = find.byKey(const ValueKey('language-dialog'));
        expect(tester.getRect(languageDialog), original);
        expect(find.text('Settings').hitTestable(), findsNothing);
        final portuguese = find.descendant(
          of: languageDialog,
          matching: find.text('Português'),
        );
        await tester.ensureVisible(portuguese);
        await tester.pumpAndSettle();
        expect(tester.getRect(languageDialog), original);
        await tester.tap(portuguese);
        await tester.pumpAndSettle();
        expect(
          container.read(appSettingsProvider).requireValue.language,
          AppLanguage.portuguese,
        );
        expect((await store.read()).language, AppLanguage.portuguese);
        expect(find.byKey(const ValueKey('language-dialog')), findsNothing);
        expect(find.byType(SettingsDialog), findsOneWidget);
        // Restore English without navigation and verify close and system Back.
        await container
            .read(appSettingsProvider.notifier)
            .saveChanges((s) => s.copyWith(language: AppLanguage.english));
        await tester.pumpAndSettle();
        await tester.ensureVisible(languageAction);
        await tester.tap(languageAction);
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: languageDialog,
            matching: find.bySemanticsLabel('Close'),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('language-dialog')), findsNothing);
        await tester.tap(languageAction);
        await tester.pumpAndSettle();
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('language-dialog')), findsNothing);
        expect(
          container
              .read(appRouterProvider)
              .routeInformationProvider
              .value
              .uri
              .path,
          AppRoute.settings.path,
        );
        await container
            .read(appSettingsProvider.notifier)
            .saveChanges((s) => s.copyWith(soundEffects: false));
        await tester.pumpAndSettle();
        audio.events.clear();
        await tester.tap(languageAction);
        await tester.pumpAndSettle();
        expect(audio.events, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
