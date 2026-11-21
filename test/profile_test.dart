import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novadoku/app/app.dart';
import 'package:novadoku/app/providers/feedback_providers.dart';
import 'package:novadoku/app/providers/progress_providers.dart';
import 'package:novadoku/app/providers/settings_providers.dart';
import 'package:novadoku/core/services/app_settings.dart';
import 'package:novadoku/core/services/feedback_services.dart';
import 'package:novadoku/core/services/progress_journal.dart';
import 'package:novadoku/core/services/settings_store.dart';
import 'package:novadoku/features/home/home_nova_character.dart';
import 'package:novadoku/features/home/home_screen.dart';
import 'package:novadoku/features/home/home_level_selector.dart';
import 'package:novadoku/game_engine/generator/puzzle_generator.dart';
import 'package:novadoku/game_engine/models/puzzle_game.dart';
import 'package:novadoku/features/home/profile/player_profile.dart';
import 'package:novadoku/features/home/profile/profile_avatar.dart';
import 'package:novadoku/features/home/profile/profile_provider.dart';
import 'package:novadoku/l10n/nova_localizations.dart';
import 'package:novadoku/shared/widgets/nova_buttons.dart';

import 'support/feedback_fakes.dart';

const _stage = ValueKey('profile capture');

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

  test(
    'all profile selections serialize and names support grapheme clusters',
    () {
      expect(ProfileAvatar.values.length, 8);
      expect(ProfileFrame.values.length, 8);
      for (final avatar in ProfileAvatar.values) {
        for (final frame in ProfileFrame.values) {
          final p = PlayerProfile(
            username: 'मीरा 日本語',
            avatar: avatar,
            frame: frame,
          );
          expect(PlayerProfile.fromJson(p.toJson()).toJson(), p.toJson());
        }
      }
      expect(PlayerProfile.validName('👨‍👩‍👧‍👦' * 32), isTrue);
      expect(PlayerProfile.validName('a' * 33), isFalse);
      expect(PlayerProfile.validName('  '), isFalse);
      expect(PlayerProfile.validName('name\n'), isFalse);
      expect(
        () => PlayerProfile.fromJson({
          'version': 1,
          'username': 'a',
          'avatar': 'missing',
          'frame': 'rose',
        }),
        throwsFormatException,
      );
    },
  );

  test('profile journal restores across restarts and recovers a corrupt generation', () async {
    final storage = MemoryProgressStorage();
    final journal = ProgressJournal(storage);
    await journal.write('unrelated', {'value': 42});
    final unrelated = Map.of(storage.files);
    final container = ProviderContainer(
      overrides: [progressJournalProvider.overrideWithValue(journal)],
    );
    expect(
      (await container.read(playerProfileProvider.future)).toJson(),
      const PlayerProfile().toJson(),
    );
    final controller = container.read(playerProfileProvider.notifier);
    const first = PlayerProfile(
      username: 'Mira',
      avatar: ProfileAvatar.fox,
      frame: ProfileFrame.mint,
    );
    const second = PlayerProfile(
      username: 'Ren',
      avatar: ProfileAvatar.bear,
      frame: ProfileFrame.cosmic,
    );
    await controller.save(first);
    await controller.save(second);
    container.dispose();
    final restarted = ProviderContainer(
      overrides: [
        progressJournalProvider.overrideWithValue(ProgressJournal(storage)),
      ],
    );
    expect(
      (await restarted.read(playerProfileProvider.future)).toJson(),
      second.toJson(),
    );
    restarted.dispose();
    storage.files['profile.0'] = 'interrupted save';
    final recovered = ProviderContainer(
      overrides: [
        progressJournalProvider.overrideWithValue(ProgressJournal(storage)),
      ],
    );
    expect(
      (await recovered.read(playerProfileProvider.future)).toJson(),
      first.toJson(),
    );
    recovered.dispose();
    for (final entry in unrelated.entries) {
      expect(storage.files[entry.key], entry.value);
    }
  });

  test(
    'failed saves preserve the prior profile and later ordered writes recover',
    () async {
      final storage = _FailingStorage();
      final container = ProviderContainer(
        overrides: [
          progressJournalProvider.overrideWithValue(ProgressJournal(storage)),
        ],
      );
      addTearDown(container.dispose);
      final original = await container.read(playerProfileProvider.future);
      final controller = container.read(playerProfileProvider.notifier);
      storage.fail = true;
      await expectLater(
        controller.save(const PlayerProfile(username: 'Failed')),
        throwsStateError,
      );
      expect(container.read(playerProfileProvider).value, same(original));
      storage.fail = false;
      await Future.wait([
        controller.save(const PlayerProfile(username: 'First')),
        controller.save(
          const PlayerProfile(username: 'Last', frame: ProfileFrame.rainbow),
        ),
      ]);
      expect(container.read(playerProfileProvider).value!.username, 'Last');
      final restored = await ProgressJournal(storage)
          .read('profile', PlayerProfile.fromJson);
      expect(restored!.username, 'Last');
    },
  );

  test(
    'all eight avatar images are valid offline artwork with alpha',
    () async {
      for (final avatar in ProfileAvatar.values) {
        final data = await rootBundle.load(profileAvatarAsset(avatar));
        final codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
        final frame = await codec.getNextFrame();
        try {
          expect(frame.image.width, greaterThanOrEqualTo(256));
          final rgba = (await frame.image.toByteData())!.buffer.asUint8List();
          expect(rgba[3], 0);
          expect(rgba.any((v) => v > 0), isTrue);
        } finally {
          frame.image.dispose();
          codec.dispose();
        }
      }
    },
  );

  testWidgets(
    'profile drafts preview instantly, cancel discards, Confirm persists once',
    (tester) async {
      final storage = MemoryProgressStorage();
      final container = await _host(tester, storage: storage);
      final initial = await container.read(playerProfileProvider.future);
      final beforeFiles = Map.of(storage.files);
      await _open(tester, 'Profile');
      expect(find.byKey(const ValueKey('profile-avatars')), findsOneWidget);
      expect(find.text('Username'), findsNothing);
      expect(find.byType(ProfileEditGlyph), findsOneWidget);
      final avatarsGrid = find.byKey(const ValueKey('profile-avatars'));
      final tiles = tester.widgetList<ProfileAvatarView>(
        find.descendant(
          of: avatarsGrid,
          matching: find.byType(ProfileAvatarView),
        ),
      );
      expect(tiles, hasLength(8));
      expect(tiles.every((view) => view.frame == null), isTrue);
      expect(ProfilePalette.avatarColors.values.toSet(), hasLength(8));

      for (final avatar in ProfileAvatar.values) {
        expect(find.byKey(ValueKey('avatar-${avatar.name}')), findsOneWidget);
      }
      await tester.enterText(find.byType(TextField), 'Mira');
      await _tap(tester, find.byKey(const ValueKey('avatar-fox')));
      await _tap(tester, find.text('Frame'));
      final framesGrid = find.byKey(const ValueKey('profile-frames'));
      expect(
        find.descendant(
          of: framesGrid,
          matching: find.byType(ProfileFramePreview),
        ),
        findsNWidgets(8),
      );
      expect(
        find.descendant(
          of: framesGrid,
          matching: find.byType(ProfileAvatarView),
        ),
        findsNothing,
      );
      expect(
        find.descendant(of: framesGrid, matching: find.byType(Image)),
        findsNothing,
      );

      await _tap(tester, find.byKey(const ValueKey('frame-rainbow')));
      final preview = tester.widget<ProfileAvatarView>(
        find.descendant(
          of: find.byKey(const ValueKey('profile-preview')),
          matching: find.byType(ProfileAvatarView),
        ),
      );
      expect(preview.avatar, ProfileAvatar.fox);
      expect(preview.frame, ProfileFrame.rainbow);
      expect(container.read(playerProfileProvider).value, same(initial));
      expect(storage.files, beforeFiles);
      await _capture(tester, 'draft-frames');
      await _tap(tester, find.bySemanticsLabel('Close'));
      expect(container.read(playerProfileProvider).value, same(initial));
      await _open(tester, 'Profile');
      await _tap(tester, find.byKey(const ValueKey('avatar-lion')));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(container.read(playerProfileProvider).value, same(initial));
      await _open(tester, 'Profile');
      await _tap(tester, find.byKey(const ValueKey('avatar-koala')));
      await tester.tapAt(const Offset(4, 100));
      await tester.pumpAndSettle();
      expect(container.read(playerProfileProvider).value, same(initial));
      expect(storage.files, beforeFiles);
      await _open(tester, 'Profile');
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Nova',
      );
      await tester.enterText(find.byType(TextField), 'Mira');
      await _tap(tester, find.byKey(const ValueKey('avatar-panda')));
      await _tap(tester, find.text('Frame'));
      await _tap(tester, find.byKey(const ValueKey('frame-cosmic')));
      await _tap(tester, find.text('Avatar'));
      await _capture(tester, 'avatars');
      final button = tester.widget<NovaPrimaryButton>(
        find.widgetWithText(NovaPrimaryButton, 'Confirm'),
      );
      for (var tap = 0; tap < 12; tap++) {
        button.onPressed!();
      }
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(
        container.read(playerProfileProvider).value!.avatar,
        ProfileAvatar.panda,
      );
      expect(container.read(playerProfileProvider).value!.username, 'Mira');
      expect(
        container.read(playerProfileProvider).value!.frame,
        ProfileFrame.cosmic,
      );
      expect(
        storage.files.keys.where((name) => name.startsWith('profile.')),
        hasLength(1),
      );
      expect(
        tester.widget<ProfileAvatarView>(find.byType(ProfileAvatarView)).avatar,
        ProfileAvatar.panda,
      );
      await _capture(tester, 'home-confirmed');
    },
  );

  testWidgets(
    'profile dismissal preserves the selected replay and campaign session',
    (tester) async {
      final generated = PuzzleGenerator.generate(size: 4, seed: 11);
      final campaign = CampaignProgress(
        game: PuzzleGame.start(generated.puzzle, level: 11),
        completed: Set.unmodifiable(List.generate(10, (i) => i + 1)),
        unlockedThrough: 11,
      );
      await _host(tester, campaign: campaign);
      tester
          .widget<HomeLevelSelector>(find.byType(HomeLevelSelector))
          .onSelected(4);
      await tester.pumpAndSettle();
      expect(find.text('Play level 4'), findsOneWidget);
      await _open(tester, 'Profile');
      await _tap(tester, find.bySemanticsLabel('Close'));
      expect(find.text('Play level 4'), findsOneWidget);
      expect(find.text('LEVEL 4'), findsOneWidget);
    },
  );

  testWidgets(
    'profile modal and keyboard never move, scroll or resize Home Nova',
    (tester) async {
      final container = await _host(tester);
      final targets = [
        find.byType(HomeNovaCharacter),
        find.text('Play level 1'),
        find.text('LEVEL 1'),
      ];
      final rectangles = targets.map(tester.getRect).toList();
      final scroll = tester
          .state<ScrollableState>(
            find
                .descendant(
                  of: find.byType(HomeScreen),
                  matching: find.byType(Scrollable),
                )
                .first,
          )
          .position;
      final offset = scroll.pixels;
      await _open(tester, 'Profile');
      expect(targets.map(tester.getRect).toList(), rectangles);
      final audio = container.read(audioServiceProvider) as RecordingAudio;
      audio.events.clear();
      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(audio.events, [FeedbackEvent.uiClick]);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      tester.view.padding = const FakeViewPadding(top: 32);
      await tester.pumpAndSettle();
      expect(targets.map(tester.getRect).toList(), rectangles);
      expect(scroll.pixels, offset);
      await tester.enterText(find.byType(TextField), 'Ren');
      await _tap(tester, find.text('Confirm'));
      expect(targets.map(tester.getRect).toList(), rectangles);
      expect(scroll.pixels, offset);
      expect(container.read(playerProfileProvider).value!.username, 'Ren');
      tester.view.viewInsets = const FakeViewPadding();
      tester.view.padding = const FakeViewPadding(top: 32, bottom: 24);
      await tester.pumpAndSettle();
      expect(targets.map(tester.getRect).toList(), rectangles);
    },
  );

  for (final language in AppLanguage.values.where((v) => v.code != null)) {
    testWidgets('profile is usable on a compact screen in ${language.code}', (
      tester,
    ) async {
      await _host(
        tester,
        language: language,
        size: const Size(320, 568),
        scale: 1.5,
      );
      final strings = lookupAppLocalizations(Locale(language.code!));
      await _open(tester, strings.profile);
      for (final avatar in ProfileAvatar.values) {
        await _tap(tester, find.byKey(ValueKey('avatar-${avatar.name}')));
      }
      final cells = [
        for (final avatar in ProfileAvatar.values)
          tester.getRect(find.byKey(ValueKey('avatar-${avatar.name}'))),
      ];
      expect(cells.take(4).map((r) => r.top).toSet(), hasLength(1));
      expect(cells.skip(4).map((r) => r.top).toSet(), hasLength(1));
      await _tap(tester, find.text(strings.profileFrames));
      for (final frame in ProfileFrame.values) {
        await _tap(tester, find.byKey(ValueKey('frame-${frame.name}')));
      }
      await _capture(tester, '${language.code}-compact');
      await _tap(tester, find.text(strings.profileConfirm));
      expect(tester.takeException(), isNull);
    });
  }
}

