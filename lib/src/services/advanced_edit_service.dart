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

  /// One-tap automatic colour/contrast enhance.
  static String autoEnhanceCommand(String input, String output) =>
      '-y -i $input -vf '
      '"eq=contrast=1.06:brightness=0.03:saturation=1.12:gamma=1.02,'
      'unsharp=3:3:0.4:3:3:0.0" '
      '-c:v libx264 -crf 20 -preset fast -c:a copy $output';

  // ---- Auto-cut (silence-based jump cut) -----------------------------------

  /// FFmpeg command that detects silent regions in the audio; the timestamps
  /// are then parsed from its log output.
  static String silenceDetectCommand(String input,
          {int noiseDb = -30, double minSilence = 0.5}) =>
      '-i $input -af silencedetect=noise=${noiseDb}dB:d=$minSilence -f null -';

  /// Parses `silence_start`/`silence_end` pairs from silencedetect log output.
  /// A silence that runs to the end of the file (no matching end) is closed at
  /// [total].
  static List<List<double>> parseSilences(String log, double total) {
    final starts = RegExp(r'silence_start:\s*([0-9.]+)')
        .allMatches(log)
        .map((m) => double.parse(m.group(1)!))
        .toList();
    final ends = RegExp(r'silence_end:\s*([0-9.]+)')
        .allMatches(log)
        .map((m) => double.parse(m.group(1)!))
        .toList();
    final silences = <List<double>>[];
    for (var i = 0; i < starts.length; i++) {
      final end = i < ends.length ? ends[i] : total;
      silences.add([starts[i], end]);
    }
    return silences;
  }

  /// Inverts silent intervals into the segments to KEEP within [0, total],
  /// dropping slivers shorter than [minKeep] seconds.
  static List<List<double>> keepSegmentsFromSilence(
    List<List<double>> silences,
    double total, {
    double minKeep = 0.15,
  }) {
    final keep = <List<double>>[];
    double cursor = 0;
    for (final s in silences) {
      final start = s[0];
      final end = s[1];
      if (start > cursor && start - cursor >= minKeep) {
        keep.add([cursor, start]);
      }
      if (end > cursor) cursor = end;
    }
    if (total - cursor >= minKeep) keep.add([cursor, total]);
    return keep;
  }

  /// Builds the select/aselect filter_complex that keeps only [segments].
  static String jumpCutFilter(List<List<double>> segments) {
    final expr = segments.isEmpty
        ? '1'
        : segments
            .map((s) =>
                'between(t,${s[0].toStringAsFixed(3)},${s[1].toStringAsFixed(3)})')
            .join('+');
    return "[0:v]select='$expr',setpts=N/FRAME_RATE/TB[v];"
        "[0:a]aselect='$expr',asetpts=N/SR/TB[a]";
  }

  static String jumpCutCommand(
          String input, String output, List<List<double>> keep) =>
      '-y -i $input -filter_complex "${jumpCutFilter(keep)}" '
      '-map "[v]" -map "[a]" -c:v libx264 -crf 20 -preset fast $output';

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

  static Future<String?> autoEnhance(String input) async {
    final out = "${await getOutputDirectoryPath()}enhanced.mp4";
    return await _run(autoEnhanceCommand(input, out)) ? out : null;
  }

  /// AI-style auto cut: detects silent gaps and removes them (jump cut).
  /// Returns null if there is nothing worth cutting (keeps < ~90% would be a
  /// real cut; otherwise we skip to avoid a pointless re-encode).
  static Future<String?> autoCutSilence(String input, double total) async {
    final session = await FFmpegKit.execute(silenceDetectCommand(input));
    if (!ReturnCode.isSuccess(await session.getReturnCode())) {
      log("autoCut: silencedetect failed");
      return null;
    }
    final logs = (await session.getOutput()) ?? '';
    final silences = parseSilences(logs, total);
    if (silences.isEmpty) return null;

    final keep = keepSegmentsFromSilence(silences, total);
    if (keep.isEmpty) return null;
    final kept = keep.fold<double>(0, (a, s) => a + (s[1] - s[0]));
    // If we'd remove less than 1% of the clip, it isn't worth it.
    if (total > 0 && kept / total > 0.99) return null;

    final out = "${await getOutputDirectoryPath()}autocut.mp4";
    return await _run(jumpCutCommand(input, out, keep)) ? out : null;
  }
}
