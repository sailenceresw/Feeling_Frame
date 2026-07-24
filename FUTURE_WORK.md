# feelm — Later Work To Do

## A. Run locally (blocked only by the lack of a Flutter SDK in the dev environment)

These steps could not be executed here because no Flutter/Dart SDK was
available. They are mechanical and should be run on a machine with Flutter
installed:

1. `flutter pub get` — resolve dependencies (incl. the newly added
   `image_picker` and `flutter_launcher_icons`).
2. `dart run flutter_launcher_icons` — generate the Android/iOS launcher
   icons from `assets/images/app_logo.png`.
3. `flutter analyze` — static analysis; fix anything it flags (the code was
   verified statically here, but only a real compile is authoritative).
4. `flutter test` — run the unit tests in `test/` (SRT builder, project model).
5. `flutter run` on an Android device and an iOS device — verify the
   on-device-only paths: FFmpeg filters (stabilization/vid.stab, chromakey,
   drawtext watermark, waveform), overlay burn-in positioning, camera capture,
   and gallery save/share.

## B. Future feature enhancements (need backend / CV / ML beyond the app)

From the project report's "Future Enhancements":

**Partially delivered (approximate, FFmpeg-based):**

- **3D effects** — a **3D Tilt** transform (perspective warp) is implemented.
  A full 3D render pipeline (rotating cubes, depth) remains future work.
- **Keyframe-style animation** — a **Ken Burns Zoom** (animated push-in) and
  animated **Fade In/Out** are implemented. A full keyframe *timeline* UI
  (arbitrary per-property keyframes) remains future work.

**Genuinely infeasible in the on-device app — intentionally not stubbed,
because faking them would misrepresent the artefact:**

1. **Cloud collaboration & version control** — requires an authenticated
   backend with real-time sync and per-user permissions. (Local project
   rename/management is implemented as a first step.)
2. **Real object motion tracking** — requires an on-device computer-vision /
   ML pipeline; FFmpeg cannot track arbitrary objects.
3. **LSTM model training** — an ML research/training effort (scene
   recognition, content prioritization), not an in-app feature.

Also: the Premium upgrade currently uses a local unlock; wiring real billing
needs the App Store / Play Store IAP SDKs and store configuration.
