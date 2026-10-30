# HomeBuddy

Android-first, offline-first home task companion. Tasks and reminder times are
stored on-device; notifications are scheduled locally by Android. The current
MVP has a hand-drawn Cholera character, task categories, completion and delete
actions, and optional date/time reminders.

## Development

Requirements: Flutter stable, Dart, Android SDK / Android Studio, and an Android
emulator or device.

```sh
flutter pub get
dart run build_runner build
flutter analyze
flutter test
flutter run
flutter build apk --debug
```

The debug APK is written to `build/app/outputs/flutter-apk/app-debug.apk`.

## Package choices

The versions in `pubspec.lock` were resolved with Flutter 3.47.7 and Dart 3.13.5.
The MVP uses:

| Package | Constraint | Purpose |
| --- | --- | --- |
| `flutter_riverpod` | `^3.4.3` | state and dependency injection |
| `go_router` | `^18.1.2` | screen navigation |
| `drift` / `drift_flutter` | `^2.35.3` / `^0.3.1` | local SQLite storage |
| `flutter_local_notifications` | `^22.3.3` | scheduled local reminders |
| `flutter_timezone` / `timezone` | `^5.1.1` / `^0.11.2` | device-local reminder times |

Quick Capture now uses `speech_to_text ^7.5.0`, `image_picker ^1.2.4`,
`home_widget ^0.10.0`, and `quick_actions ^1.1.1`. Cholera uses
`flutter_tts ^4.2.5`; local preferences use `shared_preferences ^2.5.6`.
No registration is required. See `docs/DEVELOPMENT_REPORT.md` for behavior,
validation scope, and platform requirements.

No paid AI API, Firebase, Google Maps API, or AdMob is configured.

## Cholera artwork

`assets/characters/cholera/` reserves the asset and animation structure.
`CholeraCharacter` draws and animates the original character in Flutter. See its `README.md` and `manifest.json` before adding
sprite sheets or choosing an animation runtime.
