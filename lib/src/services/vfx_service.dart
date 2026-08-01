import 'dart:developer';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../utils/storage_path.dart';

/// Cinematic look: a darkened-edge vignette and subtle film grain.
/// Command construction is pure/static for unit testing.
class VfxService {
  static String _n(double v) {
    var s = v.toStringAsFixed(3);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
    }
    return s.isEmpty ? '0' : s;
  }

  /// Builds the `-vf` chain. [vignette] 0..1 controls edge darkening (0 = off);
  /// [grain] 0..100 is the noise strength (0 = off). With both 0 the chain is
  /// a passthrough `null` filter.
  static String vfxFilter({double vignette = 0.5, int grain = 8}) {
    final parts = <String>[];
    if (vignette > 0) {
      // vignette angle: larger angle = stronger darkening. Map 0..1 -> ~PI/6..PI/3.
      final v = vignette.clamp(0.0, 1.0);
      final angle = 0.5 + 0.5 * v; // radians-ish factor of PI
      parts.add('vignette=angle=PI/${_n(1 / angle)}');
    }
    if (grain > 0) {
      final g = grain.clamp(0, 100);
      parts.add('noise=alls=$g:allf=t+u');
    }
    return parts.isEmpty ? 'null' : parts.join(',');
  }

  static String vfxCommand(
    String input,
    String output, {
    double vignette = 0.5,
    int grain = 8,
  }) {
    return '-y -i $input -vf "${vfxFilter(vignette: vignette, grain: grain)}" '
        '-c:v libx264 -crf 20 -preset fast -c:a copy $output';
  }

  static Future<bool> _run(String command) async {
    log('VfxService command: $command');
    final session = await FFmpegKit.execute(command);
    final rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) return true;
    log('VfxService failed: ${await session.getOutput()}');
    return false;
  }

  static Future<String?> apply(
    String input, {
    double vignette = 0.5,
    int grain = 8,
  }) async {
    final out = '${await getOutputDirectoryPath()}vfx.mp4';
    return await _run(vfxCommand(input, out, vignette: vignette, grain: grain))
        ? out
        : null;
  }
}
