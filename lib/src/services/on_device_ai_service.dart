import 'dart:developer';
import 'dart:io';

import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

import 'advanced_edit_service.dart';

/// On-device object/label detection — a self-contained replacement for the
/// Google Cloud Video Intelligence object tracking. It runs entirely on the
/// device via ML Kit's bundled model: no cloud account, no credentials, no
/// upload of the user's video.
///
/// A custom model (e.g. trained on a Kaggle dataset and exported to TFLite)
/// can be dropped in later via `LocalLabelerOptions(modelPath: ...)`.
class OnDeviceAiService {
  /// Samples [frameCount] frames evenly across a [durationSeconds]-long video,
  /// runs on-device image labeling on each, and returns the distinct labels
  /// ordered by confidence (highest first).
  static Future<List<String>> detectLabels(
    String videoPath,
    double durationSeconds, {
    int frameCount = 6,
    double confidenceThreshold = 0.6,
  }) async {
    final labeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: confidenceThreshold),
    );

    // Best confidence seen per label, so we can rank and dedupe.
    final best = <String, double>{};
    final tempFrames = <String>[];

    try {
      final duration = durationSeconds <= 0 ? 1.0 : durationSeconds;
      for (var i = 0; i < frameCount; i++) {
        // Spread samples across the middle of the clip (avoid the very edges).
        final t = duration * (i + 1) / (frameCount + 1);
        final framePath = await AdvancedEditService.grabFrame(videoPath, t);
        if (framePath == null) continue;
        tempFrames.add(framePath);

        final input = InputImage.fromFilePath(framePath);
        final labels = await labeler.processImage(input);
        for (final label in labels) {
          final name = label.label;
          if (!best.containsKey(name) || label.confidence > best[name]!) {
            best[name] = label.confidence;
          }
        }
      }
    } catch (e) {
      log("OnDeviceAiService.detectLabels error: $e");
    } finally {
      await labeler.close();
      for (final f in tempFrames) {
        try {
          File(f).deleteSync();
        } catch (_) {}
      }
    }

    final sorted = best.keys.toList()
      ..sort((a, b) => best[b]!.compareTo(best[a]!));
    return sorted;
  }
}
