import 'package:shared_preferences/shared_preferences.dart';

import 'progress_journal.dart';

ProgressStorage createProgressStorage() => _BrowserProgressStorage();

final class _BrowserProgressStorage implements ProgressStorage {
  final _preferences = SharedPreferencesAsync();
  static const _prefix = 'novadoku.progress.';

  @override
  Future<String?> read(String name) async {
    final key = '$_prefix$name';
    final value = (await _preferences.getAll(allowList: {key}))[key];
    return value is String ? value : null;
  }

  @override
  Future<void> replace(String name, String content) =>
      _preferences.setString('$_prefix$name', content);

  @override
  Future<Set<String>> names() async => {
    for (final key in await _preferences.getKeys())
      if (key.startsWith(_prefix)) key.substring(_prefix.length),
  };
}
