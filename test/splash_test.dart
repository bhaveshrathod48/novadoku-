import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novadoku/app/app.dart';
import 'package:novadoku/app/providers/feedback_providers.dart';
import 'package:novadoku/app/providers/progress_providers.dart';
import 'package:novadoku/app/providers/settings_providers.dart';
import 'package:novadoku/app/providers/startup_providers.dart';
import 'package:novadoku/core/services/app_settings.dart';
import 'package:novadoku/core/services/progress_journal.dart';
import 'package:novadoku/core/services/settings_store.dart';
import 'package:novadoku/features/home/profile/player_profile.dart';
import 'package:novadoku/features/home/profile/profile_provider.dart';
import 'package:novadoku/features/splash/app_launch_gate.dart';
import 'package:novadoku/features/splash/splash_screen.dart';
import 'package:novadoku/features/home/home_screen.dart';
import 'package:novadoku/features/home/home_launch_motion.dart';
import 'package:novadoku/features/home/home_nova_character.dart';
import 'package:novadoku/app/router/app_router.dart';
import 'package:novadoku/game_engine/generator/puzzle_generator.dart';
import 'package:novadoku/game_engine/models/puzzle_game.dart';

import 'support/feedback_fakes.dart';

Future<void> paintArtwork(WidgetTester tester) async {
  await tester.runAsync(() async {
    await precacheImage(
      const AssetImage(SplashScreen.asset),
      tester.element(find.byType(SplashScreen)),
    );
  });
  await tester.pump();
}

Widget host(ProviderContainer container, {bool reduced = true}) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduced),
          child: const AppLaunchGate(child: Text('Restored Home')),
        ),
      ),
    );

