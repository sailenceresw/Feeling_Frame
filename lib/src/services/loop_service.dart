import 'dart:developer';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../utils/storage_path.dart';

/// Repeat a clip N times, or make a forward-then-reverse ("ping-pong") loop.
/// Command construction is pure/static for unit testing.
class LoopService {
  /// Repeats the whole clip [times] times (>= 2) via stream-copy (fast).
  static String loopCommand(String input, String output, int times) {
    final t = times < 1 ? 1 : times;
    return '-y -stream_loop ${t - 1} -i $input -c copy $output';
  }

  /// Plays the clip forward then reversed and concatenates (video only, like a
  /// seamless ping-pong loop).
  static String pingpongCommand(String input, String output) {
    return '-y -i $input -filter_complex '
        '"[0:v]reverse[r];[0:v][r]concat=n=2:v=1[v]" '
        '-map "[v]" -c:v libx264 -crf 20 -preset fast -an $output';
  }

  static Future<bool> _run(String command) async {
    log('LoopService command: $command');
    final session = await FFmpegKit.execute(command);
    final rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) return true;
    log('LoopService failed: ${await session.getOutput()}');
    return false;
  }

  static Future<String?> loop(String input, int times) async {
    final out = '${await getOutputDirectoryPath()}looped.mp4';
    return await _run(loopCommand(input, out, times)) ? out : null;
  }

  static Future<String?> pingpong(String input) async {
    final out = '${await getOutputDirectoryPath()}pingpong.mp4';
    return await _run(pingpongCommand(input, out)) ? out : null;
  }
}
