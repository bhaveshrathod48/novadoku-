import 'package:flutter/services.dart';

import '../constants/app_assets.dart';

enum SoundCue {
  button('ui_click', 575, 0.65),
  placement('place_nova', 310, 0.44),
  markX('x_tap', 152, 0.28),
  markXSwipe('x_swipe', 75, 0.28),
  mistake('wrong_placement', 240, 0.38),
  heartLoss('heart_loss', 260, 0.31),
  hint('hint', 580, 0.40),
  victory('level_complete', 1420, 0.49),
  failure('level_failure', 790, 0.38),
  novaTap('nova_tap', 430, 0.39);

  const SoundCue(this.file, this.milliseconds, this.volume);

  final String file;
  final int milliseconds;
  final double volume;

  bool get isXMark => this == markX || this == markXSwipe;
  String get asset =>
      this == button ? AppAssets.uiClickSound : '${AppAssets.sounds}/$file.wav';
  Duration get duration => Duration(milliseconds: milliseconds);
}

enum HapticCue { light, medium, selection, success, error }

enum FeedbackEvent {
  button([SoundCue.button], HapticCue.light, 0),
  navigationBack([SoundCue.button], HapticCue.light, 0),
  navigationNext([SoundCue.button], HapticCue.light, 0),
  selection([SoundCue.button], HapticCue.selection, 0),
  uiClick([SoundCue.button], null, 0),
  novaTap([SoundCue.novaTap], HapticCue.light, 1),
  placement([SoundCue.placement], HapticCue.success, 1),
  markX([SoundCue.markX], HapticCue.light, 1),
  markXSwipe([SoundCue.markXSwipe], HapticCue.light, 1),
  mistake([SoundCue.mistake, SoundCue.heartLoss], HapticCue.error, 2),
  hint([SoundCue.hint], HapticCue.medium, 2),
  victory([SoundCue.placement, SoundCue.victory], HapticCue.success, 3),
  hintVictory([SoundCue.hint, SoundCue.victory], HapticCue.success, 3),
  failure(
    [SoundCue.mistake, SoundCue.heartLoss, SoundCue.failure],
    HapticCue.error,
    3,
  );

  const FeedbackEvent(this.sounds, this.haptic, this.priority);

  final List<SoundCue> sounds;
  final HapticCue? haptic;
  final int priority;
  bool get isXMark => this == markX || this == markXSwipe;
}

abstract interface class AudioService {
  Future<void> configure({required bool music, required bool effects});
  Future<void> play(FeedbackEvent event);
  Future<void> dispose();
}

abstract interface class HapticService {
  Future<void> play(HapticCue cue);
}

final class SystemHapticService implements HapticService {
  const SystemHapticService();

  @override
  Future<void> play(HapticCue cue) => switch (cue) {
    HapticCue.light => HapticFeedback.lightImpact(),
    HapticCue.medium => HapticFeedback.mediumImpact(),
    HapticCue.selection => HapticFeedback.selectionClick(),
    HapticCue.success => HapticFeedback.successNotification(),
    HapticCue.error => HapticFeedback.errorNotification(),
  };
}
