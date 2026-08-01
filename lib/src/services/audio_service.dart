import 'dart:developer';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../utils/storage_path.dart';

/// Adds a background-music track to a video with FFmpeg. Unlike a plain audio
/// swap, this can **mix** the music with the clip's original sound, control the
/// music/original volumes independently, fade the music in/out, and loop a
/// short track so it fills the whole clip (without ever truncating the video).
///
/// The command construction lives in a pure static helper so it can be unit
/// tested without a device.
class AudioService {
  /// Compact number formatting for FFmpeg filter args.
  static String fmt(double v) {
    var s = v.toStringAsFixed(3);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
    }
    return s.isEmpty ? '0' : s;
  }

  /// Builds the FFmpeg command that lays [music] over [video].
  ///
  /// * [musicVolume] / [originalVolume] — linear gain (1.0 = unchanged).
  /// * [keepOriginal] — mix with the clip's own audio (true) or replace it.
  /// * [fade] — fade the music in at the start and out at the end.
  /// * [loopMusic] — loop a short track to cover the whole clip.
  ///
  /// The video stream is stream-copied (fast, lossless); the output length is
  /// bound to the video via `-shortest`, and the mix uses `duration=first`, so
  /// a music track that is shorter *or* longer than the clip never changes the
  /// video length.
  static String addMusicCommand(
    String video,
    String music,
    String output, {
    required double totalSeconds,
    double musicVolume = 0.6,
    double originalVolume = 1.0,
    bool keepOriginal = true,
    bool fade = true,
    double fadeSeconds = 1.0,
    bool loopMusic = true,
    bool duckUnderVoice = false,
  }) {
    final mv = musicVolume.clamp(0.0, 4.0);
    final ov = originalVolume.clamp(0.0, 4.0);
    final loop = loopMusic ? '-stream_loop -1 ' : '';

    final music_ = StringBuffer('[1:a]volume=${fmt(mv)}');
    if (fade && fadeSeconds > 0) {
      final outStart =
          (totalSeconds - fadeSeconds).clamp(0.0, double.maxFinite);
      music_.write(',afade=t=in:st=0:d=${fmt(fadeSeconds)}');
      music_.write(',afade=t=out:st=${fmt(outStart)}:d=${fmt(fadeSeconds)}');
    }

    final String filter;
    if (keepOriginal && duckUnderVoice) {
      // Duck the music whenever the original audio (voice) is present, using
      // the voice as the sidechain, then mix the (unducked) voice back on top.
      filter = '[0:a]volume=${fmt(ov)},asplit=2[o][sc];$music_[m];'
          '[m][sc]sidechaincompress='
          'threshold=0.02:ratio=6:attack=5:release=250[mduck];'
          '[o][mduck]amix=inputs=2:duration=first:dropout_transition=0[a]';
    } else if (keepOriginal) {
      filter = '[0:a]volume=${fmt(ov)}[o];$music_[m];'
          '[o][m]amix=inputs=2:duration=first:dropout_transition=0[a]';
    } else {
      filter = '$music_[a]';
    }

    return '-y -i $video $loop-i $music '
        '-filter_complex "$filter" '
        '-map 0:v -map "[a]" -c:v copy -c:a aac -shortest $output';
  }

  static Future<bool> _run(String command) async {
    log('AudioService command: $command');
    final session = await FFmpegKit.execute(command);
    final rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) return true;
    log('AudioService failed: ${await session.getOutput()}');
    return false;
  }

  /// Renders [video] with [music] laid over it and returns the output path (or
  /// null on failure). If mixing is requested but the clip has no audio track
  /// (which would make the mix fail), it automatically falls back to a
  /// music-only render so the operation still succeeds.
  static Future<String?> addMusic(
    String video,
    String music, {
    required double totalSeconds,
    double musicVolume = 0.6,
    double originalVolume = 1.0,
    bool keepOriginal = true,
    bool fade = true,
    bool loopMusic = true,
    bool duckUnderVoice = false,
  }) async {
    final out = '${await getOutputDirectoryPath()}with_music.mp4';

    if (await _run(addMusicCommand(
      video,
      music,
      out,
      totalSeconds: totalSeconds,
      musicVolume: musicVolume,
      originalVolume: originalVolume,
      keepOriginal: keepOriginal,
      fade: fade,
      loopMusic: loopMusic,
      duckUnderVoice: duckUnderVoice,
    ))) {
      return out;
    }

    // The clip may have no original audio to mix with — retry music-only.
    if (keepOriginal) {
      if (await _run(addMusicCommand(
        video,
        music,
        out,
        totalSeconds: totalSeconds,
        musicVolume: musicVolume,
        keepOriginal: false,
        fade: fade,
        loopMusic: loopMusic,
      ))) {
        return out;
      }
    }
    return null;
  }
}
