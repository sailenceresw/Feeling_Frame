import 'dart:developer';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';

import '../utils/storage_path.dart';

/// On-device AI video enhancement helpers powered by FFmpeg.
///
/// These implement the core automation themes of the project proposal —
/// noise reduction, video stabilization, and automatically keeping the most
/// crucial sections of a video — and run fully offline (no Google Cloud
/// credentials required).
class AiVideoService {
  static Future<bool> _run(String command) async {
    log("AiVideoService command: $command");
    final session = await FFmpegKit.execute(command);
    final rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) return true;
    log("AiVideoService failed: ${await session.getOutput()}");
    return false;
  }

  /// Reduces background noise in the audio track using FFmpeg's FFT denoiser
  /// plus a high-pass filter to remove low-frequency rumble.
  static Future<String?> reduceNoise(String inputPath) async {
    final out = "${await getOutputDirectoryPath()}denoised.mp4";
    final ok = await _run(
        '-y -i $inputPath -af "afftdn=nf=-25,highpass=f=80" -c:v copy -c:a aac $out');
    return ok ? out : null;
  }

  /// Stabilizes shaky footage with the classic two-pass vid.stab pipeline
  /// (motion analysis pass, then transform + sharpen pass).
  static Future<String?> stabilizeVideo(String inputPath) async {
    final base = await getOutputDirectoryPath();
    final trf = "${base}transforms.trf";
    final out = "${base}stabilized.mp4";

    final detected = await _run(
        '-y -i $inputPath -vf vidstabdetect=shakiness=5:accuracy=15:result=$trf -f null -');
    if (!detected) return null;

    final ok = await _run(
        '-y -i $inputPath -vf "vidstabtransform=input=$trf:zoom=1:smoothing=15,unsharp=5:5:0.8:3:0.4" '
        '-c:v libx264 -crf 23 -preset fast -c:a copy $out');
    return ok ? out : null;
  }

  /// Builds an automatic highlights reel: detects scene changes and keeps a
  /// short clip around each one, discarding the rest of the footage
  /// ("save the most crucial sections of a video and get rid of the rest").
  static Future<String?> autoHighlights(
    String inputPath, {
    double sceneThreshold = 0.35,
    int clipSeconds = 3,
    int maxClips = 6,
  }) async {
    final base = await getOutputDirectoryPath();

    // Pass 1: find scene-change timestamps.
    final session = await FFmpegKit.execute(
        "-y -i $inputPath -vf \"select='gt(scene,$sceneThreshold)',showinfo\" -f null -");
    final rc = await session.getReturnCode();
    if (!ReturnCode.isSuccess(rc)) {
      log("autoHighlights detect failed: ${await session.getOutput()}");
      return null;
    }
    final logs = (await session.getOutput()) ?? '';
    final times = RegExp(r'pts_time:([0-9]+(?:\.[0-9]+)?)')
        .allMatches(logs)
        .map((m) => double.parse(m.group(1)!))
        .toList();
    if (times.isEmpty) {
      log("autoHighlights: no scene changes detected");
      return null;
    }

    // Keep up to [maxClips] well-separated moments, starting slightly before
    // each detected change.
    final starts = <double>[];
    for (final t in times) {
      final s = (t - 1).clamp(0.0, double.maxFinite);
      if (starts.isEmpty || s - starts.last >= clipSeconds + 1) {
        starts.add(s);
      }
      if (starts.length >= maxClips) break;
    }

    // Pass 2: cut each moment to an MPEG-TS chunk (stream copy, keyframe
    // aligned) using the same transport-stream concat approach as the
    // multi-video merge feature.
    final parts = <String>[];
    for (int i = 0; i < starts.length; i++) {
      final part = "${base}highlight_$i.ts";
      final ok = await _run(
          '-y -ss ${starts[i].toStringAsFixed(2)} -t $clipSeconds -i $inputPath '
          '-c copy -bsf:v h264_mp4toannexb -f mpegts $part');
      if (ok) parts.add(part);
    }
    if (parts.isEmpty) return null;

    final out = "${base}highlights.mp4";
    final ok = await _run(
        '-y -i "concat:${parts.join('|')}" -c copy -bsf:a aac_adtstoasc $out');

    // Clean up the temporary chunks.
    for (final p in parts) {
      try {
        File(p).deleteSync();
      } catch (_) {}
    }
    return ok ? out : null;
  }

  /// Renders the audio track's waveform to a PNG image (audio waveform
  /// visualization — report future enhancement). Returns the image path.
  static Future<String?> generateWaveform(String inputPath) async {
    final out = "${await getOutputDirectoryPath()}"
        "waveform_${DateTime.now().millisecondsSinceEpoch}.png";
    final ok = await _run(
        '-y -i $inputPath -filter_complex "showwavespic=s=1080x240:colors=yellow" '
        '-frames:v 1 $out');
    return ok ? out : null;
  }

  /// Burns an SRT subtitle file into the video (caption production).
  static Future<String?> burnCaptions(String inputPath, String srtPath) async {
    final out = "${await getOutputDirectoryPath()}captioned.mp4";
    final ok = await _run(
        '-y -i $inputPath -vf "subtitles=$srtPath" -c:v libx264 -crf 23 '
        '-preset fast -c:a copy $out');
    return ok ? out : null;
  }
}
