import 'dart:developer';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../utils/storage_path.dart';

/// Turns a set of photos into a video — each shown for a few seconds, scaled to
/// a common frame, with optional background music. Command construction is
/// pure/static for unit testing.
class SlideshowService {
  static String _n(double v) {
    var s = v.toStringAsFixed(2);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
    }
    return s.isEmpty ? '0' : s;
  }

  /// Builds the slideshow command for [images] at [w]x[h], [secondsPer] image,
  /// with optional [music] (looped, trimmed to the slideshow length).
  static String slideshowCommand(
    List<String> images,
    String output, {
    required int w,
    required int h,
    double secondsPer = 2.5,
    String? music,
  }) {
    final ins = StringBuffer();
    for (final img in images) {
      ins.write('-loop 1 -t ${_n(secondsPer)} -i $img ');
    }
    if (music != null) ins.write('-stream_loop -1 -i $music ');

    final chains = <String>[];
    final labels = StringBuffer();
    for (var i = 0; i < images.length; i++) {
      chains.add('[$i:v]scale=$w:$h:force_original_aspect_ratio=increase,'
          'crop=$w:$h,setsar=1,fps=30,format=yuv420p[v$i]');
      labels.write('[v$i]');
    }
    final filter =
        '${chains.join(';')};${labels}concat=n=${images.length}:v=1:a=0[v]';

    final audioMap = music != null ? '-map ${images.length}:a' : '';
    final shortest = music != null ? '-shortest' : '';
    return '-y ${ins.toString().trim()} -filter_complex "$filter" '
        '-map "[v]" $audioMap -c:v libx264 -crf 20 -preset fast '
        '${music != null ? '-c:a aac ' : ''}$shortest $output';
  }

  static Future<bool> _run(String command) async {
    log('SlideshowService command: $command');
    final session = await FFmpegKit.execute(command);
    final rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) return true;
    log('SlideshowService failed: ${await session.getOutput()}');
    return false;
  }

  /// Builds a slideshow from [images] (requires at least 1).
  static Future<String?> build(
    List<String> images, {
    required int w,
    required int h,
    double secondsPer = 2.5,
    String? music,
  }) async {
    if (images.isEmpty) return null;
    final out = '${await getOutputDirectoryPath()}slideshow.mp4';
    return await _run(slideshowCommand(images, out,
            w: w, h: h, secondsPer: secondsPer, music: music))
        ? out
        : null;
  }
}
