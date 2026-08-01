import 'dart:developer';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../utils/storage_path.dart';

/// Joins several clips into one. Each input is normalised to the same
/// size/SAR/fps/pixel-format (concat's requirement) so clips of different
/// resolutions/frame rates can be merged. Command construction is pure/static.
class MergeService {
  /// Builds the concat filter_complex for [count] inputs at [w]x[h]/[fps].
  static String concatFilter(
    int count,
    int w,
    int h,
    int fps, {
    bool withAudio = true,
  }) {
    final chains = <String>[];
    final labels = StringBuffer();
    for (var i = 0; i < count; i++) {
      chains.add('[$i:v]scale=$w:$h:force_original_aspect_ratio=increase,'
          'crop=$w:$h,setsar=1,fps=$fps,format=yuv420p[v$i]');
      labels.write('[v$i]');
      if (withAudio) labels.write('[$i:a]');
    }
    final av = withAudio
        ? 'concat=n=$count:v=1:a=1[v][a]'
        : 'concat=n=$count:v=1:a=0[v]';
    return '${chains.join(';')};$labels$av';
  }

  static String mergeCommand(
    List<String> inputs,
    String output, {
    required int w,
    required int h,
    int fps = 30,
    bool withAudio = true,
  }) {
    final ins = inputs.map((p) => '-i $p').join(' ');
    final filter = concatFilter(inputs.length, w, h, fps, withAudio: withAudio);
    final maps = withAudio ? '-map "[v]" -map "[a]"' : '-map "[v]"';
    return '-y $ins -filter_complex "$filter" $maps '
        '-c:v libx264 -crf 20 -preset fast $output';
  }

  static Future<bool> _run(String command) async {
    log('MergeService command: $command');
    final session = await FFmpegKit.execute(command);
    final rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) return true;
    log('MergeService failed: ${await session.getOutput()}');
    return false;
  }

  /// Merges [inputs] (in order). Requires at least 2. Falls back to video-only
  /// concat if the audio concat fails (e.g. a clip has no audio).
  static Future<String?> merge(
    List<String> inputs, {
    required int w,
    required int h,
    int fps = 30,
  }) async {
    if (inputs.length < 2) return null;
    final out = '${await getOutputDirectoryPath()}merged.mp4';
    if (await _run(mergeCommand(inputs, out, w: w, h: h, fps: fps))) {
      return out;
    }
    if (await _run(
        mergeCommand(inputs, out, w: w, h: h, fps: fps, withAudio: false))) {
      return out;
    }
    return null;
  }
}
