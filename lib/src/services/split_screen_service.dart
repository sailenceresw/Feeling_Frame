import 'dart:developer';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../utils/storage_path.dart';

/// Combines two clips into a split screen — side by side or stacked.
/// Command construction is pure/static for unit testing.
class SplitScreenService {
  static int _even(int v) => v.isOdd ? v - 1 : (v < 2 ? 2 : v);

  /// Builds the split-screen filter_complex for output [w]x[h]. When
  /// [horizontal] the clips sit left/right (each w/2 wide); otherwise top/bottom
  /// (each h/2 tall). Audio from both is mixed.
  static String splitFilter(
    int w,
    int h, {
    bool horizontal = true,
    bool withAudio = true,
  }) {
    final String l, r, stack;
    if (horizontal) {
      final half = _even(w ~/ 2);
      final cell = 'scale=$half:$h:force_original_aspect_ratio=increase,'
          'crop=$half:$h,setsar=1';
      l = '[0:v]$cell[l]';
      r = '[1:v]$cell[r]';
      stack = '[l][r]hstack=inputs=2[v]';
    } else {
      final half = _even(h ~/ 2);
      final cell = 'scale=$w:$half:force_original_aspect_ratio=increase,'
          'crop=$w:$half,setsar=1';
      l = '[0:v]$cell[l]';
      r = '[1:v]$cell[r]';
      stack = '[l][r]vstack=inputs=2[v]';
    }
    final base = '$l;$r;$stack';
    if (!withAudio) return base;
    return '$base;[0:a][1:a]amix=inputs=2:duration=shortest[a]';
  }

  static String splitCommand(
    String a,
    String b,
    String output, {
    required int w,
    required int h,
    bool horizontal = true,
    bool withAudio = true,
  }) {
    final filter =
        splitFilter(w, h, horizontal: horizontal, withAudio: withAudio);
    final maps = withAudio ? '-map "[v]" -map "[a]"' : '-map "[v]"';
    return '-y -i $a -i $b -filter_complex "$filter" $maps '
        '-c:v libx264 -crf 20 -preset fast -shortest $output';
  }

  static Future<bool> _run(String command) async {
    log('SplitScreenService command: $command');
    final session = await FFmpegKit.execute(command);
    final rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) return true;
    log('SplitScreenService failed: ${await session.getOutput()}');
    return false;
  }

  static Future<String?> combine(
    String a,
    String b, {
    required int w,
    required int h,
    bool horizontal = true,
  }) async {
    final out = '${await getOutputDirectoryPath()}split.mp4';
    if (await _run(splitCommand(a, b, out,
        w: w, h: h, horizontal: horizontal))) {
      return out;
    }
    if (await _run(splitCommand(a, b, out,
        w: w, h: h, horizontal: horizontal, withAudio: false))) {
      return out;
    }
    return null;
  }
}
