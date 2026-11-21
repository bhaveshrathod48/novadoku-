import 'package:flutter/material.dart';

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novadoku/app/app.dart';
import 'package:novadoku/app/providers/feedback_providers.dart';
import 'package:novadoku/app/providers/game_providers.dart';
import 'package:novadoku/app/providers/settings_providers.dart';
import 'package:novadoku/app/router/app_router.dart';
import 'package:novadoku/core/constants/app_assets.dart';
import 'package:novadoku/core/services/app_settings.dart';
import 'package:novadoku/core/services/settings_store.dart';
import 'package:novadoku/core/services/feedback_services.dart';
import 'package:novadoku/core/theme/app_colors.dart';
import 'package:novadoku/core/theme/app_theme.dart';
import 'package:novadoku/features/gameplay/gameplay_screen.dart';
import 'package:novadoku/features/daily_challenge/daily_challenge_screen.dart';
import 'package:novadoku/features/tutorial/how_to_play_screen.dart';
import 'package:novadoku/features/home/home_wordmark.dart';
import 'package:novadoku/features/home/home_nova_character.dart';
import 'package:novadoku/game_engine/generator/puzzle_catalog.dart';
import 'package:novadoku/game_engine/generator/puzzle_generator.dart';
import 'package:novadoku/game_engine/models/puzzle_game.dart';
import 'package:novadoku/shared/characters/nova_assets.dart';
import 'package:novadoku/shared/dialogs/nova_modal.dart';
import 'package:novadoku/shared/layouts/nova_scaffold.dart';
import 'package:novadoku/shared/widgets/nova_buttons.dart';
import 'package:novadoku/shared/widgets/nova_grid_cell.dart';
import 'package:novadoku/shared/widgets/nova_heart_indicator.dart';
import 'package:novadoku/shared/widgets/nova_loading_indicator.dart';
import 'package:novadoku/shared/widgets/nova_selection_controls.dart';
import 'package:novadoku/shared/widgets/nova_surfaces.dart';

