# Security Policy

feelm is a client-only Flutter mobile app. There is no first-party backend, so
most classic web vulnerabilities do not apply. The security surface that does
matter here is on-device: how credentials are handled, how FFmpeg commands are
built from user-controlled paths, and what is written to local storage.

## Reporting a vulnerability

Please do not open a public issue for a security problem.

1. Preferred: use GitHub private vulnerability reporting on this repository
   (the "Report a vulnerability" button under the Security tab). This keeps the
   report private to the maintainer.
2. If private reporting is not enabled, reach the maintainer through their
   GitHub profile at https://github.com/sailenceresw and ask for a private
   channel before sending any details.

Expect an acknowledgement within about a week. This is a solo, non-commercial
project, so response times are best effort.

## Supported versions

Only the current `main` branch is supported. There are no released versions or
backported fixes yet (the app has not shipped to a store).

## Scope, ranked by what actually matters here

1. Credential handling for the optional Google Cloud transcription path.
   Credentials are passed at build time with
   `--dart-define=GCP_SERVICE_ACCOUNT_JSON` and must never be committed. A key
   accidentally baked into a build or the repo is the highest-value target.
2. FFmpeg command construction. Services under `lib/src/services/` build FFmpeg
   argument strings that include user-chosen file paths (for example
   `advanced_edit_service.dart`, `ai_video_service.dart`,
   `watermark_service.dart`). A path or caption text containing quotes, spaces,
   or filter-graph metacharacters could break or alter a command. Reports that
   show a crafted filename or caption changing the executed command are in
   scope.
3. Local data at rest. Projects, settings, and feedback are stored as plain
   JSON in the app documents directory (`project_controller.dart`,
   `settings_controller.dart`, `feedback_dialog.dart`). Exported media lands in
   Download (Android) or the documents directory (iOS). Reports about sensitive
   data written world-readable, or leaking between apps, are in scope.
4. Runtime permissions. Over-broad or unexpected permission use via
   `permission_handler`, `image_picker`, `gal`, or `share_plus`.

## Already known, please do not report these

These are tracked and intentional for the current pre-release state:

- The login screen accepts hardcoded demo credentials
  (`lib/src/controllers/login_controller.dart`). There is no real
  authentication yet. Tracked in issue #31.
- A Google Cloud service-account key was committed in early history and later
  removed from the working tree. Rotating that key is tracked in issue #34;
  removing it from `HEAD` does not remove it from history.
- Premium is a client-side boolean with no store verification, so the export
  watermark gate is bypassable on a rooted or modified device. Tracked in
  issue #37.
- There is no per-user data isolation, since there is no real user identity.

## Out of scope

- Denial of service by feeding pathologically large media to FFmpeg.
- Physical access to an unlocked device.
- Findings that require a modified or rooted OS to reach data the owner already
  controls.
