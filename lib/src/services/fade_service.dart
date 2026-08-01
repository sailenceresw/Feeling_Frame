import 'dart:developer';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../utils/storage_path.dart';

/// Fades the clip in from black at the start and/or out to black at the end
/// (video + audio). Command construction is pure/static for unit testing.
class FadeService {
  static String _n(double v) {
    var s = v.toStringAsFixed(3);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
    }
    return s.isEmpty ? '0' : s;
  }

  /// Video fade chain (empty if neither end is faded).
  static String videoFade(
    double totalSeconds,
    double fadeSeconds, {
    bool fadeIn = true,
    bool fadeOut = true,
  }) {
    final parts = <String>[];
    if (fadeIn) parts.add('fade=t=in:st=0:d=${_n(fadeSeconds)}');
    if (fadeOut) {
      final start = (totalSeconds - fadeSeconds).clamp(0.0, double.maxFinite);
      parts.add('fade=t=out:st=${_n(start)}:d=${_n(fadeSeconds)}');
    }
    return parts.join(',');
  }

  static String audioFade(
    double totalSeconds,
    double fadeSeconds, {
    bool fadeIn = true,
    bool fadeOut = true,
  }) {
    final parts = <String>[];
    if (fadeIn) parts.add('afade=t=in:st=0:d=${_n(fadeSeconds)}');
    if (fadeOut) {
      final start = (totalSeconds - fadeSeconds).clamp(0.0, double.maxFinite);
      parts.add('afade=t=out:st=${_n(start)}:d=${_n(fadeSeconds)}');
    }
    return parts.join(',');
  }

  static String fadeCommand(
    String input,
    String output, {
    required double totalSeconds,
    double fadeSeconds = 1.0,
    bool fadeIn = true,
    bool fadeOut = true,
  }) {
    final vf = videoFade(totalSeconds, fadeSeconds,
        fadeIn: fadeIn, fadeOut: fadeOut);
    final af = audioFade(totalSeconds, fadeSeconds,
        fadeIn: fadeIn, fadeOut: fadeOut);
    return '-y -i $input -vf "$vf" -af "$af" '
        '-c:v libx264 -crf 20 -preset fast -c:a aac $output';
  }

  static Future<bool> _run(String command) async {
    log('FadeService command: $command');
    final session = await FFmpegKit.execute(command);
    final rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) return true;
    log('FadeService failed: ${await session.getOutput()}');
    return false;
  }

  static Future<String?> apply(
    String input, {
    required double totalSeconds,
    double fadeSeconds = 1.0,
    bool fadeIn = true,
    bool fadeOut = true,
  }) async {
    if (!fadeIn && !fadeOut) return null;
    final out = '${await getOutputDirectoryPath()}faded_intro.mp4';
    return await _run(fadeCommand(input, out,
            totalSeconds: totalSeconds,
            fadeSeconds: fadeSeconds,
            fadeIn: fadeIn,
            fadeOut: fadeOut))
        ? out
        : null;
  }
}
