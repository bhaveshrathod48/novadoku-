enum AppLanguage {
  system(null, 'System default'),
  english('en', 'English'),
  hindi('hi', 'हिन्दी'),
  japanese('ja', '日本語'),
  french('fr', 'Français'),
  german('de', 'Deutsch'),
  russian('ru', 'Русский'),
  portuguese('pt', 'Português');

  const AppLanguage(this.code, this.nativeName);
  final String? code;
  final String nativeName;
}

final class AppSettings {
  const AppSettings({
    this.music = false,
    this.soundEffects = true,
    this.haptics = true,
    this.regionPatterns = false,
    this.language = AppLanguage.system,
  });

  final bool music;
  final bool soundEffects;
  final bool haptics;
  final bool regionPatterns;
  final AppLanguage language;

  AppSettings copyWith({
    bool? music,
    bool? soundEffects,
    bool? haptics,
    bool? regionPatterns,
    AppLanguage? language,
  }) => AppSettings(
    music: music ?? this.music,
    soundEffects: soundEffects ?? this.soundEffects,
    haptics: haptics ?? this.haptics,
    regionPatterns: regionPatterns ?? this.regionPatterns,
    language: language ?? this.language,
  );
}
