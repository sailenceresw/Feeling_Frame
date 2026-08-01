import 'dart:developer';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../utils/storage_path.dart';
import 'text_service.dart';

/// Classic meme captions: bold white text with a black outline, top and/or
/// bottom. Command construction is pure/static for unit testing.
class MemeService {
  /// Builds the drawtext chain. [top]/[bottom] must already be sanitised.
  static String memeFilter(
    String fontfile, {
    String top = '',
    String bottom = '',
    int fontSize = 48,
  }) {
    final common =
        ':fontsize=$fontSize:fontcolor=white:borderw=4:bordercolor=black';
    final parts = <String>[];
    if (top.trim().isNotEmpty) {
      parts.add("drawtext=fontfile=$fontfile:text='$top':"
          "x=(w-text_w)/2:y=h*0.04$common");
    }
    if (bottom.trim().isNotEmpty) {
      parts.add("drawtext=fontfile=$fontfile:text='$bottom':"
          "x=(w-text_w)/2:y=h-text_h-h*0.04$common");
    }
    return parts.isEmpty ? 'null' : parts.join(',');
  }

  static String memeCommand(String input, String output, String filter) =>
      '-y -i $input -vf "$filter" '
      '-c:v libx264 -crf 20 -preset fast -c:a copy $output';

  static Future<bool> _run(String command) async {
    log('MemeService command: $command');
    final session = await FFmpegKit.execute(command);
    final rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) return true;
    log('MemeService failed: ${await session.getOutput()}');
    return false;
  }

  static Future<String?> generate(
    String input, {
    String top = '',
    String bottom = '',
    int fontSize = 48,
  }) async {
    final safeTop = TextService.sanitizeText(top);
    final safeBottom = TextService.sanitizeText(bottom);
    if (safeTop.isEmpty && safeBottom.isEmpty) return null;
    final font = await TextService.ensureFont();
    final filter = memeFilter(font,
        top: safeTop, bottom: safeBottom, fontSize: fontSize);
    final out = '${await getOutputDirectoryPath()}meme.mp4';
    return await _run(memeCommand(input, out, filter)) ? out : null;
  }
}
