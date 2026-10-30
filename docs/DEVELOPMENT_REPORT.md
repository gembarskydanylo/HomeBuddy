# HomeBuddy development report

The existing Android app was extended; its name and local Drift storage remain.

## Implemented

- Git ignore rules for secrets/signing files; initial code published to `main`
  through the authenticated GitHub connector after Git HTTPS push returned 403.
- Cholera: continuous eye motion, blinking, mouth movement during actual TTS
  callbacks, four selectable emotions, animated hands, cartoon outline, humorous
  phrases, persisted mute preference. Tap the character to hear/read a phrase.
- Smart Life Schedule: weekdays/weekends, work start/end, commute, recovery,
  sleep, allowed reminder window, and repeating shift cycles with an anchor date.
  Overnight shifts are supported. Saving reschedules future task reminders.
- Quick Capture: Ukrainian speech recognition into the editable title, camera
  capture, persistent local photo attachments, lost-image recovery, launcher
  shortcuts for text/voice/photo, native Android widget with Cholera and Add.
- Drift schema v2 adds nullable photo path with a non-destructive v1 migration.
- Completed/deleted tasks cancel notifications; deleting a task removes its photo.

## Files

- `.gitignore`, `README.md`, `pubspec.yaml`, `pubspec.lock`
- `lib/main.dart`
- `lib/features/character/cholera_character.dart`
- `lib/features/schedule/life_schedule.dart`, `schedule_page.dart`
- `lib/features/tasks/add_task_page.dart`, `lib/features/home/home_page.dart`
- `lib/data/app_database.dart`, generated `app_database.g.dart`
- `lib/services/reminder_service.dart`, `capture_entrypoints.dart`
- `android/app/src/main/AndroidManifest.xml`
- `android/app/src/main/kotlin/app/homebuddy/home_buddy/CholeraWidget.kt`
- Android widget drawable, layout, and provider XML under `res/`
- `test/app_test.dart`, `test/schedule_test.dart`, `test/migration_test.dart`
- Character asset README and manifest

## Validation and practical limits

Flutter analyze, Flutter tests, and debug APK build are run for this work.
Tests cover CRUD, home screen, standard/weekend/night schedules, shift cycles,
configuration serialization, and migration of existing tasks.

TTS requires a Ukrainian voice installed in Android. Speech recognition needs
microphone permission and a system recognizer with Ukrainian support; depending
on the system service it can need internet. Neither feature uses a paid API.
Hardware audio/camera and launcher behavior should also be checked on a physical
Android device. Notifications use Android's inexact scheduling and may be delayed
by battery restrictions. A denied permission keeps the task saved and reports
that the reminder was not scheduled. The home widget is static artwork with an
Add button; full character animation runs inside the app.

APK: `build/app/outputs/flutter-apk/app-debug.apk`.

Final automated validation: `flutter analyze` reports no issues; all 8 tests
pass, including a cold shortcut form/save/return-home regression test. Debug
APK builds successfully with the selected stable package versions.

Build warning: `flutter_tts` and `home_widget` still apply the Kotlin Gradle
Plugin. They compile with this Flutter version; dependency updates will be
needed before upgrading to a Flutter version that rejects this plugin setup.
