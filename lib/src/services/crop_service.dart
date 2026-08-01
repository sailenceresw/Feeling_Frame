import 'dart:developer';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../utils/storage_path.dart';

/// Free crop to a rectangular region. Command construction is pure/static for
/// unit testing.
class CropService {
  static int _even(int v) => v < 2 ? 2 : (v.isOdd ? v - 1 : v);

  static String cropCommand(
    String input,
    String output, {
    required int rx,
    required int ry,
    required int rw,
    required int rh,
  }) {
    final w = _even(rw);
    final h = _even(rh);
    return '-y -i $input -vf "crop=$w:$h:$rx:$ry" '
        '-c:v libx264 -crf 20 -preset fast -c:a copy $output';
  }

  static Future<bool> _run(String command) async {
    log('CropService command: $command');
    final session = await FFmpegKit.execute(command);
    final rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) return true;
    log('CropService failed: ${await session.getOutput()}');
    return false;
  }

  static Future<String?> crop(
    String input, {
    required int rx,
    required int ry,
    required int rw,
    required int rh,
  }) async {
    final out = '${await getOutputDirectoryPath()}cropped.mp4';
    return await _run(cropCommand(input, out, rx: rx, ry: ry, rw: rw, rh: rh))
        ? out
        : null;
  }
}
