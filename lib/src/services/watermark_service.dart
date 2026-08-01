import 'dart:developer';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../utils/storage_path.dart';

/// Overlays a user-supplied logo / watermark image onto a video — any corner,
/// sized as a fraction of the video width, with adjustable opacity. Works for
/// PNG (keeps transparency) and opaque images alike.
///
/// Command construction is pure/static for unit testing.
class WatermarkService {
  static const String topLeft = 'topLeft';
  static const String topRight = 'topRight';
  static const String bottomLeft = 'bottomLeft';
  static const String bottomRight = 'bottomRight';

  static const List<String> corners = [
    topLeft,
    topRight,
    bottomLeft,
    bottomRight,
  ];

  static String _n(double v) {
    var s = v.toStringAsFixed(3);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
    }
    return s.isEmpty ? '0' : s;
  }

  /// Overlay x:y expression for [corner] with a pixel [margin].
  static String overlayXY(String corner, int margin) {
    switch (corner) {
      case topLeft:
        return '$margin:$margin';
      case topRight:
        return 'W-w-$margin:$margin';
      case bottomLeft:
        return '$margin:H-h-$margin';
      case bottomRight:
      default:
        return 'W-w-$margin:H-h-$margin';
    }
  }

  /// Even watermark width in pixels for [sizeFraction] of [mainW].
  static int watermarkWidth(int mainW, double sizeFraction) {
    var w = (mainW * sizeFraction).round();
    if (w.isOdd) w -= 1;
    return w < 2 ? 2 : w;
  }

  /// Builds the FFmpeg command that stamps [image] onto [video]. [opacity] is
  /// 0..1 (multiplies any existing alpha).
  static String watermarkCommand(
    String video,
    String image,
    String output, {
    required int mainW,
    double sizeFraction = 0.18,
    double opacity = 0.7,
    String corner = bottomRight,
    int? margin,
  }) {
    final w = watermarkWidth(mainW, sizeFraction);
    final m = margin ?? (mainW * 0.03).round();
    final xy = overlayXY(corner, m);
    final op = opacity.clamp(0.0, 1.0);
    return '-y -i $video -i $image -filter_complex '
        '"[1:v]scale=$w:-1,format=rgba,colorchannelmixer=aa=${_n(op)}[wm];'
        '[0:v][wm]overlay=$xy[v]" '
        '-map "[v]" -map 0:a? -c:v libx264 -crf 20 -preset fast -c:a copy '
        '$output';
  }

  static Future<bool> _run(String command) async {
    log('WatermarkService command: $command');
    final session = await FFmpegKit.execute(command);
    final rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) return true;
    log('WatermarkService failed: ${await session.getOutput()}');
    return false;
  }

  /// Applies the watermark and returns the output path (or null).
  static Future<String?> apply(
    String video,
    String image, {
    required int mainW,
    double sizeFraction = 0.18,
    double opacity = 0.7,
    String corner = bottomRight,
  }) async {
    final out = '${await getOutputDirectoryPath()}watermarked.mp4';
    return await _run(watermarkCommand(
      video,
      image,
      out,
      mainW: mainW,
      sizeFraction: sizeFraction,
      opacity: opacity,
      corner: corner,
    ))
        ? out
        : null;
  }
}
