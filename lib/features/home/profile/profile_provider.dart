import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/progress_providers.dart';
import 'player_profile.dart';

final playerProfileProvider =
    AsyncNotifierProvider<ProfileController, PlayerProfile>(
      ProfileController.new,
    );

class ProfileController extends AsyncNotifier<PlayerProfile> {
  static const storageKey = 'profile';
  Future<void> _writes = Future.value();

  @override
  Future<PlayerProfile> build() async =>
      await ref
          .watch(progressJournalProvider)
          .read(storageKey, PlayerProfile.fromJson) ??
      const PlayerProfile();

  /// Publish only after the journal has durably committed. A failed Confirm
  /// preserves the previous profile and leaves the dialog draft editable.
  Future<void> save(PlayerProfile profile) {
    if (!PlayerProfile.validName(profile.username)) {
      return Future.error(const FormatException('Invalid profile name.'));
    }
    final next = PlayerProfile(
      username: profile.username.trim(),
      avatar: profile.avatar,
      frame: profile.frame,
    );
    final operation = _writes.then((_) async {
      await future;
      if (!ref.mounted) return;
      await ref.read(progressJournalProvider).write(storageKey, next.toJson());
      if (ref.mounted) state = AsyncData(next);
    });
    _writes = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }
}
