import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novadoku/app/app.dart';
import 'package:novadoku/app/providers/feedback_providers.dart';
import 'package:novadoku/app/providers/settings_providers.dart';
import 'package:novadoku/core/constants/app_assets.dart';
import 'package:novadoku/core/services/app_settings.dart';
import 'package:novadoku/core/services/feedback_services.dart';
import 'package:novadoku/core/services/game_audio.dart';
import 'package:novadoku/core/services/settings_store.dart';

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

  test(
    'all UI cues use the supplied MP3 and protected cues stay unchanged',
    () async {
      expect(SoundCue.button.asset, 'assets/music/Ui click btn.mp3');
      expect(
        (await rootBundle.load(SoundCue.button.asset)).lengthInBytes,
        23094,
      );
      for (final event in [
        FeedbackEvent.button,
        FeedbackEvent.navigationBack,
        FeedbackEvent.navigationNext,
        FeedbackEvent.selection,
        FeedbackEvent.uiClick,
      ]) {
        expect(event.sounds, [SoundCue.button]);
      }
      expect(FeedbackEvent.uiClick.haptic, isNull);
      expect(FeedbackEvent.markX.sounds, [SoundCue.markX]);
      expect(FeedbackEvent.markXSwipe.sounds, [SoundCue.markXSwipe]);
      expect(FeedbackEvent.mistake.sounds, [
        SoundCue.mistake,
        SoundCue.heartLoss,
      ]);
      expect(FeedbackEvent.hint.sounds, [SoundCue.hint]);
      expect(FeedbackEvent.victory.sounds, [
        SoundCue.placement,
        SoundCue.victory,
      ]);
      expect(AppAssets.backgroundMusic, 'assets/music/pastel_orbit.wav');
    },
  );

  testWidgets(
    'rapid UI clicks restart once, never interrupt puzzle audio and stop on mute/dispose',
    (tester) async {
      final output = _Output();
      final audio = GameAudio(output);
      await audio.configure(music: false, effects: true);
      await tester.pump();
      await audio.play(FeedbackEvent.mistake);
      for (var i = 0; i < 40; i++) {
        await audio.play(FeedbackEvent.button);
        await tester.pump(const Duration(milliseconds: 10));
      }
      expect(output.uiStarts, 40);
      expect(output.uiPeak, 1);
      expect(output.started, [SoundCue.mistake, SoundCue.heartLoss]);
      await Future.wait(
        List.generate(100, (_) => audio.play(FeedbackEvent.navigationNext)),
      );
      expect(output.uiStarts, 41);
      await audio.configure(music: false, effects: false);
      expect(output.uiPlaying, 0);
      await audio.play(FeedbackEvent.button);
      expect(output.uiStarts, 41);
      await audio.dispose();
      await tester.pump(const Duration(seconds: 2));
      expect(output.disposed, isTrue);
      expect(output.peakPlaying, 1);
    },
  );

  testWidgets(
    'UI clicks do not depend on gameplay preload and survive native stop latency',
    (tester) async {
      final output = _Output()..preloadGate = Completer<void>();
      final audio = GameAudio(output);
      await audio.configure(music: false, effects: true);
      await tester.pump();
      await audio.play(FeedbackEvent.button);
      expect(output.uiStarts, 1);
      expect(output.started, isEmpty);
      output.uiStopGate = Completer<void>();
      final click = audio.play(FeedbackEvent.button);
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      output.uiStopGate!.complete();
      await click;
      expect(
        output.uiStarts,
        2,
        reason: 'Native latency must not silently discard a valid click',
      );
      output.preloadGate!.complete();
      await tester.pump();
      await audio.dispose();
    },
  );

  testWidgets(
    'cold UI preload retains latest click, respects mute and retries source errors',
    (tester) async {
      final output = _Output()..uiPreloadGate = Completer<void>();
      final audio = GameAudio(output);
      await audio.configure(music: false, effects: true);
      final clicks = List.generate(10, (_) => audio.play(FeedbackEvent.button));
      await tester.pump();
      expect(output.uiStarts, 0);
      output.uiPreloadGate!.complete();
      await Future.wait(clicks);
      expect(output.uiStarts, 1);
      expect(output.uiPreloads, 1);
      await audio.dispose();

      final retryOutput = _Output()..failUiPreload = true;
      final retry = GameAudio(retryOutput);
      await retry.configure(music: false, effects: true);
      await tester.pump();
      retryOutput.failUiPreload = false;
      await retry.play(FeedbackEvent.button);
      expect(retryOutput.uiStarts, 1);
      expect(retryOutput.uiPreloads, 2);
      await retry.dispose();

      final mutedOutput = _Output()..uiPreloadGate = Completer<void>();
      final muted = GameAudio(mutedOutput);
      await muted.configure(music: false, effects: true);
      final pending = muted.play(FeedbackEvent.button);
      await tester.pump();
      final mute = muted.configure(music: false, effects: false);
      mutedOutput.uiPreloadGate!.complete();
      await Future.wait([pending, mute]);
      expect(mutedOutput.uiStarts, 0);
      await muted.dispose();
    },
  );

  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'X excerpts retain the supplied tap character with clean PCM boundaries',
    () async {
      final source = await rootBundle.load(AppAssets.xMarkSound);
      expect(source.lengthInBytes, 42855);
      expect(SoundCue.markX.asset, AppAssets.xTapSound);
      expect(SoundCue.markXSwipe.asset, AppAssets.xSwipeSound);
      for (final cue in [SoundCue.markX, SoundCue.markXSwipe]) {
        final data = await rootBundle.load(cue.asset);
        expect(
          String.fromCharCodes(data.buffer.asUint8List(data.offsetInBytes, 4)),
          'RIFF',
        );
        expect(data.getUint32(24, Endian.little), 44100);
        expect(data.getUint16(22, Endian.little), 2);
        final frames = data.getUint32(40, Endian.little) ~/ 4;
        expect((frames / 44.1 - cue.milliseconds).abs(), lessThan(.03));
        expect(data.getInt16(44, Endian.little), 0);
        expect(data.getInt16(data.lengthInBytes - 2, Endian.little), 0);
        expect(cue.volume, .28);
      }
    },
  );

  for (final spacing in [0, 12, 50, 200]) {
    testWidgets(
      'every ready X edit restarts once without overlap at ${spacing}ms spacing',
      (tester) async {
        final output = _Output();
        final audio = GameAudio(output);
        await audio.configure(music: false, effects: true);
        await tester.pump();
        for (var i = 0; i < 100; i++) {
          await audio.play(
            i.isEven ? FeedbackEvent.markX : FeedbackEvent.markXSwipe,
          );
          await tester.pump(Duration(milliseconds: spacing));
        }
        expect(output.started, hasLength(100));
        expect(output.peakPlaying, 1);
        await tester.pump(const Duration(seconds: 1));
        expect(output.playing, 0);
        expect(output.started, hasLength(100));
        await audio.dispose();
      },
    );
  }

  testWidgets(
    'same-frame X burst supersedes stale starts with no audible backlog',
    (tester) async {
      final output = _Output();
      final audio = GameAudio(output);
      await audio.configure(music: false, effects: true);
      await tester.pump();
      await Future.wait(
        List.generate(100, (_) => audio.play(FeedbackEvent.markXSwipe)),
      );
      expect(output.started, [SoundCue.markXSwipe]);
      expect(output.peakPlaying, 1);
      await tester.pump(const Duration(seconds: 1));
      expect(output.playing, 0);
      expect(output.started, hasLength(1));
      await audio.dispose();
    },
  );

  testWidgets(
    'warmup and stalled X preparation never replay old interactions',
    (tester) async {
      final output = _Output()..preloadGate = Completer<void>();
      final audio = GameAudio(output);
      await audio.configure(music: false, effects: true);
      await Future.wait(
        List.generate(100, (_) => audio.play(FeedbackEvent.markXSwipe)),
      );
      output.preloadGate!.complete();
      await tester.pump();
      expect(output.started, isEmpty);
      output.prepareEffectGate = Completer<void>();
      final pending = audio.play(FeedbackEvent.markXSwipe);
      await tester.pump();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      output.prepareEffectGate!.complete();
      await pending;
      expect(output.started, isEmpty);
      output.prepareEffectGate = null;
      await audio.play(FeedbackEvent.markXSwipe);
      expect(output.started, [SoundCue.markXSwipe]);
      await audio.configure(music: false, effects: false);
      await tester.pump(const Duration(seconds: 1));
      expect(output.playing, 0);
      await audio.dispose();
    },
  );

  testWidgets(
    'disposal waits for ongoing cache preparation without changing playback',
    (tester) async {
      final output = _Output()..preloadGate = Completer<void>();
      final audio = GameAudio(output);
      await audio.configure(music: false, effects: true);
      var closed = false;
      final closing = audio.dispose().then((_) => closed = true);
      await tester.pump();
      expect(closed, isFalse);
      await audio.play(FeedbackEvent.markX);
      expect(output.started, isEmpty);
      output.preloadGate!.complete();
      await closing;
      expect(output.disposed, isTrue);
      await tester.pump(const Duration(seconds: 1));
      expect(output.started, isEmpty);
    },
  );

  test(
    'bundled PCM plays for the cue lengths and the score has a quiet loop seam',
    () async {
      final paths = {
        AppAssets.backgroundMusic: const Duration(milliseconds: 25600),
        for (final cue in SoundCue.values.where(
          (cue) => !cue.isXMark && cue != SoundCue.button,
        ))
          cue.asset: cue.duration,
      };
      expect(paths, hasLength(8));
      for (final entry in paths.entries) {
        final asset = await rootBundle.load(entry.key);
        String tag(int offset) => String.fromCharCodes(
          List.generate(4, (i) => asset.getUint8(offset + i)),
        );
        int shortAt(int offset) => asset.getUint16(offset, Endian.little);
        int longAt(int offset) => asset.getUint32(offset, Endian.little);
        expect(tag(0), 'RIFF', reason: entry.key);
        expect(tag(8), 'WAVE', reason: entry.key);
        expect(tag(12), 'fmt ', reason: entry.key);
        expect(shortAt(20), 1); // PCM
        expect(shortAt(22), 2);
        expect(longAt(24), 44100);
        expect(shortAt(34), 16);
        expect(tag(36), 'data');
        final dataBytes = longAt(40);
        expect(dataBytes, asset.lengthInBytes - 44);
        expect(dataBytes, entry.value.inMilliseconds * 44100 * 4 ~/ 1000);
        int sample(int frame, int channel) =>
            asset.getInt16(44 + frame * 4 + channel * 2, Endian.little);
        final frames = dataBytes ~/ 4;
        var max = 0;
        for (var frame = 0; frame < frames; frame++) {
          max = math.max(
            max,
            math.max(sample(frame, 0).abs(), sample(frame, 1).abs()),
          );
        }
        expect(max, inInclusiveRange(22000, 25000), reason: entry.key);
        if (entry.key == AppAssets.backgroundMusic) {
          for (var channel = 0; channel < 2; channel++) {
            final seam = (sample(0, channel) - sample(frames - 1, channel))
                .abs();
            expect(
              seam,
              lessThan(240),
              reason: 'Avoid an impulse at the PCM boundary',
            );
            expect(
              sample(0, channel).abs() + sample(frames - 1, channel).abs(),
              greaterThan(0),
            );
          }
        }
      }
    },
  );

  testWidgets('effects use a single channel and cancel their tail when muted', (
    tester,
  ) async {
    final output = _Output();
    final audio = GameAudio(output);
    await audio.configure(music: true, effects: true);
    expect(output.music, [true]);
    expect(output.preloads, 1);
    await audio.play(FeedbackEvent.failure);
    expect(output.started, [SoundCue.mistake]);
    expect(output.peakPlaying, 1);
    await audio.play(FeedbackEvent.button);
    expect(output.started, [SoundCue.mistake]);
    expect(output.uiStarts, 1);

    await tester.pump(SoundCue.mistake.duration);
    expect(output.started, [SoundCue.mistake, SoundCue.heartLoss]);
    await tester.pump(SoundCue.heartLoss.duration);
    expect(output.started, [
      SoundCue.mistake,
      SoundCue.heartLoss,
      SoundCue.failure,
    ]);
    await tester.pump(SoundCue.failure.duration);
    await audio.play(FeedbackEvent.button);
    expect(output.uiStarts, 2);
    expect(output.started.last, SoundCue.failure);

    await audio.play(FeedbackEvent.mistake);
    await audio.configure(music: true, effects: false);
    await tester.pump(const Duration(seconds: 2));
    expect(output.started.last, SoundCue.mistake);
    expect(output.playing, 0);
    expect(output.music, [true]);

    await audio.configure(music: false, effects: true);
    await audio.play(FeedbackEvent.hint);
    expect(output.started.last, SoundCue.hint);
    expect(output.music, [true, false]);
    await audio.dispose();
    await tester.pump(const Duration(seconds: 2));
    expect(output.disposed, isTrue);
    expect(output.peakPlaying, 1);
  });

  testWidgets(
    'muting during native preparation does not start stale playback',
    (tester) async {
      final output = _Output();
      final audio = GameAudio(output);
      output.prepareMusicGate = Completer<void>();
      final enable = audio.configure(music: true, effects: true);
      await tester.pump();
      final muteMusic = audio.configure(music: false, effects: true);
      output.prepareMusicGate!.complete();
      await Future.wait([enable, muteMusic]);
      expect(output.music, [false]);

      output.prepareEffectGate = Completer<void>();
      final incoming = audio.play(FeedbackEvent.victory);
      await tester.pump();
      final muteEffects = audio.configure(music: false, effects: false);
      output.prepareEffectGate!.complete();
      await Future.wait([incoming, muteEffects]);
      expect(output.started, isEmpty);
      await audio.dispose();
    },
  );

  testWidgets(
    'Settings and foreground state independently gate effects and haptics',
    (tester) async {
      final audio = RecordingAudio();
      final haptics = RecordingHaptics();
      final store = _Store();
      final container = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(store),
          audioServiceProvider.overrideWithValue(audio),
          hapticServiceProvider.overrideWithValue(haptics),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const NovaApp()),
      );
      await tester.pumpAndSettle();
      expect(audio.configurations.last, (music: false, effects: true));
      await tester.tap(find.bySemanticsLabel('Play with Nova'));
      await tester.pumpAndSettle();
      expect(audio.events, [FeedbackEvent.uiClick, FeedbackEvent.novaTap]);
      expect(haptics.cues, [HapticCue.light]);

      await tester.tap(find.bySemanticsLabel('Settings'));
      await tester.pumpAndSettle();
      audio.events.clear();
      haptics.cues.clear();
      store.writeGate = Completer<void>();
      await tester.tap(find.bySemanticsLabel('Sound effects'));
      await tester.pumpAndSettle();
      expect(audio.configurations.last, (music: false, effects: false));
      expect(store.settings.soundEffects, isTrue);
      expect(audio.events, isEmpty);
      await tester.tap(find.bySemanticsLabel('Music'));
      await tester.pumpAndSettle();
      expect(audio.configurations.last, (music: true, effects: false));
      expect(store.settings.music, isFalse);
      store.writeGate!.complete();
      await tester.pumpAndSettle();
      expect(store.settings.music, isTrue);
      expect(store.settings.soundEffects, isFalse);
      expect(haptics.cues, everyElement(HapticCue.selection));
      haptics.cues.clear();
      await tester.tap(find.bySemanticsLabel('Haptics'));
      await tester.pumpAndSettle();
      expect(store.settings.haptics, isFalse);
      await tester.tap(find.bySemanticsLabel('Close'));
      await tester.pumpAndSettle();
      expect(audio.events, isEmpty);
      expect(haptics.cues, isEmpty);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(
        TickerMode.valuesOf(
          tester.element(find.bySemanticsLabel('Play with Nova')),
        ).enabled,
        isFalse,
      );
      expect(audio.configurations.last, (music: false, effects: false));
      final feedback = container.read(feedbackPlayerProvider);
      feedback(FeedbackEvent.victory);
      expect(audio.events, isEmpty);
      expect(haptics.cues, isEmpty);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(audio.configurations.last, (music: true, effects: false));
      expect(
        TickerMode.valuesOf(
          tester.element(find.bySemanticsLabel('Play with Nova')),
        ).enabled,
        isTrue,
      );

      final settings = container.read(appSettingsProvider.notifier);
      await settings.saveChanges(
        (current) => current.copyWith(haptics: true, music: false),
      );
      feedback(FeedbackEvent.victory);
      expect(audio.events, isEmpty);
      expect(haptics.cues, [HapticCue.success]);
      await tester.pump(const Duration(milliseconds: 200));
    },
  );

  test(
    'system haptics send the four Flutter platform feedback types',
    () async {
      final calls = <MethodCall>[];
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        calls.add(call);
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
      for (final cue in HapticCue.values) {
        await const SystemHapticService().play(cue);
      }
      expect(
        calls.map((call) => call.method),
        List.filled(5, 'HapticFeedback.vibrate'),
      );
      expect(calls.map((call) => call.arguments), [
        'HapticFeedbackType.lightImpact',
        'HapticFeedbackType.mediumImpact',
        'HapticFeedbackType.selectionClick',
        'HapticFeedbackType.successNotification',
        'HapticFeedbackType.errorNotification',
      ]);
    },
  );
}

