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

From the project report's "Future Enhancements" — intentionally not stubbed,
because faking them would misrepresent the artefact:

1. **Cloud collaboration & version control** — requires an authenticated
   backend with real-time sync and per-user permissions.
2. **Motion tracking** — requires an on-device computer-vision pipeline.
3. **3D effects** — requires a 3D render pipeline.
4. **Keyframe animation timeline** — requires a dedicated animation/render
   engine and a timeline UI.
5. **LSTM model training** — an ML research/training effort (scene
   recognition, content prioritization), not an in-app feature.

Also: the Premium upgrade currently uses a local unlock; wiring real billing
needs the App Store / Play Store IAP SDKs and store configuration.
