import 'support/gameplay_gestures.dart';

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novadoku/app/app.dart';
import 'package:novadoku/app/providers/feedback_providers.dart';
import 'package:novadoku/app/providers/game_providers.dart';
import 'package:novadoku/app/providers/settings_providers.dart';
import 'package:novadoku/app/router/app_router.dart';
import 'package:novadoku/core/services/app_settings.dart';
import 'package:novadoku/core/services/progress_journal.dart';
import 'package:novadoku/core/services/settings_store.dart';
import 'package:novadoku/game_engine/generator/puzzle_catalog.dart';
import 'package:novadoku/game_engine/generator/puzzle_generator.dart';
import 'package:novadoku/game_engine/hints/hint_engine.dart';
import 'package:novadoku/game_engine/models/puzzle_game.dart';
import 'package:novadoku/l10n/hint_localizations.dart';
import 'package:novadoku/l10n/nova_localizations.dart';
import 'package:novadoku/shared/dialogs/nova_modal.dart';

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

  TestWidgetsFlutterBinding.ensureInitialized();

  test('all catalogs have complete messages and matching placeholders', () {
    final english =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map;
    final keys = english.keys
        .cast<String>()
        .where((key) => !key.startsWith('@'))
        .toSet();
    expect(
      keys,
      containsAll([
        'novaUsesRemaining',
        'hint',
        'restartPuzzle',
        'restartDescription',
      ]),
    );
    for (final locale in AppLocalizations.supportedLocales) {
      final arb = jsonDecode(
        File('lib/l10n/app_${locale.languageCode}.arb').readAsStringSync(),
      ) as Map;
      expect(
        arb.keys.cast<String>().where((key) => !key.startsWith('@')).toSet(),
        keys,
      );
      for (final key in keys) {
        expect(arb[key], isA<String>());
        expect((arb[key] as String).trim(), isNotEmpty, reason: '$locale $key');
        final metadata = english['@$key'] as Map?;
        if (metadata == null) continue;
        for (final placeholder in (metadata['placeholders'] as Map).keys) {
          expect(arb[key], contains('{$placeholder'), reason: '$locale $key');
        }
      }
    }
  });

  test(
    'language preference survives restart for every locale and old preferences',
    () async {
      final storage = MemoryProgressStorage();
      for (final language in AppLanguage.values) {
        final store = LocalSettingsStore(
          ProgressJournal(storage),
          readLegacy: () async => null,
        );
        await store.write(
          AppSettings(language: language, music: true, regionPatterns: true),
        );
        final restored = await LocalSettingsStore(
          ProgressJournal(storage),
          readLegacy: () async => null,
        ).read();
        expect(restored.language, language);
        expect(restored.music, isTrue);
        expect(restored.regionPatterns, isTrue);
      }
      final legacy = LocalSettingsStore(
        ProgressJournal(MemoryProgressStorage()),
        readLegacy: () async => ['soundEffects', 'language:en'],
      );
      expect((await legacy.read()).language, AppLanguage.english);
      final unknown = ProgressJournal(MemoryProgressStorage());
      await unknown.write('settings', {
        'version': 1,
        'flags': ['language:xx'],
      });
      expect(
        (await LocalSettingsStore(
          unknown,
          readLegacy: () async => null,
        ).read()).language,
        AppLanguage.english,
      );
    },
  );

  test('plural forms cover zero, one, few and many', () {
    final english = lookupAppLocalizations(const Locale('en'));
    expect(english.attemptsLeft(0), '0 attempts left');
    expect(english.attemptsLeft(1), '1 attempt left');
    expect(english.attemptsLeft(3), '3 attempts left');
    final russian = lookupAppLocalizations(const Locale('ru'));
    expect(russian.attemptsLeft(1), 'Осталась 1 попытка');
    expect(russian.attemptsLeft(2), 'Осталось 2 попытки');
    expect(russian.attemptsLeft(5), 'Осталось 5 попыток');
    expect(russian.hintsRemaining(21), 'Осталась 21 подсказка');
    expect(lookupAppLocalizations(const Locale('ja')).attemptsLeft(3), '残り3回');
  });

  testWidgets(
    'Settings switches every language instantly while preserving the route and game',
    (tester) async {
      final store = _Store();
      final container = _container(store);
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const NovaApp()),
      );
      await tester.pumpAndSettle();
      await container.read(puzzleGameProvider.notifier).startLevel(1);
      final game = container.read(puzzleSessionProvider);
      final router = container.read(appRouterProvider);
      router.goNamed(AppRoute.settings.name);
      await tester.pumpAndSettle();
      for (final language in AppLanguage.values.where(
        (option) => option.code != null,
      )) {
        final previous = lookupAppLocalizations(
          Locale(store.settings.language.code ?? 'en'),
        );
        final languageAction = find.bySemanticsLabel(
          previous.languageLabel(
            previous.language,
            store.settings.language == AppLanguage.system
                ? 'English'
                : store.settings.language.nativeName,
          ),
        );
        await tester.ensureVisible(languageAction);
        await tester.tap(languageAction);
        await tester.pumpAndSettle();
        final option = find.text(language.nativeName).hitTestable();
        if (option.evaluate().isEmpty) {
          await tester.ensureVisible(
            find.descendant(
              of: find.byType(NovaDialog).last,
              matching: find.text(language.nativeName),
            ),
          );
        }
        await tester.tap(
          find.descendant(
            of: find.byType(NovaDialog).last,
            matching: find.text(language.nativeName),
          ),
        );
        await tester.pumpAndSettle();
        final current = lookupAppLocalizations(Locale(language.code!));
        expect(store.settings.language, language);
        expect(find.text(current.settings), findsOneWidget);
        expect(find.text(current.music), findsOneWidget);
        expect(container.read(puzzleSessionProvider), same(game));
        expect(container.read(appRouterProvider), same(router));
        expect(
          tester.widget<MaterialApp>(find.byType(MaterialApp)).title,
          'novadoku',
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets(
    'open logical hint translates instantly without consuming or changing the proof',
    (tester) async {
      final store = _Store();
      final container = _container(store);
      addTearDown(container.dispose);
      container.read(appRouterProvider).goNamed(AppRoute.gameplay.name);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const NovaApp()),
      );
      await tester.pumpAndSettle();
      final controller = container.read(puzzleGameProvider.notifier);
      final board = container.read(puzzleGameProvider).game!.verifiedPuzzle;
      controller.play((row: 0, column: board.columnsByRow.first));
      await tester.pumpAndSettle();
      await openHintPreview(tester, container);
      final hint = container.read(puzzleGameProvider).game!.pendingHint!;
      final session = container.read(puzzleSessionProvider);
      final english = tester.widget<NovaHintText>(find.byType(NovaHintText));
      expect(
        localizedHint(tester.element(find.byType(NovaHintText)), english.hint),
        hint.explanation,
      );
      for (final language in AppLanguage.values.where(
        (option) => option.code != null,
      )) {
        await container
            .read(appSettingsProvider.notifier)
            .saveChanges((s) => s.copyWith(language: language));
        await tester.pumpAndSettle();
        expect(
          container.read(puzzleGameProvider).game!.pendingHint,
          same(hint),
        );
        expect(container.read(puzzleSessionProvider), same(session));
        expect(
          find.text(lookupAppLocalizations(Locale(language.code!)).applyHint),
          findsOneWidget,
        );
        if (language != AppLanguage.english) {
          expect(
            localizedHint(tester.element(find.byType(NovaHintText)), hint),
            isNot(hint.explanation),
          );
        }
      }
      final cancel = find.text(
        lookupAppLocalizations(Locale(store.settings.language.code!)).cancel,
      );
      await tester.ensureVisible(cancel);
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      expect(container.read(puzzleSessionProvider)!.hintsRemaining, 3);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('unsupported system locales fall back to English', (
    tester,
  ) async {
    tester.platformDispatcher.localesTestValue = const [Locale('ar')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    final container = _container(_Store());
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const NovaApp()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Play level 1'), findsOneWidget);
    expect(
      Localizations.localeOf(tester.element(find.byType(NovaText).first)),
      const Locale('en'),
    );
  });

  testWidgets('all hint rule explanations use structured parameters', (
    tester,
  ) async {
    for (final language in AppLanguage.values.where(
      (option) => option.code != null,
    )) {
      final locale = Locale(language.code!);
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Builder(
            builder: (context) => SingleChildScrollView(
              child: Column(
                children: [
                  for (final rule in HintRule.values)
                    NovaHintText(
                      hint: PuzzleHint(
                        target: (row: 1, column: 2),
                        action: HintAction.markX,
                        rule: rule,
                        explanation:
                            'English proof is preserved by the engine.',
                        unitKind: 'region',
                        unitNumber: 4,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final element in find.byType(NovaHintText).evaluate()) {
        final hint = (element.widget as NovaHintText).hint;
        final text = localizedHint(element, hint);
        expect(text, contains('2'));
        expect(text, contains('3'));
        expect(text, isNot(contains('null')));
        expect(text, isNot(contains('English proof')));
      }
      expect(tester.takeException(), isNull);
    }
  });
}

ProviderContainer _container(_Store store) => ProviderContainer(
  overrides: [
    settingsStoreProvider.overrideWithValue(store),
    puzzleWorkProvider.overrideWithValue(const _Work()),
    audioServiceProvider.overrideWithValue(RecordingAudio()),
    hapticServiceProvider.overrideWithValue(RecordingHaptics()),
  ],
);

class _Store implements SettingsStore {
  AppSettings settings = const AppSettings();
  @override
  Future<AppSettings> read() async => settings;
  @override
  Future<void> write(AppSettings next) async => settings = next;
}

class _Work implements PuzzleWork {
  const _Work();
  @override
  Future<GeneratedPuzzle> level(int level) async =>
      PuzzleGenerator.generate(size: 4, seed: level);
  @override
  Future<GeneratedPuzzle> daily(int day) async => PuzzleCatalog.dailyByKey(day);
  @override
  Future<PuzzleGame> restore(Map<String, Object?> snapshot) async =>
      PuzzleGame.restore(snapshot);
  @override
  Future<PuzzleGame> preview(PuzzleGame game) async => game.previewHint();
}
