# novadoku

A little puzzle. A little joy.

novadoku is a portrait Flutter logic puzzle built around Nova, a white and purple fantasy cat. Home leads into playable campaign puzzles with dynamic boards, attempts, hints, and puzzle feedback from the Dart engine and Riverpod.

## Development

Use Flutter 3.47.2 with Dart 3.13.2, the versions installed when the foundation was implemented.

```sh
flutter pub get
dart format .
flutter analyze
flutter test
flutter run
```

Run `flutter build apk --debug` to build the Android debug APK. Android needs the SDK, NDK, JDK, and SDK licenses reported by `flutter doctor -v`. The scaffold draws behind the system bars and insets interactive content around them.

The [development roadmap](docs/MASTER_PROMPT.md) defines phase scope, code ownership, and dependency choices. The [UI specification](docs/UI_SPECIFICATION.md) records the approved visual reference and its implementation tokens.
