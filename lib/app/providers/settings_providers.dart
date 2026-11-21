import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/app_settings.dart';
import '../../core/services/feedback_services.dart';
import '../../core/services/settings_store.dart';
import 'progress_providers.dart';

final settingsStoreProvider = Provider<SettingsStore>(
  (ref) => LocalSettingsStore(
    ref.watch(progressJournalProvider),
    readLegacy: () =>
        SharedPreferencesAsync().getStringList('novadoku.settings.v1'),
  ),
);

final appSettingsProvider =
    AsyncNotifierProvider<SettingsController, AppSettings>(
      SettingsController.new,
    );

final hapticServiceProvider = Provider<HapticService>(
  (ref) => const SystemHapticService(),
);

class SettingsController extends AsyncNotifier<AppSettings> {
  Future<void> _pendingWrite = Future.value();
  final _pending = <Object, AppSettings Function(AppSettings)>{};
  AppSettings? _saved;
  int _generation = 0;

  @override
  Future<AppSettings> build() async {
    final generation = ++_generation;
    _pending.clear();
    _saved = null;
    final initial = await ref.watch(settingsStoreProvider).read();
    if (ref.mounted && generation == _generation) _saved = initial;
    return initial;
  }

  Future<void> saveChanges(
    AppSettings Function(AppSettings current) change,
  ) async {
    final current = state.value ?? await future;
    if (!ref.mounted) return;
    final generation = _generation;
    final store = ref.read(settingsStoreProvider);
    final update = Object();
    final visible = change(current);
    _pending[update] = change;
    state = AsyncData(visible);
    final operation = _pendingWrite.then((_) async {
      if (!ref.mounted || generation != _generation) return;
      try {
        final next = change(_saved ?? current);
        await store.write(next);
        if (ref.mounted && generation == _generation) _saved = next;
      } finally {
        if (ref.mounted && generation == _generation) {
          _pending.remove(update);
          // Replay newer edits over the last successful write, even if this
          // operation failed, so a slow write cannot undo a newer toggle.
          state = AsyncData(
            _pending.values.fold(
              _saved ?? current,
              (settings, apply) => apply(settings),
            ),
          );
        }
      }
    });

    // The caller receives write errors. Subsequent changes can still proceed.
    _pendingWrite = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }
}
