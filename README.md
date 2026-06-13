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
persistent **Recent Projects** list, and optional AI
features (object detection and speech transcription) powered by Google Cloud
Video Intelligence.

## Project theme: AI-automated video editing

This app is the artefact for the proposal *"Automated Video Editing Mobile
Application Using AI"*. Feature ↔ proposal mapping:

| Proposal theme | Implementation |
| --- | --- |
| Cross-platform Flutter app (Android + iOS) | Single codebase, both platforms configured |
| Speech identification | Google Cloud Video Intelligence speech transcription |
| Caption production | Word-level timings → auto-generated SRT, burned into the video |
| Noise reduction | On-device FFmpeg FFT denoiser + high-pass filter (offline) |
| Video stabilization | On-device two-pass vid.stab pipeline (offline) |
| FFmpeg-automated compression | Export resolution/quality settings (CRF + downscale) |
| "Keep the crucial sections" | Auto Highlights: scene detection keeps key moments (offline) |
| Object recognition | Google Cloud Video Intelligence object tracking |
| Instructional materials | In-app "How to use" guide |
| In-app capture (report feature 2) | Record videos with the camera from "New Project" |
| Green screen editing (Phase Two) | Chroma-key background replacement in the editor |
| Feedback loops (report methodology) | In-app feedback panel (rating + message, stored locally) |

Phase Two items from the report that remain future work: keyframe animation,
masking tools, cloud collaboration/version control, motion tracking, audio
waveform visualization, and 3D effects.

## Requirements

- Flutter SDK `>=3.2.6 <4.0.0`
- Android: `minSdkVersion 24`, `compileSdkVersion 34`
- iOS: deployment target `13.0+`

## Getting started

```bash
flutter pub get

# Android
flutter run

# iOS
cd ios && pod install && cd ..
flutter run
```

## Login credentials

```
Email    : test@gmail.com
Password : 123456
```

## AI features (optional)

The Google Cloud service-account credentials are **no longer hardcoded** in the
source. To enable the AI object-detection and transcription features, pass the
service-account JSON at build/run time with a `--dart-define`:

```bash
flutter run --dart-define=GCP_SERVICE_ACCOUNT_JSON="$(cat service_account.json)"
```

If the credentials are not provided, the rest of the app works normally and the
AI screens show a clear "not configured" message instead of failing silently.

> Never commit credentials or private keys to the repository.

## Exported files

- **Android:** processed videos are written to the public `Download` folder
  (falling back to app storage if unavailable).
- **iOS:** processed videos are written to the app's documents directory and are
  accessible through the Files app (file sharing is enabled).
</content>
