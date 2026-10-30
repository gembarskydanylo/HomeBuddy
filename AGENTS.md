# HomeBuddy development rules

## Scope and architecture

- Ship Android first. Keep the app offline-first and store user tasks in Drift.
- Organize code by feature under `lib/features/`; put persistence in `lib/data/`
  and platform integrations in `lib/services/`.
- Use Riverpod for dependency injection and reactive state, and `go_router` for
  navigation. Widgets should call feature/service APIs rather than SQL or
  platform channels directly.
- Treat notifications as optional OS capability. Persist task/reminder data
  locally even when notification permission is denied.
- Keep Cholera behind a small reusable widget/API. Future sprites or animation
  must be documented under `assets/characters/cholera/`; do not claim planned
  TTS, speech recognition, image selection, home widgets, or quick actions are
  working until implemented and configured on Android.
- Do not add paid AI APIs, Firebase, Google Maps, or AdMob without a concrete
  product requirement and explicit configuration.

## Data and platform rules

- Add Drift schema migrations when changing a released schema; never silently
  discard user data.
- Keep notification IDs stable and cancel scheduled reminders when their task
  is deleted or reminder is removed.
- Request Android permissions at the point of use and explain denied optional
  behavior in the UI.
- Store only local assets and user-selected content needed by the feature.

## Verification

- Before handing off a change, run `dart format .`, `flutter analyze`,
  `flutter test`, and `flutter build apk --debug` when the Android toolchain is
  available.
- Add focused tests for persistence and user-visible task flows.
- Report unavailable tools and any verification command that could not finish.

## Repository workflow

- Keep changes focused and review `git status` and `git diff` before committing.
- Use the configured `main` branch and the `origin` remote for this repository.
- Do not commit, push, publish, or change GitHub settings unless requested.
- Keep generated Drift source in sync with its schema and generators.
