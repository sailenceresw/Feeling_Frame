import 'dart:developer';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../utils/storage_path.dart';

/// Adds a border/frame around the video — a solid colour or a blurred extension
/// of the video itself. Command construction is pure/static for unit testing.
class BorderService {
  /// FFmpeg colour names offered in the UI.
  static const List<String> colors = [
    'white',
    'black',
    'red',
    'yellow',
    'cyan',
    'pink',
  ];

  /// Solid-colour border of [border] px on all sides via `pad`.
  static String coloredFilter(int border, String color) {
    final b = border < 0 ? 0 : border;
    return 'pad=iw+${2 * b}:ih+${2 * b}:$b:$b:$color';
  }

  /// Blurred border: a blurred, enlarged copy of the video behind the original.
  static String blurredFilter(int border) {
    final b = border < 0 ? 0 : border;
    return '[0:v]scale=iw+${2 * b}:ih+${2 * b},boxblur=20:5[bg];'
        '[bg][0:v]overlay=$b:$b[v]';
  }

  static String borderCommand(
    String input,
    String output, {
    int border = 40,
    String color = 'white',
    bool blurred = false,
  }) {
    if (blurred) {
      return '-y -i $input -filter_complex "${blurredFilter(border)}" '
          '-map "[v]" -map 0:a? -c:v libx264 -crf 20 -preset fast -c:a copy '
          '$output';
    }
    return '-y -i $input -vf "${coloredFilter(border, color)}" '
        '-c:v libx264 -crf 20 -preset fast -c:a copy $output';
  }

  static Future<bool> _run(String command) async {
    log('BorderService command: $command');
    final session = await FFmpegKit.execute(command);
    final rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) return true;
    log('BorderService failed: ${await session.getOutput()}');
    return false;
  }

  static Future<String?> apply(
    String input, {
    int border = 40,
    String color = 'white',
    bool blurred = false,
  }) async {
    final out = '${await getOutputDirectoryPath()}bordered.mp4';
    return await _run(borderCommand(input, out,
            border: border, color: color, blurred: blurred))
        ? out
        : null;
  }
}
