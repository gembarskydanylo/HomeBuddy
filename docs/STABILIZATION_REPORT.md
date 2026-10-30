# HomeBuddy stabilization — 30 October 2026

## Changes

- Added a small TTS controller that invalidates stale async speech requests,
  replaces rather than queues speech, supports explicit Stop, and persists mute.
  Route changes, backgrounding, screen lock lifecycle events and disposal stop
  speech; returning to the app does not resume it. Missing Ukrainian voice and
  speech errors have text fallbacks. Native engine behavior still needs phone QA.
- Centralized complete/delete actions. Cancellation must succeed before marking
  a task complete or deleting it; failure leaves the task available for retry.
  Actions are serialized and ignore stale taps for deleted records, preventing
  overlapping restore/complete operations from resurrecting a reminder.
- Check both global Android notification access and the reminder channel before
  scheduling. Denied access keeps the task locally and explains settings.
- Added clearer microphone/camera failure messages; optional audio capture stops
  in the background and late results cannot overwrite a task during Save.
- Keyboard Done saves a typed task. Camera/voice shortcuts avoid automatic
  keyboard focus. No extra registration, onboarding questions or paid services.
- Dependency constraints and lockfile are unchanged. Current legacy KGP warnings
  remain; see [compatibility audit](ANDROID_COMPATIBILITY.md) for installed-source
  evidence and Flutter's migration guidance.

## Automated checks

- `flutter analyze`: no issues.
- `flutter test`: all **17** tests passed.
- `flutter build apk --debug`: successful.
- `git diff --check`: clean.

Tests include CRUD; standard/weekend/night shift windows; settings round-trip;
SQLite v1→v2 migration; reopening an upgraded non-empty on-disk database while
preserving IDs, status, due time and photo paths; cold task entry/save navigation;
TTS rapid requests, stop, dispose, mute persistence, missing voice, route changes
and backgrounding; denied notification permission/disabled channel; cancellation
failure and concurrent complete/delete reminder safety. Platform channel tests
simulate native responses and do not establish real hardware audio/delivery.

## Emulator evidence

The final APK installed via `adb install -r` over the previous app without Clear
storage/uninstall. The existing emulator database was empty (schema v2); this
alone is not evidence for preserving a populated user's database during a real
package upgrade. The populated-file migration/reopen test supplies automated
storage evidence; a populated APK update is in the physical test plan.

Four [screenshots](screenshots/README.md) were captured from the emulator after
rendering. The debug emulator showed a slow cold start and skipped frames; no
Flutter exception was found in the inspected launch journal. Measure cold-start
latency and animation smoothness separately on a physical phone before judging
performance. No physical Android phone was connected for this task.

## Required phone testing / remaining limits

Follow [the detailed test plan](PHYSICAL_ANDROID_TEST_PLAN.md). Every physical
scenario remains NOT RUN: real Ukrainian TTS output and cancellation on lock/call,
microphone permission/recognition, camera return/lost data, launcher widgets and
shortcuts, notification delivery after swipe-away/reboot/update, OEM battery
restrictions and real night-shift timing. Inexact alarms can be delayed by
Android. Timezone changes preserve absolute task timestamps; automatic wall-clock
reinterpretation is not claimed. Android Force stop has different semantics from
swiping away and may suppress alarms until a manual launch.

## APK

`build/app/outputs/flutter-apk/app-debug.apk`

SHA-256: `eeb6567490333a74acb8e0d14b8cc781d19f3908e58d26c88bad811a2defec2c`

GitHub publication is verified by comparing the final local tree with origin/main.
No APK, keys, private database, logs, or local SDK configuration are committed.
