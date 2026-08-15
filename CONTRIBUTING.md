# Contributing to feelm

Thanks for looking at feelm. It is a Flutter video editor for Android and iOS.
This guide has the setup that actually works, the conventions the code already
follows, and the changes that will be declined so you do not spend time on them.

## Local setup

Prerequisites: the Flutter SDK. The pubspec allows Dart `>=3.2.6 <4.0.0`, and
the project is built and tested on Flutter 3.44.8.

```bash
flutter pub get

# Static analysis (this is exactly what CI runs)
flutter analyze --no-fatal-infos lib test

# Unit tests (205 tests today, all passing)
flutter test

# Run on a connected Android device or emulator
flutter run

# Or build the debug APK CI produces
flutter build apk --debug
```

iOS (macOS only):

```bash
cd ios && pod install && cd ..
flutter run
```

Launcher icons are generated, not hand-drawn. If you change
`assets/images/app_logo.png`, regenerate them:

```bash
dart run flutter_launcher_icons
```

Optional Google Cloud transcription. The rest of the app works without it. Pass
the service account at run time, never commit it:

```bash
flutter run --dart-define=GCP_SERVICE_ACCOUNT_JSON="$(cat service_account.json)"
```

## How the code is organised

- State is GetX. Controllers are singletons registered in `lib/di_init.dart`
  and read as `SomeController.instance`.
- Each editing tool is a screen under `lib/src/screens/editor/` backed by a
  service under `lib/src/services/`.
- FFmpeg services follow one shape: pure static functions that build the
  command string, plus a thin runner that executes it. The command builders
  take no I/O so they can be unit tested. See `advanced_edit_service.dart` and
  its test `test/advanced_edit_service_test.dart` for the pattern.

## Conventions to follow

1. New FFmpeg feature? Add the command builder as a pure static function and add
   a unit test for it in `test/`, matching an existing `*_service_test.dart`.
   The command string can be verified without a device even though running it
   needs one.
2. Keep `flutter analyze` and `flutter test` green. CI runs analyze, test, and
   an Android debug build on every pull request; all three must pass.
3. No secrets in the repository. Credentials come from `--dart-define`. There is
   a `git grep` check you should run before pushing:
   `git grep -nE "BEGIN PRIVATE KEY|AIza" -- lib` must be empty.
4. If a feature cannot be finished, document it honestly (see `FUTURE_WORK.md`)
   rather than shipping a stub that looks complete.

## Pull requests

- Branch off `main`, do not push to `main` directly.
- Keep the change focused and describe why, not only what.
- Make sure CI is green before asking for review.

## What will be declined

- Committing credentials, private keys, or generated build output.
- Making core editing require a network or an account. The move to on-device AI
  (ML Kit object detection, the on-device caption pipeline) was deliberate.
  Editing must keep working offline.
- Anything that breaks license compliance. The app links the full-GPL FFmpeg
  build through `ffmpeg_kit_flutter_new`, which is why the project is AGPL-3.0.
  Do not relicense to a permissive license while keeping GPL FFmpeg.
- A large feature with no test for its pure logic.
- Presenting a stub as a finished feature.