class _Store implements SettingsStore {
  AppSettings settings = const AppSettings();
  Completer<void>? writeGate;

  @override
  Future<AppSettings> read() async => settings;

  @override
  Future<void> write(AppSettings next) async {
    await writeGate?.future;
    settings = next;
  }
}

class _Output implements AudioOutput {
  Completer<void>? uiPreloadGate;
  Completer<void>? uiStopGate;
  int uiPreloads = 0;
  bool failUiPreload = false;
  @override
  Future<void> preloadUi() async {
    uiPreloads++;
    await uiPreloadGate?.future;
    if (failUiPreload) throw StateError('transient UI preload failure');
  }

  int uiStarts = 0;
  int uiPlaying = 0;
  int uiPeak = 0;
  @override
  Future<void> resumeUi() async {
    uiStarts++;
    uiPlaying++;
    uiPeak = math.max(uiPeak, uiPlaying);
  }

  @override
  Future<void> stopUi() async {
    await uiStopGate?.future;
    uiPlaying = 0;
  }

  final music = <bool>[];
  final started = <SoundCue>[];
  int preloads = 0;
  int playing = 0;
  int peakPlaying = 0;
  bool disposed = false;
  SoundCue? prepared;
  Completer<void>? prepareMusicGate;
  Completer<void>? prepareEffectGate;
  Completer<void>? preloadGate;

  @override
  Future<void> preloadEffects() async {
    preloads++;
    await preloadGate?.future;
  }

  @override
  Future<void> prepareMusic() async => await prepareMusicGate?.future;

  @override
  Future<void> setMusic(bool playing) async => music.add(playing);

  @override
  Future<void> prepareEffect(SoundCue cue) async {
    await prepareEffectGate?.future;
    prepared = cue;
  }

  @override
  Future<void> resumeEffect() async {
    playing++;
    peakPlaying = math.max(peakPlaying, playing);
    started.add(prepared!);
  }

  @override
  Future<void> stopEffect() async => playing = 0;

  @override
  Future<void> dispose() async => disposed = true;
}
