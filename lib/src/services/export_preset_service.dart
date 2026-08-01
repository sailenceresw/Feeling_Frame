import 'dart:developer';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../utils/storage_path.dart';

/// A social-platform export target.
class ExportPreset {
  const ExportPreset(this.name, this.width, this.height, this.ratio);

  final String name;
  final int width;
  final int height;
  final String ratio;
}

/// How to fit a clip of a different aspect into the target frame.
enum ExportFit {
  /// Crop to completely fill the frame (no bars).
  fill,

  /// Scale to fit and pad the remainder with a blurred copy of the video.
  blur,

  /// Scale to fit and pad the remainder with black bars.
  bars,
}

/// Re-encodes a clip to the exact size social platforms expect, with a choice
/// of fit mode. Command construction is pure/static for unit testing.
class ExportPresetService {
  static const List<ExportPreset> presets = [
    ExportPreset('TikTok / Reels / Shorts', 1080, 1920, '9:16'),
    ExportPreset('YouTube', 1920, 1080, '16:9'),
    ExportPreset('Instagram Post', 1080, 1080, '1:1'),
    ExportPreset('Instagram Portrait', 1080, 1350, '4:5'),
    ExportPreset('Widescreen HD', 1280, 720, '16:9'),
  ];

  static String fitLabel(ExportFit fit) {
    switch (fit) {
      case ExportFit.fill:
        return 'Fill (crop)';
      case ExportFit.blur:
        return 'Fit (blurred bars)';
      case ExportFit.bars:
        return 'Fit (black bars)';
    }
  }

  /// Builds the FFmpeg command that re-encodes [input] to [w]x[h] using [fit].
  static String exportCommand(
    String input,
    String output, {
    required int w,
    required int h,
    ExportFit fit = ExportFit.fill,
  }) {
    switch (fit) {
      case ExportFit.fill:
        return '-y -i $input '
            '-vf "scale=$w:$h:force_original_aspect_ratio=increase,crop=$w:$h" '
            '-c:v libx264 -crf 20 -preset fast -c:a aac $output';
      case ExportFit.bars:
        return '-y -i $input '
            '-vf "scale=$w:$h:force_original_aspect_ratio=decrease,'
            'pad=$w:$h:(ow-iw)/2:(oh-ih)/2:black" '
            '-c:v libx264 -crf 20 -preset fast -c:a aac $output';
      case ExportFit.blur:
        return '-y -i $input -filter_complex '
            '"[0:v]scale=$w:$h:force_original_aspect_ratio=increase,'
            'crop=$w:$h,boxblur=20:5[bg];'
            '[0:v]scale=$w:$h:force_original_aspect_ratio=decrease[fg];'
            '[bg][fg]overlay=(W-w)/2:(H-h)/2[v]" '
            '-map "[v]" -map 0:a? -c:v libx264 -crf 20 -preset fast '
            '-c:a aac $output';
    }
  }

  static Future<bool> _run(String command) async {
    log('ExportPresetService command: $command');
    final session = await FFmpegKit.execute(command);
    final rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) return true;
    log('ExportPresetService failed: ${await session.getOutput()}');
    return false;
  }

  /// Exports [input] to [preset]'s dimensions with [fit]. Returns the output
  /// path (or null).
  static Future<String?> export(
    String input,
    ExportPreset preset, {
    ExportFit fit = ExportFit.fill,
  }) async {
    final safeName =
        preset.ratio.replaceAll(':', 'x'); // e.g. 9x16 for the filename
    final out = '${await getOutputDirectoryPath()}export_$safeName.mp4';
    return await _run(exportCommand(
      input,
      out,
      w: preset.width,
      h: preset.height,
      fit: fit,
    ))
        ? out
        : null;
  }
}
