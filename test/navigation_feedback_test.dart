import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novadoku/app/providers/feedback_providers.dart';
import 'package:novadoku/app/providers/settings_providers.dart';
import 'package:novadoku/app/router/navigation_feedback_observer.dart';
import 'package:novadoku/core/services/app_settings.dart';
import 'package:novadoku/core/services/feedback_services.dart';
import 'package:novadoku/core/services/progress_journal.dart';
import 'package:novadoku/core/services/settings_store.dart';

import 'support/feedback_fakes.dart';

void main() {
  testWidgets(
    'actual push, system back, barrier dismissal and replace emit once',
    (tester) async {
      final events = <FeedbackEvent>[];
      final key = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: key,
          navigatorObservers: [NavigationFeedbackObserver(events.add)],
          home: const SizedBox(),
        ),
      );
      expect(events, isEmpty);
      key.currentState!.push(
        MaterialPageRoute<void>(builder: (_) => const Text('Next')),
      );
      await tester.pumpAndSettle();
      expect(events, [FeedbackEvent.navigationNext]);
      await key.currentState!.maybePop();
      await tester.pumpAndSettle();
      expect(events.last, FeedbackEvent.navigationBack);
      showDialog<void>(
        context: key.currentContext!,
        builder: (_) => const AlertDialog(content: Text('Modal')),
      );
      await tester.pumpAndSettle();
      expect(events.last, FeedbackEvent.navigationNext);
      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();
      expect(events.last, FeedbackEvent.navigationBack);
      expect(events, hasLength(4));
      key.currentState!.pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const Text('Replace')),
      );
      await tester.pumpAndSettle();
      expect(events.last, FeedbackEvent.navigationNext);
      expect(events, hasLength(5));
    },
  );

  testWidgets(
    'button and route coalesce; gameplay audio stays immediate while haptics are bounded',
    (tester) async {
      final audio = RecordingAudio();
      final haptics = RecordingHaptics();
      final container = ProviderContainer(
        overrides: [
          audioServiceProvider.overrideWithValue(audio),
          hapticServiceProvider.overrideWithValue(haptics),
          settingsStoreProvider.overrideWithValue(_Store()),
        ],
      );
      addTearDown(container.dispose);
      await container.read(appSettingsProvider.future);
      final keep = container.listen(feedbackPlayerProvider, (_, _) {});
      addTearDown(keep.close);
      final play = container.read(feedbackPlayerProvider);
      play(FeedbackEvent.button);
      play(FeedbackEvent.navigationNext);
      await tester.pump();
      expect(audio.events, [FeedbackEvent.navigationNext]);
      expect(haptics.cues, [HapticCue.light]);
      play(FeedbackEvent.navigationNext);
      await tester.pump();
      expect(audio.events, hasLength(1));
      await tester.pump(const Duration(milliseconds: 100));
      play(FeedbackEvent.navigationBack);
      await tester.pump();
      expect(audio.events.last, FeedbackEvent.navigationBack);
      haptics.cues.clear();
      for (var i = 0; i < 100; i++) {
        play(i.isEven ? FeedbackEvent.markX : FeedbackEvent.markXSwipe);
      }
      expect(audio.events, hasLength(102));
      expect(haptics.cues.length, lessThanOrEqualTo(1));
      await tester.pump(const Duration(milliseconds: 200));
      play(FeedbackEvent.placement);
      expect(haptics.cues.last, HapticCue.success);
      await tester.pump(const Duration(milliseconds: 200));
      play(FeedbackEvent.mistake);
      expect(haptics.cues.last, HapticCue.error);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      final beforeApply = haptics.cues.length;
      play(FeedbackEvent.uiClick);
      play(FeedbackEvent.navigationBack);
      await tester.pump();
      expect(audio.events.last, FeedbackEvent.uiClick);
      expect(haptics.cues, hasLength(beforeApply));
      play(FeedbackEvent.hint);
      expect(haptics.cues.last, HapticCue.medium);
      await tester.pump();
      final settings = container.read(appSettingsProvider.notifier);
      await settings.saveChanges(
        (s) => s.copyWith(soundEffects: false, haptics: false),
      );
      final count = audio.events.length;
      final vibrations = haptics.cues.length;
      await tester.pump(const Duration(milliseconds: 200));
      play(FeedbackEvent.navigationBack);
      play(FeedbackEvent.markX);
      await tester.pump();
      expect(audio.events, hasLength(count));
      expect(haptics.cues, hasLength(vibrations));
      keep.close();
      container.dispose();
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'legacy motion flag is ignored without losing other settings or data',
    () async {
      final storage = MemoryProgressStorage();
      final journal = ProgressJournal(storage);
      await journal.write('unrelated', {'campaign': 123});
      await journal.write('settings', {
        'version': 1,
        'flags': [
          'music',
          'haptics',
          'soundEffects',
          'regionPatterns',
          'language:ja',
          'reducedMotion',
        ],
      });
      final store = LocalSettingsStore(journal, readLegacy: () async => null);
      final settings = await store.read();
      expect(
        settings.music &&
            settings.haptics &&
            settings.soundEffects &&
            settings.regionPatterns,
        isTrue,
      );
      expect(settings.language, AppLanguage.japanese);
      await store.write(settings);
      final flags = await journal.read<List<dynamic>>(
        'settings',
        (json) => json['flags']! as List<dynamic>,
      );
      expect(flags, isNot(contains('reducedMotion')));
      expect(
        await journal.read<int>(
          'unrelated',
          (json) => json['campaign']! as int,
        ),
        123,
      );
    },
  );
}

class _Store implements SettingsStore {
  AppSettings settings = const AppSettings();
  @override
  Future<AppSettings> read() async => settings;
  @override
  Future<void> write(AppSettings value) async {
    settings = value;
  }
}
