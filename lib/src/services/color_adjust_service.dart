import 'dart:developer';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../utils/storage_path.dart';

/// Manual colour grading: brightness, contrast, saturation and warmth.
/// Command construction is pure/static for unit testing.
class ColorAdjustService {
  static String _n(double v) {
    var s = v.toStringAsFixed(3);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
    }
    return s.isEmpty ? '0' : s;
  }

  /// Builds the colour `-vf` chain.
  ///
  /// * [brightness] −1..1 (0 = unchanged)
  /// * [contrast]   0..2  (1 = unchanged)
  /// * [saturation] 0..3  (1 = unchanged)
  /// * [warmth]     −1..1 (0 = neutral; + = warmer, − = cooler)
  static String colorFilter({
    double brightness = 0.0,
    double contrast = 1.0,
    double saturation = 1.0,
    double warmth = 0.0,
  }) {
    final b = brightness.clamp(-1.0, 1.0);
    final c = contrast.clamp(0.0, 2.0);
    final s = saturation.clamp(0.0, 3.0);
    final w = warmth.clamp(-1.0, 1.0);
    final eq =
        'eq=brightness=${_n(b)}:contrast=${_n(c)}:saturation=${_n(s)}';
    if (w == 0) return eq;
    // Warmth: push red up / blue down (or the reverse when cooling).
    final rm = _n(0.3 * w);
    final bm = _n(-0.3 * w);
    return '$eq,colorbalance=rm=$rm:bm=$bm';
  }

  static String colorCommand(
    String input,
    String output, {
    double brightness = 0.0,
    double contrast = 1.0,
    double saturation = 1.0,
    double warmth = 0.0,
  }) {
    final vf = colorFilter(
      brightness: brightness,
      contrast: contrast,
      saturation: saturation,
      warmth: warmth,
    );
    return '-y -i $input -vf "$vf" '
        '-c:v libx264 -crf 20 -preset fast -c:a copy $output';
  }

  static Future<bool> _run(String command) async {
    log('ColorAdjustService command: $command');
    final session = await FFmpegKit.execute(command);
    final rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) return true;
    log('ColorAdjustService failed: ${await session.getOutput()}');
    return false;
  }

  static Future<String?> apply(
    String input, {
    double brightness = 0.0,
    double contrast = 1.0,
    double saturation = 1.0,
    double warmth = 0.0,
  }) async {
    final out = '${await getOutputDirectoryPath()}color_adjusted.mp4';
    return await _run(colorCommand(
      input,
      out,
      brightness: brightness,
      contrast: contrast,
      saturation: saturation,
      warmth: warmth,
    ))
        ? out
        : null;
  }
}
