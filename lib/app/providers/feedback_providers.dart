import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/feedback_services.dart';
import '../../core/services/game_audio.dart';
import 'settings_providers.dart';
import 'startup_providers.dart';

final audioServiceProvider = Provider.autoDispose<AudioService>((ref) {
  final service = GameAudio(BundledAudioOutput());
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

final feedbackPlayerProvider =
    Provider.autoDispose<ValueChanged<FeedbackEvent>>((ref) {
      final audio = ref.watch(audioServiceProvider);
      final haptics = ref.watch(hapticServiceProvider);
      var visible =
          (WidgetsBinding.instance.lifecycleState ??
              AppLifecycleState.resumed) ==
          AppLifecycleState.resumed;
      var settings = ref.read(appSettingsProvider).value;
      var closed = false;
      FeedbackEvent? pending;
      Timer? uiCooldown;
      Timer? hapticCooldown;
      HapticCue? lastHaptic;
      var hapticBusy = false;
      ref.onDispose(() {
        closed = true;
        pending = null;
        uiCooldown?.cancel();
        hapticCooldown?.cancel();
      });

      void dispatch(FeedbackEvent event) {
        if (closed || !visible) return;
        if (settings?.soundEffects ?? false) unawaited(audio.play(event));
        if (!(settings?.haptics ?? false) ||
            hapticBusy ||
            event.haptic == null) {
          return;
        }
        final strong =
            event.haptic == HapticCue.success ||
            event.haptic == HapticCue.error;
        final previousStrong =
            lastHaptic == HapticCue.success || lastHaptic == HapticCue.error;
        if ((hapticCooldown?.isActive ?? false) &&
            !(strong && !previousStrong)) {
          return;
        }
        lastHaptic = event.haptic;
        hapticCooldown?.cancel();
        hapticCooldown = Timer(
          Duration(milliseconds: strong ? 180 : 65),
          () {},
        );
        hapticBusy = true;
        unawaited(
          _playHaptic(
            haptics,
            event.haptic!,
          ).whenComplete(() => hapticBusy = false),
        );
      }

      void syncAudio() => unawaited(
        audio.configure(
          music:
              visible &&
              ref.read(musicLaunchReadyProvider) &&
              (settings?.music ?? false),
          effects: visible && (settings?.soundEffects ?? false),
        ),
      );

      final lifecycle = AppLifecycleListener(
        onStateChange: (state) {
          visible = state == AppLifecycleState.resumed;
          syncAudio();
        },
      );
      ref.onDispose(lifecycle.dispose);
      ref.listen(appSettingsProvider, (_, next) {
        settings = next.value;
        syncAudio();
      });
      ref.listen(musicLaunchReadyProvider, (_, _) => syncAudio());
      syncAudio();

      return (event) {
        if (closed || !visible) return;
        if (event.priority != 0) {
          // Gameplay audio remains immediate, with its existing native channel
          // ordering and durations. Never defer cell edits for UI feedback.
          // A power-up click must remain audible without adding a second
          // haptic that could suppress the original placement/hint feedback.
          if (pending != null) {
            pending = null;
            if (settings?.soundEffects ?? false) {
              unawaited(audio.play(FeedbackEvent.uiClick));
            }
          }
          dispatch(event);
          return;
        }
        // A control and its ensuing route notification describe one action.
        // Coalesce within this turn; cover a later Navigator notification too.
        final queued = pending != null;
        if (pending != FeedbackEvent.uiClick &&
            (pending == null || event != FeedbackEvent.button)) {
          pending = event;
        }
        if (queued) return;
        scheduleMicrotask(() {
          final next = pending;
          pending = null;
          if (next == null || closed || !visible) return;
          final route =
              next == FeedbackEvent.navigationBack ||
              next == FeedbackEvent.navigationNext;
          if (route && (uiCooldown?.isActive ?? false)) return;
          uiCooldown?.cancel();
          uiCooldown = Timer(const Duration(milliseconds: 90), () {});
          dispatch(next);
        });
      };
    });

Future<void> _playHaptic(HapticService service, HapticCue cue) async {
  try {
    await service.play(cue);
  } catch (error, stack) {
    developer.log(
      'Haptic feedback failed',
      name: 'novadoku.haptics',
      error: error,
      stackTrace: stack,
    );
  }
}
