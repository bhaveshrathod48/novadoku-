import 'app_settings.dart';
import 'progress_journal.dart';

abstract interface class SettingsStore {
  Future<AppSettings> read();
  Future<void> write(AppSettings settings);
}

final class LocalSettingsStore implements SettingsStore {
  LocalSettingsStore(this._journal, {required this.readLegacy});

  final Future<List<String>?> Function() readLegacy;
  final ProgressJournal _journal;
  static const _key = 'settings';

  @override
  Future<AppSettings> read() async {
    final saved = await _journal.read<List<String>>(_key, (json) {
      final flags = json['flags'];
      if (json['version'] != 1 ||
          flags is! List ||
          flags.any((flag) => flag is! String)) {
        throw const FormatException('Invalid Settings save.');
      }
      return flags.cast<String>();
    });
    List<String>? flags = saved;
    if (flags == null) {
      try {
        flags = await readLegacy();
      } on TypeError {
        // An incompatible legacy value does not affect newer journal saves.
      }
    }
    if (flags == null) return const AppSettings();
    return AppSettings(
      music: flags.contains('music'),
      soundEffects: flags.contains('soundEffects'),
      haptics: flags.contains('haptics'),
      regionPatterns: flags.contains('regionPatterns'),
      language: AppLanguage.values.firstWhere(
        (language) =>
            language.code != null &&
            flags!.contains('language:${language.code}'),
        orElse: () => flags!.any((flag) => flag.startsWith('language:'))
            ? AppLanguage.english
            : AppLanguage.system,
      ),
    );
  }

  @override
  Future<void> write(AppSettings settings) => _journal.write(_key, {
    'version': 1,
    'flags': [
      if (settings.music) 'music',
      if (settings.soundEffects) 'soundEffects',
      if (settings.haptics) 'haptics',
      if (settings.regionPatterns) 'regionPatterns',
      if (settings.language.code != null) 'language:${settings.language.code}',
    ],
  });
}
