import 'dart:developer';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../utils/storage_path.dart';

/// How to obscure a region.
enum RegionMode { blur, pixelate }

/// Blurs or pixelates a rectangular region (to hide a face, plate or logo).
/// The region is cropped, obscured, and overlaid back at the same spot.
/// Command construction is pure/static for unit testing.
class BlurRegionService {
  /// Rounds to an even, in-frame value >= 2.
  static int _even(int v) {
    if (v < 2) return 2;
    return v.isOdd ? v - 1 : v;
  }

  /// Builds the filter_complex that obscures the [rw]x[rh] region at ([rx],[ry]).
  static String regionFilter(
    int rx,
    int ry,
    int rw,
    int rh, {
    RegionMode mode = RegionMode.blur,
  }) {
    final w = _even(rw);
    final h = _even(rh);
    final crop = 'crop=$w:$h:$rx:$ry';
    final obscure = mode == RegionMode.pixelate
        // Downscale hard then back up with nearest-neighbour = blocky pixels.
        ? '$crop,scale=iw/12:ih/12:flags=neighbor,'
            'scale=$w:$h:flags=neighbor'
        : '$crop,boxblur=20:3';
    return '[0:v]$obscure[fg];[0:v][fg]overlay=$rx:$ry[v]';
  }

  static String regionCommand(
    String input,
    String output,
    int rx,
    int ry,
    int rw,
    int rh, {
    RegionMode mode = RegionMode.blur,
  }) {
    return '-y -i $input -filter_complex '
        '"${regionFilter(rx, ry, rw, rh, mode: mode)}" '
        '-map "[v]" -map 0:a? -c:v libx264 -crf 20 -preset fast -c:a copy '
        '$output';
  }

  static Future<bool> _run(String command) async {
    log('BlurRegionService command: $command');
    final session = await FFmpegKit.execute(command);
    final rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) return true;
    log('BlurRegionService failed: ${await session.getOutput()}');
    return false;
  }

  static Future<String?> apply(
    String input,
    int rx,
    int ry,
    int rw,
    int rh, {
    RegionMode mode = RegionMode.blur,
  }) async {
    final out = '${await getOutputDirectoryPath()}region_${mode.name}.mp4';
    return await _run(regionCommand(input, out, rx, ry, rw, rh, mode: mode))
        ? out
        : null;
  }
}
