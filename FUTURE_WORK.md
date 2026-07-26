# feelm — Later Work To Do

## A. Local/tooling status

DONE in the dev environment (Flutter 3.44.8 installed):
- `flutter pub get` — resolves cleanly (now incl. google_mlkit_image_labeling)
- `flutter analyze` — 0 errors (info-level lints remain)
- `flutter test` — 22/22 passing
- `dart fix --apply` — deprecations/style auto-fixed

Also DONE:
- `dart run flutter_launcher_icons` — Android mipmaps + iOS AppIcon set
  generated from `assets/images/app_logo.png` and committed.

Still to run on a real machine/device (the sandbox's network policy blocks
dl.google.com, so Gradle/Android-SDK downloads and therefore `flutter build
apk` cannot run here):
1. `flutter build apk` / `flutter run` on an Android device and an iOS
   device — verify the on-device-only paths: FFmpeg filters
   (stabilization/vid.stab, chromakey, drawtext watermark, waveform,
   auto-cut, shake-cut, adaptive colour), ML Kit object labeling, overlay
   burn-in positioning, camera capture, and gallery save/share.
2. iOS: run `pod install` (deployment target is already set to 15.5 for the
   ML Kit pods) and build/run from Xcode or `flutter run`.

## B. Future feature enhancements (need backend / CV / ML beyond the app)

From the project report's "Future Enhancements":

**Delivered:**

- **Keyframe timeline (animated pan & zoom)** — a CapCut-style **Keyframe
  Animation** editor: scrub the clip, set zoom + position keyframes at chosen
  times, and the camera interpolates smoothly between them. Rendered on-device
  with FFmpeg `zoompan` (piecewise-linear expressions); the live preview shares
  the same interpolation maths as the export (WYSIWYG). See
  `KeyframeService` + `KeyframeScreen`. Per-property independent tracks
  (e.g. rotation/opacity) remain a possible future extension.

**Partially delivered (approximate, FFmpeg-based):**

- **3D effects** — a **3D Tilt** transform (perspective warp) is implemented.
  A full 3D render pipeline (rotating cubes, depth) remains future work.
- **Ken Burns Zoom** (animated push-in) and animated **Fade In/Out** are
  implemented as one-tap presets (superseded for custom moves by the keyframe
  timeline above).

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
