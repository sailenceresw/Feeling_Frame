# Feeling_Frame

A Flutter video editor mobile app that runs on **both Android and iOS**. It
supports trimming, cropping, rotation, **flip (horizontal/vertical) and
reverse** transforms, filters (Sepia, High Saturation, Grayscale, Warm, Cool,
Vintage, Invert), color adjustments, playback speed, **volume control**, text
overlays (with adjustable font size and color), aspect-ratio changes, audio
replacement, cover selection, multi-video merging, **export with a live
progress indicator**, a persistent **Recent Projects** list, and optional AI
features (object detection and speech transcription) powered by Google Cloud
Video Intelligence.

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
