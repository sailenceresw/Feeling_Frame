import 'dart:developer';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../utils/storage_path.dart';

/// Exports a video as a GIF with control over fps, width, looping and quality.
/// High quality uses a per-clip palette (palettegen/paletteuse). Command
/// construction is pure/static for unit testing.
class GifStudioService {
  /// Builds the GIF command. [loop] follows FFmpeg's `-loop` (0 = infinite,
  /// -1 = play once). [highQuality] adds a palette pass for cleaner colours.
  static String gifCommand(
    String input,
    String output, {
    int fps = 12,
    int width = 480,
    int loop = 0,
    bool highQuality = false,
  }) {
    final base = 'fps=$fps,scale=$width:-1:flags=lanczos';
    if (highQuality) {
      return '-y -i $input -filter_complex '
          '"[0:v]$base,split[a][b];[a]palettegen[p];[b][p]paletteuse" '
          '-loop $loop $output';
    }
    return '-y -i $input -vf "$base" -loop $loop $output';
  }

  static Future<bool> _run(String command) async {
    log('GifStudioService command: $command');
    final session = await FFmpegKit.execute(command);
    final rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) return true;
    log('GifStudioService failed: ${await session.getOutput()}');
    return false;
  }

  static Future<String?> export(
    String input, {
    int fps = 12,
    int width = 480,
    int loop = 0,
    bool highQuality = false,
  }) async {
    final out = '${await getOutputDirectoryPath()}export.gif';
    return await _run(gifCommand(input, out,
            fps: fps, width: width, loop: loop, highQuality: highQuality))
        ? out
        : null;
  }
}
