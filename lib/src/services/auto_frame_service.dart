import 'dart:developer';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

import '../utils/storage_path.dart';
import 'advanced_edit_service.dart';

/// On-device "Auto Frame" (subject-follow reframe): detects the main subject
/// with ML Kit's on-device object detector and reframes the clip to a target
/// aspect ratio centered on that subject — the genuine, non-faked version of
/// the "motion tracking" idea, running entirely on the device (no cloud, no
/// credentials, and no FFmpeg conflict).
class AutoFrameService {
  // ---- Pure geometry helpers (unit tested) ---------------------------------

  /// Computes the largest crop rectangle of [targetAspect] (w/h) that fits in
  /// a [frameW] x [frameH] frame, centered on the subject at
  /// ([subjectCx], [subjectCy]) and clamped to stay inside the frame.
  /// Returns [x, y, w, h] with even width/height (required by libx264).
  static List<int> smartCropRect({
    required double subjectCx,
    required double subjectCy,
    required int frameW,
    required int frameH,
    required double targetAspect,
  }) {
    int cropH = frameH;
    int cropW = (cropH * targetAspect).round();
    if (cropW > frameW) {
      cropW = frameW;
      cropH = (cropW / targetAspect).round();
    }
    if (cropW > frameW) cropW = frameW;
    if (cropH > frameH) cropH = frameH;
    if (cropW.isOdd) cropW -= 1;
    if (cropH.isOdd) cropH -= 1;

    int x = (subjectCx - cropW / 2).round();
    int y = (subjectCy - cropH / 2).round();
    x = x.clamp(0, frameW - cropW);
    y = y.clamp(0, frameH - cropH);
    return [x, y, cropW, cropH];
  }

  /// FFmpeg command that crops to [rect] ([x,y,w,h]) then scales to [outH]
  /// tall (even width), keeping the audio.
  static String autoFrameCommand(
    String input,
    String output,
    List<int> rect, {
    int outH = 1280,
  }) {
    final x = rect[0], y = rect[1], w = rect[2], h = rect[3];
    return '-y -i $input -vf "crop=$w:$h:$x:$y,scale=-2:$outH" '
        '-c:v libx264 -crf 20 -preset fast -c:a copy $output';
  }

  // ---- On-device detection + reframe ---------------------------------------

  /// Detects the dominant subject in a representative frame and returns the
  /// crop rectangle to reframe around it. Null if no subject is found.
  static Future<List<int>?> detectSubjectRect(
    String videoPath,
    double durationSeconds,
    int frameW,
    int frameH,
    double targetAspect,
  ) async {
    if (frameW <= 0 || frameH <= 0) return null;
    final t = durationSeconds > 0 ? durationSeconds / 2 : 0.0;
    final framePath = await AdvancedEditService.grabFrame(videoPath, t);
    if (framePath == null) return null;

    final detector = ObjectDetector(
      options: ObjectDetectorOptions(
        mode: DetectionMode.single,
        classifyObjects: false,
        multipleObjects: true,
      ),
    );
    try {
      final objects =
          await detector.processImage(InputImage.fromFilePath(framePath));
      if (objects.isEmpty) return null;
      // The largest detected box is treated as the main subject.
      objects.sort((a, b) => (b.boundingBox.width * b.boundingBox.height)
          .compareTo(a.boundingBox.width * a.boundingBox.height));
      final box = objects.first.boundingBox;
      return smartCropRect(
        subjectCx: box.center.dx,
        subjectCy: box.center.dy,
        frameW: frameW,
        frameH: frameH,
        targetAspect: targetAspect,
      );
    } catch (e) {
      log("AutoFrameService.detectSubjectRect error: $e");
      return null;
    } finally {
      await detector.close();
      try {
        File(framePath).deleteSync();
      } catch (_) {}
    }
  }

  /// Full pipeline: detect the subject and render the reframed clip.
  static Future<String?> autoFrame(
    String videoPath,
    double durationSeconds,
    int frameW,
    int frameH, {
    double targetAspect = 9 / 16,
  }) async {
    final rect = await detectSubjectRect(
        videoPath, durationSeconds, frameW, frameH, targetAspect);
    if (rect == null) return null;
    final out = "${await getOutputDirectoryPath()}autoframe.mp4";
    final ok = await FFmpegKit.execute(autoFrameCommand(videoPath, out, rect))
        .then((s) async => ReturnCode.isSuccess(await s.getReturnCode()));
    return ok ? out : null;
  }
}
