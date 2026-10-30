# Cholera character assets

The Android MVP currently draws Cholera with a Flutter `CustomPainter` in
`lib/features/character/cholera_character.dart`. This folder is the stable
asset boundary for future artwork and animation files.

Suggested layout:

- `sprites/idle/` — neutral pose, 2D sprite sheets or individual PNG frames
- `sprites/cheer/` — completed-task celebration
- `sprites/listening/` — voice-input pose
- `animations/` — Lottie, Rive, or frame sequence files
- `manifest.json` — canvas size, anchor, frame rate, and animation names

Keep the character widget API independent from the rendering format so the
MVP UI does not need to change when an animation runtime is selected.
