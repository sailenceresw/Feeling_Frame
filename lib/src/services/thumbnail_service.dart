import 'dart:developer';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../utils/storage_path.dart';
import 'text_service.dart';

/// Designs a cover/thumbnail image: grabs a frame at a chosen time and
/// optionally overlays a title. Command construction is pure/static for tests.
class ThumbnailService {
  static String _n(double v) {
    var s = v.toStringAsFixed(2);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
    }
    return s.isEmpty ? '0' : s;
  }

  /// The drawtext for a title on the cover ([text] must already be sanitised).
  static String titleFilter(
    String fontfile,
    String text, {
    String position = TextService.bottom,
    int fontSize = 56,
    String color = 'white',
  }) {
    return 'drawtext=fontfile=$fontfile:text=\'$text\':'
        '${TextService.positionXY(position)}:fontsize=$fontSize:'
        'fontcolor=$color:box=1:boxcolor=black@0.5:boxborderw=12';
  }

  /// Command that saves a single frame at [seconds] as a JPEG, optionally with
  /// a [drawtext] title overlay.
  static String thumbnailCommand(
    String input,
    String output,
    double seconds, {
    String? drawtext,
  }) {
    final vf = (drawtext != null && drawtext.isNotEmpty)
        ? ' -vf "$drawtext"'
        : '';
    return '-y -ss ${_n(seconds)} -i $input -frames:v 1$vf -q:v 2 $output';
  }

  static Future<bool> _run(String command) async {
    log('ThumbnailService command: $command');
    final session = await FFmpegKit.execute(command);
    final rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) return true;
    log('ThumbnailService failed: ${await session.getOutput()}');
    return false;
  }

  /// Generates the cover image and returns its path (JPEG).
  static Future<String?> generate(
    String input, {
    required double seconds,
    String title = '',
    String position = TextService.bottom,
    int fontSize = 56,
    String color = 'white',
  }) async {
    String? drawtext;
    final safe = TextService.sanitizeText(title);
    if (safe.isNotEmpty) {
      final font = await TextService.ensureFont();
      drawtext = titleFilter(font, safe,
          position: position, fontSize: fontSize, color: color);
    }
    final out = '${await getOutputDirectoryPath()}cover.jpg';
    return await _run(thumbnailCommand(input, out, seconds, drawtext: drawtext))
        ? out
        : null;
  }
}
