import 'dart:developer';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../utils/storage_path.dart';

/// Joins two clips with a professional transition using FFmpeg's `xfade`
/// (video) and `acrossfade` (audio). Both inputs are normalised to the same
/// size, pixel format, SAR and frame rate first — the requirement `xfade` has —
/// so clips of different resolutions/frame rates can still be joined.
///
/// Command construction is a pure static helper for unit testing.
class TransitionService {
  /// Curated, widely-supported `xfade` transitions (name shown in the UI ->
  /// FFmpeg transition id).
  static const Map<String, String> transitions = {
    'Crossfade': 'fade',
    'Fade Black': 'fadeblack',
    'Fade White': 'fadewhite',
    'Dissolve': 'dissolve',
    'Wipe Left': 'wipeleft',
    'Wipe Right': 'wiperight',
    'Wipe Up': 'wipeup',
    'Wipe Down': 'wipedown',
    'Slide Left': 'slideleft',
    'Slide Right': 'slideright',
    'Circle Open': 'circleopen',
    'Radial': 'radial',
    'Pixelize': 'pixelize',
  };

  /// Compact number formatting for FFmpeg args.
  static String fmt(double v) {
    var s = v.toStringAsFixed(3);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
    }
    return s.isEmpty ? '0' : s;
  }

  /// Builds the FFmpeg command that joins [a] then [b] with [transition]
  /// (an xfade id) lasting [duration] seconds. [clip1Duration] is the length of
  /// [a]; the transition begins [duration] seconds before it ends. Both clips
  /// are scaled to [w]x[h] at [fps]. Output length is
  /// `clip1Duration + clip2Duration - duration`.
  static String transitionCommand(
    String a,
    String b,
    String output, {
    required int w,
    required int h,
    required double clip1Duration,
    String transition = 'fade',
    double duration = 1.0,
    int fps = 30,
    bool keepAudio = true,
  }) {
    final offset = (clip1Duration - duration).clamp(0.0, double.maxFinite);
    final v0 = '[0:v]scale=$w:$h,setsar=1,fps=$fps,format=yuv420p[v0]';
    final v1 = '[1:v]scale=$w:$h,setsar=1,fps=$fps,format=yuv420p[v1]';
    final xf = '[v0][v1]xfade=transition=$transition:'
        'duration=${fmt(duration)}:offset=${fmt(offset)}[v]';

    if (!keepAudio) {
      return '-y -i $a -i $b -filter_complex "$v0;$v1;$xf" '
          '-map "[v]" -c:v libx264 -crf 20 -preset fast -an $output';
    }
    final af = '[0:a][1:a]acrossfade=d=${fmt(duration)}[a]';
    return '-y -i $a -i $b -filter_complex "$v0;$v1;$xf;$af" '
        '-map "[v]" -map "[a]" -c:v libx264 -crf 20 -preset fast $output';
  }

  static Future<bool> _run(String command) async {
    log('TransitionService command: $command');
    final session = await FFmpegKit.execute(command);
    final rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) return true;
    log('TransitionService failed: ${await session.getOutput()}');
    return false;
  }

  /// Joins the two clips and returns the output path (or null). If crossfading
  /// audio fails (e.g. a clip has no audio track), it retries video-only so the
  /// operation still succeeds.
  static Future<String?> joinWithTransition(
    String a,
    String b, {
    required int w,
    required int h,
    required double clip1Duration,
    String transition = 'fade',
    double duration = 1.0,
    int fps = 30,
    bool keepAudio = true,
  }) async {
    final out = '${await getOutputDirectoryPath()}transition.mp4';
    if (await _run(transitionCommand(a, b, out,
        w: w,
        h: h,
        clip1Duration: clip1Duration,
        transition: transition,
        duration: duration,
        fps: fps,
        keepAudio: keepAudio))) {
      return out;
    }
    if (keepAudio) {
      if (await _run(transitionCommand(a, b, out,
          w: w,
          h: h,
          clip1Duration: clip1Duration,
          transition: transition,
          duration: duration,
          fps: fps,
          keepAudio: false))) {
        return out;
      }
    }
    return null;
  }
}
