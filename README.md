# Feeling_Frame

A Flutter video editor mobile app that runs on **both Android and iOS**. It
supports trimming, cropping, rotation, **flip (horizontal/vertical) and
reverse** transforms, filters (Sepia, High Saturation, Grayscale, Warm, Cool,
Vintage, Invert), color adjustments, playback speed, **volume control**, text
overlays (with adjustable font size and color) that are **burned into the
exported video**, **image sticker overlays**, aspect-ratio changes, audio
replacement, cover selection, multi-video merging, editing of clips up to
**10 minutes**, **export with a live progress indicator and selectable
resolution/quality** (downscale HD/2K/4K/8K sources to 1440p/1080p/720p/480p
with high/balanced/small-size compression to dramatically reduce file size), a
persistent **Recent Projects** list, and AI features that primarily run
**on-device** (ML Kit object labeling, FFmpeg-based auto-edit pipelines).

## Project theme: AI-automated video editing

This app is the artefact for the proposal *"Automated Video Editing Mobile
Application Using AI"*. Feature ↔ proposal mapping:

| Proposal theme | Implementation |
| --- | --- |
| Cross-platform Flutter app (Android + iOS) | Single codebase, both platforms configured |
| Speech identification | On-device STT pipeline (interface ready; model bundling tracked in issues) + optional Google Cloud path |
| Caption production | Word-level timings → auto-generated SRT, burned into the video (typed/paste/SRT import fully work) |
| Noise reduction | On-device FFmpeg FFT denoiser + high-pass filter (offline) |
| Video stabilization | On-device two-pass vid.stab pipeline (offline) |
| FFmpeg-automated compression | Export resolution/quality settings (CRF + downscale) |
| "Keep the crucial sections" | Auto Highlights: scene detection keeps key moments (offline) |
| Object recognition | **On-device** ML Kit image labeling (no cloud/credentials required) |
| Instructional materials | In-app "How to use" guide |
| In-app capture (report feature 2) | Record videos with the camera from "New Project" |
| Green screen editing (Phase Two) | Chroma-key background replacement in the editor |
| Feedback loops (report methodology) | In-app feedback panel (rating + message, stored locally) |
| Audio waveform visualization | Waveform image rendered in the editor's Audio tab |
| Unit testing (report methodology) | `flutter test` suite for SRT building and project persistence |
| Accessibility (WCAG) | Settings: high-contrast theme + app-wide text-size scaling |
| Localization / globalization | 5 languages (EN/ES/HI/NE/FR) via a settings language picker |
| AI integration refinement | Selectable transcription language (8 locales) |
| Monetization | Premium screen with plans; free exports get a watermark, premium removes it (local unlock for now) |
| Security & privacy | No bundled credentials; explicit-consent optional cloud features; in-app privacy policy |
| Continuous user feedback | In-app feedback panel (rating + message) |

The editor also includes a CapCut-style "Blur Pad 9:16" transform that fits
any clip into a vertical frame over a blurred copy of itself, plus
**Boomerang** and **Fade In/Out** transforms, **Keyframe Animation** (zoom/pan),
and multi-format export: **video, animated GIF, extracted audio (MP3)**, and cover image.

### Later work

Remaining tasks — both the SDK-dependent steps to run locally and the larger
deferred features (cloud collaboration/version control, motion tracking, full
keyframe timeline, real IAP, LSTM training) — are tracked in
[`FUTURE_WORK.md`](FUTURE_WORK.md) and the open GitHub issues.

## Branding

The app is **feelm** (published under the *feeling frame* brand). It opens
with a publisher-style **intro animation** showing the *feeling frame — edit
with emotion* company logo (scale-in + heartbeat pulse, cross-fading from
white into the dark app), followed by the **feelm** splash screen.

The launcher icon is generated from `assets/images/app_logo.png`. After
`flutter pub get`, run it once:

```bash
dart run flutter_launcher_icons
```

## Requirements

- Flutter SDK `>=3.2.6 <4.0.0` (verified building/testing on Flutter 3.44.8)
- Android: `minSdkVersion 24`, `compileSdkVersion 34`
- iOS: deployment target `15.5+` (required by the on-device ML Kit object
  detection; already configured in the Podfile/project). Android works at the
  current minSdk 24.

## Getting started

```bash
flutter pub get

# Android
flutter run

# iOS
cd ios && pod install && cd ..
flutter run
```

## Demo entry

The app opens in **demo / offline mode**. There is no real authentication.
Tap **Continue (demo)** on the start screen to enter the project list and editor.
All projects, premium state, and feedback are stored locally on the device.

## AI features

- **Object detection / labeling**: fully on-device via Google ML Kit. No
  credentials or network required.
- **Captions**: typed, pasted, or imported SRT work today and are burned into
  the export. Auto-generate from speech uses an on-device `SpeechRecognizer`
  interface; a concrete model (e.g. sherpa-onnx) is still to be bundled
  (see open issues).
- **Optional cloud transcription**: the Google Cloud Video Intelligence path
  remains available if you pass a service-account JSON at build/run time:

```bash
flutter run --dart-define=GCP_SERVICE_ACCOUNT_JSON="$(cat service_account.json)"
```

If the credentials are not provided, the rest of the app works normally.

> Never commit credentials or private keys to the repository.

## Exported files

- **Android:** processed videos are written to the public `Download` folder
  (falling back to app storage if unavailable).
- **iOS:** processed videos are written to the app's documents directory and are
  accessible through the Files app (file sharing is enabled).