void main() {
  testWidgets(
    'launch staggers Home within 1100ms without remounting Nova or replaying on return',
    (tester) async {
      final journal = ProgressJournal(MemoryProgressStorage());
      final container = ProviderContainer(
        overrides: [
          launchSplashProvider.overrideWithValue(true),
          progressJournalProvider.overrideWithValue(journal),
          audioServiceProvider.overrideWithValue(RecordingAudio()),
          settingsStoreProvider.overrideWithValue(
            LocalSettingsStore(journal, readLegacy: () async => []),
          ),
          campaignRestoreProvider.overrideWith(
            (ref) =>
                ref.watch(appStartupProvider).value?.campaign ??
                const AsyncLoading(),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const NovaApp()),
      );
      await paintArtwork(tester);
      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pump();
      final clock = HomeLaunchMotion.maybeOf(
        tester.element(find.byType(HomeScreen)),
      )!;
      final nova = tester.state(find.byType(HomeNovaCharacter));
      final size = tester.getSize(find.byType(HomeNovaCharacter));
      double opacity(int delay) {
        final part = find.byWidgetPredicate(
          (w) => w is HomeLaunchPart && w.delay == delay,
        );
        return tester
            .widget<FadeTransition>(
              find
                  .descendant(of: part, matching: find.byType(FadeTransition))
                  .first,
            )
            .opacity
            .value;
      }

      expect(clock.value, 0);
      expect(find.byType(SplashScreen), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 200));
      expect(opacity(120), greaterThan(0));
      expect(opacity(240), 0);
      expect(opacity(700), 0);
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(SplashScreen), findsNothing);
      expect(opacity(240), greaterThan(opacity(400)));
      expect(opacity(700), 0);
      await tester.pump(const Duration(milliseconds: 600));
      expect(clock.value, 1);
      expect(opacity(700), 1);
      expect(tester.state(find.byType(HomeNovaCharacter)), same(nova));
      expect(tester.getSize(find.byType(HomeNovaCharacter)), size);
      final router = container.read(appRouterProvider);
      router.goNamed(AppRoute.dailyChallenge.name);
      // Ambient particles loop continuously; wait for navigation, not every
      // animation in the destination to become idle.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      router.goNamed(AppRoute.home.name);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(
        HomeLaunchMotion.maybeOf(tester.element(find.byType(HomeScreen))),
        same(clock),
      );
      expect(opacity(700), 1);
      expect(find.byType(SplashScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'reduced motion finishes launch without replay or per-frame child rebuilds',
    (tester) async {
      var reduced = false;
      var builds = 0;
      late StateSetter update;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child: HomeLaunchMotion(
                child: HomeLaunchPart(
                  delay: 700,
                  child: Builder(
                    builder: (context) {
                      builds++;
                      return const SizedBox.square(dimension: 80);
                    },
                  ),
                ),
              ),
            );
          },
        ),
      );
      final clock = HomeLaunchMotion.maybeOf(
        tester.element(find.byType(HomeLaunchPart)),
      )!;
      final before = builds;
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      expect(builds, before);
      update(() => reduced = true);
      await tester.pump();
      expect(clock.value, 1);
      update(() => reduced = false);
      await tester.pump();
      expect(clock.value, 1);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
      expect(tester.binding.transientCallbackCount, 0);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'startup hydrates existing settings and profile without rewriting data',
    () async {
      final storage = MemoryProgressStorage();
      final journal = ProgressJournal(storage);
      final game = PuzzleGame.start(
        PuzzleGenerator.generate(size: 4, seed: 11).puzzle,
        level: 3,
      );
      final campaign = CampaignProgress(
        game: game,
        completed: {1, 2},
        unlockedThrough: 3,
      );
      await journal.write(CampaignProgress.key, campaign.toJson());
      const settings = AppSettings(language: AppLanguage.hindi);
      await LocalSettingsStore(
        journal,
        readLegacy: () async => null,
      ).write(settings);
      const profile = PlayerProfile(
        username: 'Mira',
        avatar: ProfileAvatar.fox,
        frame: ProfileFrame.mint,
      );
      await journal.write(ProfileController.storageKey, profile.toJson());
      final before = Map.of(storage.files);
      final restoredJournal = ProgressJournal(storage);
      final container = ProviderContainer(
        overrides: [
          progressJournalProvider.overrideWithValue(restoredJournal),
          settingsStoreProvider.overrideWithValue(
            LocalSettingsStore(restoredJournal, readLegacy: () async => null),
          ),
        ],
      );
      addTearDown(container.dispose);
      final startup = await container.read(appStartupProvider.future);
      expect(startup.campaign.requireValue!.toJson(), campaign.toJson());
      expect(
        container.read(appSettingsProvider).requireValue.language,
        AppLanguage.hindi,
      );
      expect(
        container.read(playerProfileProvider).requireValue.toJson(),
        profile.toJson(),
      );
      expect(storage.files, before);
    },
  );

  testWidgets('waits 2.5 seconds from artwork paint, then leaves splash once', (
    tester,
  ) async {
    final startup = Completer<StartupResult>();
    final container = ProviderContainer(
      overrides: [appStartupProvider.overrideWith((ref) => startup.future)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(host(container));
    await paintArtwork(tester);
    startup.complete(const StartupResult(AsyncData(null)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2499));
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('Restored Home'), findsNothing);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Restored Home'), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(host(container));
    expect(find.byType(SplashScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'production launch opens Home without a splash back-stack entry',
    (tester) async {
      final journal = ProgressJournal(MemoryProgressStorage());
      final container = ProviderContainer(
        overrides: [
          launchSplashProvider.overrideWithValue(true),
          progressJournalProvider.overrideWithValue(journal),
          audioServiceProvider.overrideWithValue(RecordingAudio()),
          settingsStoreProvider.overrideWithValue(
            LocalSettingsStore(
              journal,
              readLegacy: () async => ['reducedMotion'],
            ),
          ),
          campaignRestoreProvider.overrideWith(
            (ref) =>
                ref.watch(appStartupProvider).value?.campaign ??
                const AsyncLoading(),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const NovaApp()),
      );
      await paintArtwork(tester);
      expect(find.byType(HomeScreen), findsNothing);
      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(SplashScreen), findsNothing);
      expect(container.read(appRouterProvider).canPop(), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('slow initialization is awaited without another minimum delay', (
    tester,
  ) async {
    final startup = Completer<StartupResult>();
    final container = ProviderContainer(
      overrides: [appStartupProvider.overrideWith((ref) => startup.future)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(host(container, reduced: false));
    await paintArtwork(tester);
    await tester.pump(const Duration(seconds: 4));
    expect(find.byType(SplashScreen), findsOneWidget);
    startup.complete(const StartupResult(AsyncData(null)));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Restored Home'), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('disposing during entrance cancels timers and image listeners', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        appStartupProvider.overrideWith(
          (ref) async => const StartupResult(AsyncData(null)),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(host(container, reduced: false));
    await paintArtwork(tester);
    await tester.pump(const Duration(milliseconds: 180));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('contained artwork renders on narrow, tall and tablet screens', (
    tester,
  ) async {
    for (final size in [
      const Size(360, 640),
      const Size(390, 844),
      const Size(800, 1280),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: RepaintBoundary(
              key: const ValueKey('capture'),
              child: SplashScreen(onPainted: () {}),
            ),
          ),
        ),
      );
      await paintArtwork(tester);
      await tester.pump();
      expect(tester.getSize(find.byType(SplashScreen)), size);
      expect(tester.takeException(), isNull);
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('capture')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final dir = Directory('build/splash_review')
          ..createSync(recursive: true);
        File('${dir.path}/${size.width.toInt()}x${size.height.toInt()}.png')
            .writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox());
    }
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
