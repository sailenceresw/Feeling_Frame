import 'dart:developer';

import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';

import '../utils/storage_path.dart';

/// Advanced editing operations built on FFmpeg. Command construction is kept
/// in pure static helpers (no I/O) so it can be unit tested; the public
/// methods resolve an output path, run the command, and return the result
/// path (or null on failure).
class AdvancedEditService {
  // ---- Pure command builders (unit tested) ---------------------------------

  /// Exports the video as an animated GIF (12fps, 480px wide, palette-free
  /// quick path).
  static String gifCommand(String input, String output) =>
      '-y -i $input -vf "fps=12,scale=480:-1:flags=lanczos" -loop 0 $output';

  /// Extracts the audio track to an MP3 file.
  static String extractAudioCommand(String input, String output) =>
      '-y -i $input -vn -acodec libmp3lame -q:a 2 $output';

  /// Boomerang: plays the clip forward then reversed (video only, like the
  /// popular social effect).
  static String boomerangCommand(String input, String output) =>
      '-y -i $input -filter_complex '
      '"[0:v]reverse[r];[0:v][r]concat=n=2:v=1:a=0[v]" '
      '-map "[v]" -c:v libx264 -crf 23 -preset fast -an $output';

  /// Fade in and out on both video and audio. [totalSeconds] is the clip
  /// length; the out-fade starts [fade] seconds before the end.
  static String fadeCommand(
    String input,
    String output,
    double totalSeconds, {
    double fade = 1.0,
  }) {
    final outStart = (totalSeconds - fade).clamp(0.0, double.maxFinite);
    final start = outStart.toStringAsFixed(2);
    return '-y -i $input '
        '-vf "fade=t=in:st=0:d=$fade,fade=t=out:st=$start:d=$fade" '
        '-af "afade=t=in:st=0:d=$fade,afade=t=out:st=$start:d=$fade" '
        '-c:v libx264 -crf 23 -preset fast $output';
  }

  /// Grabs a single frame at [seconds] as a high-quality JPEG (fast seek by
  /// placing -ss before -i).
  static String grabFrameCommand(String input, String output, double seconds) =>
      '-y -ss ${seconds.toStringAsFixed(2)} -i $input -frames:v 1 -q:v 2 $output';

  // ---- Runners -------------------------------------------------------------

  static Future<bool> _run(String command) async {
    log("AdvancedEditService command: $command");
    final session = await FFmpegKit.execute(command);
    final rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) return true;
    log("AdvancedEditService failed: ${await session.getOutput()}");
    return false;
  }

  static Future<String?> toGif(String input) async {
    final out = "${await getOutputDirectoryPath()}export.gif";
    return await _run(gifCommand(input, out)) ? out : null;
  }

  static Future<String?> extractAudio(String input) async {
    final out = "${await getOutputDirectoryPath()}audio_track.mp3";
    return await _run(extractAudioCommand(input, out)) ? out : null;
  }

  static Future<String?> boomerang(String input) async {
    final out = "${await getOutputDirectoryPath()}boomerang.mp4";
    return await _run(boomerangCommand(input, out)) ? out : null;
  }

  static Future<String?> fadeInOut(String input, double totalSeconds) async {
    final out = "${await getOutputDirectoryPath()}faded.mp4";
    return await _run(fadeCommand(input, out, totalSeconds)) ? out : null;
  }

  static Future<String?> grabFrame(String input, double seconds) async {
    final out = "${await getOutputDirectoryPath()}"
        "frame_${seconds.toStringAsFixed(0)}s.jpg";
    return await _run(grabFrameCommand(input, out, seconds)) ? out : null;
  }
}
