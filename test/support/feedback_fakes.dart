import 'package:novadoku/core/services/feedback_services.dart';

class RecordingAudio implements AudioService {
  final configurations = <({bool music, bool effects})>[];
  final events = <FeedbackEvent>[];
  bool disposed = false;

  @override
  Future<void> configure({required bool music, required bool effects}) async {
    configurations.add((music: music, effects: effects));
  }

  @override
  Future<void> play(FeedbackEvent event) async => events.add(event);

  @override
  Future<void> dispose() async => disposed = true;
}

class RecordingHaptics implements HapticService {
  final cues = <HapticCue>[];

  @override
  Future<void> play(HapticCue cue) async => cues.add(cue);
}