import 'support/feedback_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    TestWidgetsFlutterBinding
        .instance
        .platformDispatcher
        .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
  });
  tearDown(
    () => TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearAccessibilityFeaturesTestValue(),
  );

  testWidgets('starts Home and resolves the named destinations', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        audioServiceProvider.overrideWithValue(RecordingAudio()),
        settingsStoreProvider.overrideWithValue(
          _MemoryStore()..settings = const AppSettings(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const NovaApp()),
    );
    await tester.pumpAndSettle();

    final title = find.byType(HomeWordmark);
    expect(title, findsOneWidget);
    expect(find.text('A little puzzle. A little joy.'), findsOneWidget);
    expect(find.bySemanticsLabel('novadoku'), findsOneWidget);
    expect(find.text('LEVEL 1'), findsOneWidget);
    expect(find.text('Play level 1'), findsOneWidget);
    expect(
      Theme.of(tester.element(title)).colorScheme.primary,
      AppColors.primary,
    );

    final router = container.read(appRouterProvider);
    for (final route in AppRoute.values) {
      expect(router.namedLocation(route.name), route.path);
      if (route == AppRoute.gameplay || route == AppRoute.dailyGameplay) {
        continue;
      }
      router.goNamed(route.name);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, route.path);
      if (route != AppRoute.home) {
        switch (route) {
          case AppRoute.settings:
            expect(find.text('Make it feel like you.'), findsOneWidget);
          case AppRoute.howToPlay:
            expect(find.byType(HowToPlayScreen), findsOneWidget);
          case AppRoute.dailyChallenge:
            expect(find.byType(DailyChallengeScreen), findsOneWidget);
          default:
            fail('Unexpected destination.');
        }
        router.pop();
        await tester.pumpAndSettle();
        expect(title, findsOneWidget);
      }
    }

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Play launches or resumes the current puzzle and follows unlocks',
    (tester) async {
      final worker = _HomePuzzleWork();
      final container = ProviderContainer(
        overrides: [
          audioServiceProvider.overrideWithValue(RecordingAudio()),
          puzzleWorkProvider.overrideWithValue(worker),
          settingsStoreProvider.overrideWithValue(
            _MemoryStore()..settings = const AppSettings(),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const NovaApp()),
      );
      await tester.pumpAndSettle();

      final router = container.read(appRouterProvider);
      final controller = container.read(puzzleGameProvider.notifier);
      await tester.tap(find.text('Play level 1'));
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/play');
      expect(
        router.routeInformationProvider.value.uri.queryParameters['level'],
        '1',
      );
      expect(worker.levels, [1]);
      expect(find.byType(GameplayScreen), findsOneWidget);
      final puzzle = container.read(puzzleGameProvider).game!.verifiedPuzzle;
      controller.play((row: 0, column: puzzle.columnsByRow[0]));
      final started = container.read(puzzleSessionProvider);

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save and leave'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Play level 1'));
      await tester.pumpAndSettle();
      expect(worker.levels, [1]);
      expect(container.read(puzzleSessionProvider), same(started));

      for (final (row, column) in puzzle.columnsByRow.indexed.skip(1)) {
        controller.play((row: row, column: column));
      }
      router.goNamed(AppRoute.home.name);
      await tester.pumpAndSettle();
      expect(find.text('LEVEL 2'), findsOneWidget);
      expect(find.text('Play level 2'), findsOneWidget);
      expect(find.bySemanticsLabel('Level 2, unlocked'), findsOneWidget);

      await controller.startDaily(DateTime.utc(2026, 11, 18));
      await tester.pumpAndSettle();
      expect(find.text('Play level 2'), findsOneWidget);
    },
  );

  testWidgets(
    'settings, daily challenge and tutorial buttons open their named routes',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          audioServiceProvider.overrideWithValue(RecordingAudio()),
          settingsStoreProvider.overrideWithValue(
            _MemoryStore()..settings = const AppSettings(),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const NovaApp()),
      );
      await tester.pumpAndSettle();
      final router = container.read(appRouterProvider);
      final actions = {
        AppRoute.settings: find.bySemanticsLabel('Settings'),
        AppRoute.dailyChallenge: find.text('Daily challenge'),
        AppRoute.howToPlay: find.text('How to play'),
      };
      for (final entry in actions.entries) {
        await tester.ensureVisible(entry.value);
        await tester.tap(entry.value);
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, entry.key.path);
        await tester.tap(
          find.bySemanticsLabel(
            entry.key == AppRoute.settings ? 'Close' : 'Back',
          ),
        );
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/');
      }
      expect(container.read(puzzleSessionProvider), isNull);
    },
  );

  testWidgets(
    'English selection and settings changes reach the app and store',
    (tester) async {
      final store = _MemoryStore()..settings = const AppSettings();
      final container = ProviderContainer(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const NovaApp()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Settings'));
      await tester.pumpAndSettle();

      for (final label in [
        'Music',
        'Sound effects',
        'Haptics',
        'Region patterns',
      ]) {
        final toggle = find.bySemanticsLabel(label);
        await tester.ensureVisible(toggle);
        await tester.tap(toggle);
        await tester.pumpAndSettle();
      }
      expect(store.settings.music, isTrue);
      expect(store.settings.soundEffects, isFalse);
      expect(store.settings.haptics, isFalse);
      expect(store.settings.regionPatterns, isTrue);

      final language = find.bySemanticsLabel('Language, English');
      await tester.ensureVisible(language);
      await tester.tap(language);
      await tester.pumpAndSettle();
      await tester.tap(find.text('English').hitTestable());
      await tester.pumpAndSettle();
      expect(store.settings.language, AppLanguage.english);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
        const Locale('en'),
      );
      await tester.tap(language);
      await tester.pumpAndSettle();
      await tester.tap(find.text('System default'));
      await tester.pumpAndSettle();
      expect(store.settings.language, AppLanguage.system);
      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
        isNull,
      );

      expect(find.bySemanticsLabel('Reduced motion'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'remaining screens keep primary actions reachable on compact large text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 550);
      tester.view.padding = const FakeViewPadding(top: 34, bottom: 28);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final container = ProviderContainer(
        overrides: [
          audioServiceProvider.overrideWithValue(RecordingAudio()),
          puzzleWorkProvider.overrideWithValue(_HomePuzzleWork()),
          settingsStoreProvider.overrideWithValue(
            _MemoryStore()..settings = const AppSettings(),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const NovaApp()),
      );
      final router = container.read(appRouterProvider);
      for (final (route, action) in [
        (AppRoute.settings, 'How to play'),
        (AppRoute.dailyChallenge, 'Play daily puzzle'),
        (AppRoute.howToPlay, 'Let’s play'),
      ]) {
        router.goNamed(route.name);
        await tester.pumpAndSettle();
        final target = find.text(action, findRichText: true).last;
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        expect(target.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.text('Let’s play'));
      await tester.pumpAndSettle();
      expect(find.byType(GameplayScreen), findsOneWidget);
      expect(container.read(puzzleSessionProvider)?.level, 1);
    },
  );

  testWidgets(
    'Home scrolls on a narrow safe area and Nova reacts with reduced motion',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 570);
      tester.view.padding = const FakeViewPadding(top: 32, bottom: 24);
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final container = ProviderContainer(
        overrides: [
          audioServiceProvider.overrideWithValue(RecordingAudio()),
          settingsStoreProvider.overrideWithValue(
            _MemoryStore()..settings = const AppSettings(),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const NovaApp()),
      );
      await tester.pumpAndSettle();
      final character = find.byType(HomeNovaCharacter);
      final controller = tester.widget<HomeNovaCharacter>(character).controller;
      expect(controller.value.expression, NovaExpression.idle);
      await tester.tap(character);
      await tester.pump();
      expect(controller.value.expression, NovaExpression.happy);
      await tester.ensureVisible(find.text('How to play'));
      await tester.pumpAndSettle();
      expect(find.text('How to play').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Home ignores repeated Nova taps and their duplicate feedback', (
    tester,
  ) async {
    tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.padding = const FakeViewPadding(top: 32, bottom: 24);
    tester.view.viewPadding = const FakeViewPadding(top: 32, bottom: 24);
    addTearDown(tester.view.reset);
    const capture = bool.fromEnvironment('HOME_JUMP_CAPTURE');
    if (capture) {
      await tester.runAsync(() async {
        for (final (family, asset) in [
          ('DynaPuff', 'DynaPuff'),
          ('Nunito Sans', 'NunitoSans'),
        ]) {
          await (FontLoader(
            family,
          )..addFont(rootBundle.load('assets/fonts/$asset.ttf'))).load();
        }
      });
    }
    final stage = GlobalKey();
    final audio = RecordingAudio();
    final container = ProviderContainer(
      overrides: [
        audioServiceProvider.overrideWithValue(audio),
        settingsStoreProvider.overrideWithValue(_MemoryStore()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      RepaintBoundary(
        key: stage,
        child: UncontrolledProviderScope(
          container: container,
          child: const NovaApp(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    final nova = find.byType(HomeNovaCharacter);
    for (var tap = 0; tap < 30; tap++) {
      await tester.tap(nova);
    }
    await tester.pump();
    expect(
      audio.events.where((event) => event == FeedbackEvent.novaTap),
      hasLength(1),
    );
    expect(
      audio.events.where((event) => event == FeedbackEvent.uiClick),
      hasLength(1),
    );
    expect(find.byKey(const ValueKey('Home Nova jump')), findsNothing);
    if (capture) {
      var captured = false;
      for (var step = 0; step < 700; step++) {
        final candidates = find.byKey(const ValueKey('Home Nova jump'));
        if (candidates.evaluate().isNotEmpty &&
            tester
                .widget<RawImage>(candidates)
                .debugImageLabel!
                .contains('frame 38/')) {
          expect(
            tester.getRect(candidates).top,
            lessThan(tester.getRect(nova).top),
          );
          await tester.runAsync(() async {
            final boundary =
                stage.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary;
            final image = await boundary.toImage();
            try {
              final png = (await image.toByteData(
                format: ui.ImageByteFormat.png,
              ))!;
              final folder = Directory('build/home_jump_review')
                ..createSync(recursive: true);
              await File('${folder.path}/home-jump-peak.png').writeAsBytes(
                png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes),
              );
            } finally {
              image.dispose();
            }
          });
          captured = true;
          break;
        }
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 3)),
        );
        await tester.pump(const Duration(milliseconds: 20));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 3)),
        );
        await tester.pump();
      }
      expect(captured, isTrue);
    }
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
  });

  testWidgets('bundles offline fonts and their license texts', (tester) async {
    for (final path in [
      '${AppAssets.fonts}/DynaPuff.ttf',
      '${AppAssets.fonts}/NunitoSans.ttf',
    ]) {
      expect((await rootBundle.load(path)).lengthInBytes, greaterThan(1000));
    }
    for (final path in [
      AppAssets.headingFontLicense,
      AppAssets.supportingFontLicense,
    ]) {
      expect(
        await rootBundle.loadString(path),
        contains('SIL OPEN FONT LICENSE'),
      );
    }
  });

  testWidgets('scrollable scaffold respects safe areas with larger type', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 550);
    tester.view.padding = const FakeViewPadding(top: 34, bottom: 28);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      _host(
        NovaScaffold(
          scrollable: true,
          body: Column(
            children: [
              NovaPrimaryButton(label: 'First action', onPressed: () {}),
              const SizedBox(height: 570),
              NovaSecondaryButton(
                label: 'A longer action label to wrap',
                onPressed: () {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.getTopLeft(find.byType(SingleChildScrollView)).dy, 34);
    expect(tester.getBottomRight(find.byType(SingleChildScrollView)).dy, 522);
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -490),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('A longer action label to wrap').hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'buttons accept keyboard and pointer input and block busy actions',
    (tester) async {
      var primaryTaps = 0;
      var busyTaps = 0;

      await tester.pumpWidget(
        _host(
          NovaScaffold(
            body: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NovaPrimaryButton(
                  label: 'Primary',
                  onPressed: () => primaryTaps++,
                ),
                NovaSecondaryButton(
                  label: 'Wait',
                  onPressed: () => busyTaps++,
                  loading: true,
                ),
                const NovaTextButton(label: 'Disabled', onPressed: null),
                NovaIconButton(
                  icon: Icons.close,
                  label: 'Close',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel('Primary'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.tap(find.byType(NovaLoadingIndicator));
      await tester.tap(find.bySemanticsLabel('Disabled'));
      expect(primaryTaps, 2);
      expect(busyTaps, 0);
      expect(find.bySemanticsLabel('Wait, Loading'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('renders and updates controls and cell states', (tester) async {
    var music = false;
    var mode = 'Place Nova';
    var cellTaps = 0;

    await tester.pumpWidget(
      _host(
        StatefulBuilder(
          builder: (context, setState) => NovaScaffold(
            body: NovaCard(
              elevated: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const NovaBadge(
                    label: 'PUZZLE COMPLETE',
                    tone: NovaBadgeTone.success,
                  ),
                  const NovaHeartIndicator(
                    remaining: 2,
                    semanticLabel: '2 attempts left',
                  ),
                  NovaToggle(
                    label: 'Music',
                    value: music,
                    onChanged: (next) => setState(() => music = next),
                  ),
                  NovaSegmentedControl(
                    options: const {
                      'Place Nova': 'Place Nova',
                      'Mark X': 'Mark X',
                    },
                    value: mode,
                    onChanged: (next) => setState(() => mode = next),
                  ),
                  Row(
                    children: [
                      for (final appearance in NovaCellAppearance.values)
                        SizedBox(
                          width: 52,
                          child: NovaGridCell(
                            region: NovaRegionTone.mint,
                            regionLabel: '2',
                            semanticLabel: 'Region 2, ${appearance.name}',
                            appearance: appearance,
                            onPressed: () => cellTaps++,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(NovaToggle));
    await tester.pumpAndSettle();
    expect(music, isTrue);
    expect(find.text('On'), findsOneWidget);
    await tester.tap(find.text('Mark X'));
    await tester.pumpAndSettle();
    expect(mode, 'Mark X');
    await tester.tap(find.byType(NovaGridCell).first);
    expect(cellTaps, 1);
    expect(find.text('!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dialog and sheet layer over the scaffold and return results', (
    tester,
  ) async {
    bool? dialogResult;
    String? sheetResult;
    await tester.pumpWidget(
      _host(
        NovaScaffold(
          body: Builder(
            builder: (context) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NovaPrimaryButton(
                  label: 'Open dialog',
                  onPressed: () async {
                    dialogResult = await NovaDialog.show<bool>(
                      context,
                      builder: (context) => NovaDialog(
                        title: 'Take a break?',
                        content: const Text(
                          'Your puzzle will be here when you return.',
                        ),
                        actions: [
                          NovaSecondaryButton(
                            label: 'Keep playing',
                            onPressed: () => Navigator.of(context).pop(true),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                NovaTextButton(
                  label: 'Open sheet',
                  onPressed: () async {
                    sheetResult = await NovaBottomSheet.show<String>(
                      context,
                      builder: (context) => NovaBottomSheet(
                        child: NovaPrimaryButton(
                          label: 'Apply hint',
                          onPressed: () => Navigator.of(context).pop('applied'),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open dialog'));
    await tester.pumpAndSettle();
    expect(find.text('Take a break?'), findsOneWidget);
    await tester.tap(find.text('Keep playing'));
    await tester.pumpAndSettle();
    expect(dialogResult, isTrue);
    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply hint'));
    await tester.pumpAndSettle();
    expect(sheetResult, 'applied');
    expect(tester.takeException(), isNull);
  });

  test(
    'settings writes stay ordered and preserve the last successful state',
    () async {
      final store = _MemoryStore();
      final container = ProviderContainer(
        overrides: [settingsStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);
      await container.read(appSettingsProvider.future);
      final controller = container.read(appSettingsProvider.notifier);

      store.failNext = true;
      final failed = controller.saveChanges(
        (current) => current.copyWith(soundEffects: false),
      );
      final afterFailure = expectLater(failed, throwsStateError);
      await Future.wait([
        controller.saveChanges((current) => current.copyWith(music: true)),
        controller.saveChanges((current) => current.copyWith(haptics: false)),
        afterFailure,
      ]);

      expect(store.settings.music, isTrue);
      expect(store.settings.haptics, isFalse);
      expect(store.settings.soundEffects, isTrue);
      expect(
        container.read(appSettingsProvider).requireValue,
        same(store.settings),
      );
    },
  );
}

Widget _host(Widget child) => MaterialApp(theme: AppTheme.light, home: child);

class _HomePuzzleWork implements PuzzleWork {
  final levels = <int>[];

  @override
  Future<GeneratedPuzzle> level(int number) async {
    levels.add(number);
    return PuzzleCatalog.level(number);
  }

  @override
  Future<GeneratedPuzzle> daily(int day) async => PuzzleCatalog.dailyByKey(day);

  @override
  Future<PuzzleGame> restore(Map<String, Object?> snapshot) async =>
      PuzzleGame.restore(snapshot);

  @override
  Future<PuzzleGame> preview(PuzzleGame game) async => game.previewHint();
}

class _MemoryStore implements SettingsStore {
  AppSettings settings = const AppSettings();
  bool failNext = false;

  @override
  Future<AppSettings> read() async => settings;

  @override
  Future<void> write(AppSettings next) async {
    if (failNext) {
      failNext = false;
      throw StateError('Test storage failure');
    }
    settings = next;
  }
}
