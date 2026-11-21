# App localization

The seven bundled locales are English, Hindi, Japanese, French, German, Russian and Portuguese. Portuguese copy uses European Portuguese. Settings also retains the system-language option. Unsupported system languages and unknown stored locale codes fall back to English.

Flutter generates the delegates and ICU messages from the seven ARB catalogs in `lib/l10n/`. Run `flutter gen-l10n` after editing a catalog. All 111 messages exist in every locale, including dynamic level labels, counters, plural forms, controls, instructions, feedback, errors and accessibility labels. Shared presentation widgets resolve authored reference copy through the generated delegate. Dynamic messages call the generated methods directly.

Hint localization uses the engine's rule, target coordinates, unit and proof type. The English proof remains available to existing engine callers. UI hints use structured values and update with the inherited Flutter locale, including while a hint is open. Changing language keeps the router and game session in place and saves the locale code through the existing Settings journal.

Brand names novadoku and Nova and the logo artwork retain their existing form. The tagline and game copy are translated. Translations were authored for this implementation. Independent native-speaker review has not been performed.

Noto Sans, Noto Sans Devanagari and Noto Sans JP are bundled as fallback fonts. DynaPuff SemiBold/Bold and Nunito Sans SemiBold/Bold are the current primary families. DynaPuff supplies the Latin display lettering; the Noto fallbacks cover Russian, Hindi and Japanese headings. Nunito Sans supports Cyrillic supporting text directly. All fallback fonts ship with their SIL Open Font License texts, are registered in the app license registry, and render offline. [Noto Sans source](https://github.com/google/fonts/tree/main/ofl/notosans), [Devanagari source](https://github.com/google/fonts/tree/main/ofl/notosansdevanagari), [Japanese source](https://github.com/google/fonts/tree/main/ofl/notosansjp)

`test/localization_test.dart` covers catalog completeness, placeholders, plurals, persistence, fallback, instant switching and structured hints. `test/localization_surface_test.dart` exercises all ten surfaces in all seven locales at normal and enlarged text sizes with the bundled fonts. Set `--dart-define=L10N_CAPTURE=true` to write screenshots under `build/localization/`.