Future<ProviderContainer> _host(
  WidgetTester tester, {
  ProgressStorage? storage,
  CampaignProgress? campaign,
  AppLanguage language = AppLanguage.english,
  Size size = const Size(390, 844),
  double scale = 1,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  tester.view.padding = const FakeViewPadding(top: 32, bottom: 24);
  tester.view.viewPadding = const FakeViewPadding(top: 32, bottom: 24);
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  if (const bool.fromEnvironment('PROFILE_CAPTURE')) {
    await tester.runAsync(() async {
      await (FontLoader(
        'MaterialIcons',
      )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      for (final family in [
        'DynaPuff',
        'Nunito Sans',
        'Noto Sans',
        'Noto Sans JP',
        'Noto Sans Devanagari',
      ]) {
        await (FontLoader(family)..addFont(
              rootBundle.load('assets/fonts/${family.replaceAll(' ', '')}.ttf'),
            ))
            .load();
      }
    });
  }
  final container = ProviderContainer(
    overrides: [
      if (campaign != null)
        campaignRestoreProvider.overrideWithValue(AsyncData(campaign)),
      progressJournalProvider.overrideWithValue(
        ProgressJournal(storage ?? MemoryProgressStorage()),
      ),
      settingsStoreProvider.overrideWithValue(_Settings(language)),
      audioServiceProvider.overrideWithValue(RecordingAudio()),
      hapticServiceProvider.overrideWithValue(RecordingHaptics()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    RepaintBoundary(
      key: _stage,
      child: UncontrolledProviderScope(
        container: container,
        child: const NovaApp(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.runAsync(
    () => Future.wait([
      for (final avatar in ProfileAvatar.values)
        precacheImage(
          AssetImage(profileAvatarAsset(avatar)),
          tester.element(find.byType(Scaffold)),
        ),
    ]),
  );
  await tester.pumpAndSettle();
  return container;
}

Future<void> _open(WidgetTester tester, String label) async {
  await _tap(tester, find.bySemanticsLabel(label));
  for (
    var step = 0;
    step < 40 && find.byType(TextField).evaluate().isEmpty;
    step++
  ) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
    await tester.pumpAndSettle();
  }
  expect(find.byType(TextField), findsOneWidget);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('PROFILE_CAPTURE')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_stage),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
      final file = File('build/profile_review/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

class _Settings implements SettingsStore {
  const _Settings(this.language);
  final AppLanguage language;
  @override
  Future<AppSettings> read() async => AppSettings(language: language);
  @override
  Future<void> write(AppSettings settings) async {}
}

class _FailingStorage implements ProgressStorage {
  final inner = MemoryProgressStorage();
  bool fail = false;
  @override
  Future<String?> read(String name) => inner.read(name);
  @override
  Future<Set<String>> names() => inner.names();
  @override
  Future<void> replace(String name, String content) {
    if (fail) throw StateError('Disk unavailable');
    return inner.replace(name, content);
  }
}
