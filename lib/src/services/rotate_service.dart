import 'dart:developer';
import 'dart:math' as math;

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../utils/storage_path.dart';

/// Rotate by quarter turns and straighten a tilted horizon (with an auto zoom
/// so no black corners appear). Command construction is pure/static for tests.
class RotateService {
  static String _n(double v) {
    var s = v.toStringAsFixed(4);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
    }
    return s.isEmpty ? '0' : s;
  }

  /// 90°/180°/270° rotation via `transpose`. [quarterTurns] is 1 (90° CW),
  /// 2 (180°) or 3 (90° CCW); anything else is a no-op copy.
  static String rotateQuarterCommand(
    String input,
    String output,
    int quarterTurns,
  ) {
    final t = ((quarterTurns % 4) + 4) % 4;
    final String vf;
    switch (t) {
      case 1:
        vf = '-vf transpose=1';
        break;
      case 2:
        vf = '-vf transpose=1,transpose=1';
        break;
      case 3:
        vf = '-vf transpose=2';
        break;
      default:
        return '-y -i $input -c copy $output';
    }
    return '-y -i $input $vf -c:v libx264 -crf 20 -preset fast -c:a copy '
        '$output';
  }

  /// Minimum uniform up-scale so a [w]x[h] frame rotated by [degrees] still
  /// covers the whole frame (no black corners): cos(a) + max(w/h,h/w)·sin(|a|).
  static double straightenScale(int w, int h, double degrees) {
    if (w <= 0 || h <= 0) return 1.0;
    final a = degrees.abs() * math.pi / 180.0;
    final aspectMax = math.max(w / h, h / w);
    return math.cos(a) + aspectMax * math.sin(a);
  }

  /// The `-vf` chain that straightens by [degrees]: scale up, rotate, crop back.
  static String straightenFilter(int w, int h, double degrees) {
    final s = straightenScale(w, h, degrees);
    final rad = degrees * math.pi / 180.0;
    return 'scale=iw*${_n(s)}:ih*${_n(s)},'
        'rotate=${_n(rad)}:ow=iw:oh=ih,crop=$w:$h';
  }

  static String straightenCommand(
    String input,
    String output, {
    required int w,
    required int h,
    required double degrees,
  }) {
    return '-y -i $input -vf "${straightenFilter(w, h, degrees)}" '
        '-c:v libx264 -crf 20 -preset fast -c:a copy $output';
  }

  static Future<bool> _run(String command) async {
    log('RotateService command: $command');
    final session = await FFmpegKit.execute(command);
    final rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) return true;
    log('RotateService failed: ${await session.getOutput()}');
    return false;
  }

  static Future<String?> rotateQuarter(String input, int quarterTurns) async {
    final out = '${await getOutputDirectoryPath()}rotated.mp4';
    return await _run(rotateQuarterCommand(input, out, quarterTurns))
        ? out
        : null;
  }

  static Future<String?> straighten(
    String input, {
    required int w,
    required int h,
    required double degrees,
  }) async {
    final out = '${await getOutputDirectoryPath()}straightened.mp4';
    return await _run(straightenCommand(input, out, w: w, h: h, degrees: degrees))
        ? out
        : null;
  }
}
