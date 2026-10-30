# Android compatibility audit

Audited with Flutter 3.47.7 / Dart 3.13.5, AGP 9.1.0, Gradle 9.3.1.
No dependency versions or lockfile were upgraded for stabilization.

| Component | Evidence in installed source | Risk / decision |
| --- | --- | --- |
| flutter_tts 4.2.5 | android/build.gradle applies `kotlin-android`, legacy kotlinOptions; compileSdk 36, minSdk 24 | The legacy KGP warning is real for future Flutter migration. Keep current working toolchain; do not set builtInKotlin=true while this plugin still requires migration. |
| home_widget 0.10.0 | android/build.gradle conditionally applies `kotlin-android` when builtInKotlin=false; includes a branch for AGP 9 built-in Kotlin | Current warning follows the app's legacy setting. Plugin has migration support; an upgrade is not needed solely to remove this warning. Test it together with all plugins when changing the toolchain. |
| App | android/gradle.properties keeps `android.builtInKotlin=false`, `android.newDsl=false` from Flutter template | Temporary compatibility path supported by the current Flutter. Warning is about future builds, not evidence of a runtime audio/widget failure. |

Official basis: [Flutter built-in Kotlin migration guide](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin).
Flutter describes legacy KGP support on AGP 9 as temporary and requires all
plugins to migrate before opting into built-in Kotlin. No date for the project's
mandatory upgrade is assumed here. A future toolchain upgrade should be an
isolated change with a clean Android build, widget/shortcut checks and phone tests.

## Permissions

- RECORD_AUDIO is declared in the app; speech_to_text requests it on use.
  Denial/unavailable recognizer does not block typed task creation.
- image_picker launches an external camera. The app does not declare CAMERA
  or broad storage permissions. The camera application manages its own access;
  errors are explained and photo attachments remain optional.
- flutter_local_notifications contributes POST_NOTIFICATIONS/VIBRATE through
  manifest merging. Runtime notification permission is requested only for a
  reminder. RECEIVE_BOOT_COMPLETED and plugin scheduling receivers are explicit.
- No exact-alarm permission is requested: Android can delay inexact reminders.
- No login, paid API, ad, map, billing, or app-store integration was added.
