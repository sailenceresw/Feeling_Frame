# Architecture

This describes how feelm is put together so you can find your way around the
code. The app is a single Flutter codebase targeting Android and iOS. Video
work is done with FFmpeg on the device; the AI features run on-device where
possible.

## Table of contents

- [Stack](#stack)
- [App flow](#app-flow)
- [Directory layout](#directory-layout)
- [The service pattern](#the-service-pattern)
- [Feature inventory](#feature-inventory)
- [AI features](#ai-features)
- [Data and storage](#data-and-storage)
- [Platform and dependency notes](#platform-and-dependency-notes)
- [Testing](#testing)

## Stack

- Flutter and Dart. Verified on Flutter 3.44.8, Dart in the range
  `>=3.2.6 <4.0.0`.
- State management: GetX (`get`). Controllers are singletons.
- Video processing: FFmpeg through `ffmpeg_kit_flutter_new`, the maintained
  fork of FFmpegKit. It links the full-GPL FFmpeg build, which is why the
  project is licensed AGPL-3.0.
- Trim and crop UI: the `video_editor` package.
- On-device vision: `google_mlkit_image_labeling` and
  `google_mlkit_object_detection`.
- Media I/O: `video_player`, `image_picker`, `file_picker`, `gal` (gallery
  save), `share_plus`, `path_provider`.
- Overlays: `lindi_sticker_widget` for draggable text and stickers.

## App flow

Entry is `lib/main.dart`, which calls `diInit()` in `lib/di_init.dart` to
register the GetX controllers, then runs the app. The first-run sequence is:

1. Intro animation (branded, `screens/splash` and the intro widget).
2. Splash screen.
3. Login (`screens/login`). See the note in the README: the login is a
   hardcoded demo, tracked in issue #31.
4. Project dashboard (`screens/project/project_screen.dart`).
5. Editor (`screens/editor/custom_video_editor.dart`) once a clip is picked,
   with each tool opening its own screen.

`di_init.dart` registers `LoginController`, `ProjectController`,
`SettingsController`, `AiVideoController`, and `EditorController`. They are read
anywhere as `SomeController.instance`.

## Directory layout

```
lib/
  main.dart                 app entry, theme, first-frame setup
  di_init.dart              GetX singleton registration
  src/
    constant/               theme, colors, dimensions, asset paths
    controllers/            GetX controllers (login, project, settings, ai, editor)
    models/                 plain data models (project_model.dart)
    screens/
      splash/ login/ project/ settings/ premium/ help/ legal/
      ai/                   AI mode and object detection screens
      editor/               the editor and one screen per tool
    services/               one service per editing capability (FFmpeg + logic)
    utils/                  srt_builder, storage_path, app_translations, diagnostics
    widgets/                shared widgets (text, textfield, dialogs, toast)
test/                       one test file per service, plus model and smoke tests
```

## The service pattern

Every editing capability is a service under `lib/src/services/`. Services follow
one shape on purpose:

- Pure static functions build the FFmpeg command string from parameters. They
  do no I/O, so they can be unit tested without a device or real media.
- A thin runner executes the command and returns the output path.

`advanced_edit_service.dart` is the clearest example, and
`test/advanced_edit_service_test.dart` tests its command builders directly.
This is why the test suite can cover video features without decoding video: the
tests assert on the command strings, and the runtime run is verified on a
device (see the validation issues in the roadmap).

## Feature inventory

Each editor tool is a screen in `lib/src/screens/editor/` backed by a service
in `lib/src/services/`. Grouped by what they do:

- Trim, crop, rotate, speed: `crop_screen`, `crop_region_screen`,
  `rotate_screen`, `speed_screen`, `loop_screen`, `fade_screen`.
- Composition: `merge_screen`, `pip_screen`, `split_screen_screen`,
  `slideshow_screen`, `transition_screen`.
- Look and effects: `color_adjust_screen`, `vfx_screen`, `border_screen`,
  `blur_region_screen`, `watermark_screen`, plus the filter presets in
  `filter_service.dart`.
- Text and graphics: `text_screen`, `caption_studio_screen`,
  `thumbnail_designer_screen`, `meme_screen`, `gif_studio_screen`.
- Audio: `volume_screen`, `audio_cleanup_screen`.
- Export: `compress_screen`, `export_preset_screen`, and the export path inside
  `custom_video_editor.dart` (resolution and quality selection, watermark for
  free users, overlay burn-in).
- Keyframe style animation: `keyframe_screen` (a Ken Burns style zoom today; a
  full timeline is future work).

The main editor `custom_video_editor.dart` hosts the timeline, preview, and the
export flow, and launches the tool screens above.

## AI features

Reached from the editor's AI mode (`screens/ai/ai_screen.dart`).

On-device, no account or network:

- Object detection: `on_device_ai_service.dart` samples frames and labels them
  with ML Kit. Shown in `object_detect_screen.dart`.
- Noise reduction, stabilization (vid.stab), and auto-highlights (scene
  detection): `ai_video_service.dart`.
- Auto Frame: `auto_frame_service.dart` reframes toward a detected subject.
- Captions: `caption_service.dart` and `stt_service.dart`. The caption pipeline
  extracts 16 kHz mono WAV, decodes it, and groups timed tokens into cues.
  Typing, pasting, and importing SRT work today. Auto-generation needs a
  concrete `SpeechRecognizer` and model, which is not bundled yet (issue #36).

Optional cloud:

- Google Cloud speech transcription can be enabled by passing a service account
  at build time with `--dart-define=GCP_SERVICE_ACCOUNT_JSON`. Nothing is
  bundled, and the app works without it.

## Data and storage

- Projects: `project_controller.dart` persists a list of projects to a JSON file
  in the app documents directory via `path_provider`. `project_model.dart` is
  the row.
- Settings: `settings_controller.dart` persists theme, text scale, language, and
  the premium flag to JSON.
- Feedback: `widgets/feedback_dialog.dart` stores rating and message locally.
- Output files: `utils/storage_path.dart` writes to the public Download folder
  on Android (with an app-storage fallback) and to the documents directory on
  iOS.

Premium today is the local flag in `settings_controller.dart`. It gates only the
export watermark and is not backed by a store purchase (issue #37).

## Platform and dependency notes

- Android: `minSdkVersion 24`, `compileSdkVersion 34`.
- iOS: deployment target 15.5, required by the ML Kit pods.
- `pubspec.yaml` has two `dependency_overrides` with comments explaining why:
  `win32` (a transitive dependency used a symbol removed in newer Dart) and
  `flutter_plugin_android_lifecycle` (an old transitive version used the removed
  v1 Android embedding). Both are needed to build on current Flutter.
- Web is not a supported target. The code compiles for web, but FFmpeg and ML
  Kit have no web implementation, and the video-pick flow returns bytes rather
  than a path, so editing does not function there.

## Testing

`flutter test` runs 205 tests. The suite is one file per service plus the model
and a screens smoke test. Because the FFmpeg services expose pure command
builders, the tests assert on the exact command strings, which is fast and
needs no device. What the tests do not cover is the runtime behaviour of those
commands on real media; that is on-device validation, tracked in the roadmap.
