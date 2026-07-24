import 'dart:developer';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../utils/storage_path.dart';
import 'advanced_edit_service.dart';

/// Per-frame measurement extracted from FFmpeg's signalstats filter.
class FrameStat {
  final double t; // pts_time in seconds
  final double ydif; // temporal luma difference (motion/shake proxy)
  final double yavg; // average luma 0..255 (exposure)
  final double satavg; // average chroma saturation (colourfulness)

  const FrameStat(this.t, {this.ydif = 0, this.yavg = 128, this.satavg = 60});
}

/// Content-adaptive analysis built on FFmpeg `signalstats`:
/// - motion-spike detection (YDIF) to auto-cut shaky/chaotic sections
/// - exposure/saturation measurement (YAVG/SATAVG) for adaptive colour
///   correction that protects already-saturated tones such as skin.
class AutoAnalysisService {
  // ---- Pure helpers (unit tested) ------------------------------------------

  /// FFmpeg pass that prints per-frame signalstats metadata into the log.
  static String signalStatsCommand(String input) =>
      '-i $input -vf signalstats,metadata=mode=print -f null -';

  /// Parses `pts_time` + `lavfi.signalstats.*` lines from FFmpeg log output.
  static List<FrameStat> parseFrameStats(String logText) {
    final stats = <FrameStat>[];
    double? t;
    double ydif = 0, yavg = 128, satavg = 60;

    void flush() {
      if (t != null) {
        stats.add(FrameStat(t!, ydif: ydif, yavg: yavg, satavg: satavg));
      }
    }

    final ptsRe = RegExp(r'pts_time:\s*([0-9]+(?:\.[0-9]+)?)');
    final kvRe = RegExp(r'lavfi\.signalstats\.(YDIF|YAVG|SATAVG)=([0-9.]+)');

    for (final line in logText.split('\n')) {
      final pts = ptsRe.firstMatch(line);
      if (pts != null) {
        flush(); // previous frame is complete
        t = double.parse(pts.group(1)!);
        ydif = 0;
        yavg = 128;
        satavg = 60;
        continue;
      }
      final kv = kvRe.firstMatch(line);
      if (kv != null && t != null) {
        final v = double.parse(kv.group(2)!);
        switch (kv.group(1)) {
          case 'YDIF':
            ydif = v;
            break;
          case 'YAVG':
            yavg = v;
            break;
          case 'SATAVG':
            satavg = v;
            break;
        }
      }
    }
    flush();
    return stats;
  }

  /// Groups frames whose motion (YDIF) exceeds [threshold] into shaky
  /// intervals. Consecutive spikes closer than [maxGap] seconds merge into one
  /// interval; intervals shorter than [minDuration] are ignored; survivors are
  /// padded by [pad] seconds on both sides (clamped to [0, total]).
  static List<List<double>> shakyIntervals(
    List<FrameStat> stats,
    double total, {
    double threshold = 18.0,
    double maxGap = 0.3,
    double minDuration = 0.25,
    double pad = 0.15,
  }) {
    final intervals = <List<double>>[];
    double? start;
    double last = 0;

    for (final s in stats) {
      if (s.ydif >= threshold) {
        start ??= s.t;
        last = s.t;
      } else if (start != null && s.t - last > maxGap) {
        intervals.add([start, last]);
        start = null;
      }
    }
    if (start != null) intervals.add([start, last]);

    return intervals
        .where((iv) => iv[1] - iv[0] >= minDuration)
        .map((iv) => [
              (iv[0] - pad).clamp(0.0, total),
              (iv[1] + pad).clamp(0.0, total),
            ])
        .toList();
  }

  /// Computes adaptive eq parameters from measured exposure/saturation.
  /// Saturation boost is capped low so already-natural tones (e.g. skin)
  /// are preserved; dark footage gets a gamma lift instead of raw gain.
  static String adaptiveEqParams(double yavg, double satavg) {
    final brightness = ((128 - yavg) / 400).clamp(-0.06, 0.08);
    final double gamma;
    if (yavg < 90) {
      gamma = 1.12; // lift shadows in dark footage
    } else if (yavg > 170) {
      gamma = 0.96; // tame highlights in bright footage
    } else {
      gamma = 1.0;
    }
    final double saturation;
    if (satavg < 40) {
      saturation = 1.15; // dull footage gets a gentle boost
    } else if (satavg < 90) {
      saturation = 1.05;
    } else {
      saturation = 1.0; // already colourful: do not push skin tones
    }
    return 'eq=contrast=1.05:'
        'brightness=${brightness.toStringAsFixed(3)}:'
        'saturation=${saturation.toStringAsFixed(2)}:'
        'gamma=${gamma.toStringAsFixed(2)}';
  }

  static String adaptiveEnhanceCommand(
          String input, String output, String eqParams) =>
      '-y -i $input -vf "$eqParams" -c:v libx264 -crf 20 -preset fast '
      '-c:a copy $output';

  // ---- Runners -------------------------------------------------------------

  static Future<List<FrameStat>> _measure(String input) async {
    final session = await FFmpegKit.execute(signalStatsCommand(input));
    if (!ReturnCode.isSuccess(await session.getReturnCode())) {
      log("AutoAnalysis: signalstats failed");
      return const [];
    }
    return parseFrameStats((await session.getOutput()) ?? '');
  }

  /// Auto-cuts shaky/fast-motion sections. Returns null when nothing
  /// significant was found (callers should tell the user, not error).
  static Future<String?> removeShakyParts(String input, double total) async {
    final stats = await _measure(input);
    if (stats.isEmpty) return null;

    final shaky = shakyIntervals(stats, total);
    if (shaky.isEmpty) return null;

    final keep =
        AdvancedEditService.keepSegmentsFromSilence(shaky, total);
    if (keep.isEmpty) return null; // whole clip shaky: nothing sensible left
    final kept = keep.fold<double>(0, (a, s) => a + (s[1] - s[0]));
    if (total > 0 && kept / total > 0.99) return null;

    final out = "${await getOutputDirectoryPath()}steadycut.mp4";
    final ok = await FFmpegKit.execute(
            AdvancedEditService.jumpCutCommand(input, out, keep))
        .then((s) async => ReturnCode.isSuccess(await s.getReturnCode()));
    return ok ? out : null;
  }

  /// Measures the clip and applies content-adaptive colour correction.
  static Future<String?> adaptiveEnhance(String input) async {
    final stats = await _measure(input);
    // Fall back to neutral midpoints when measurement fails.
    final yavg = stats.isEmpty
        ? 128.0
        : stats.map((s) => s.yavg).reduce((a, b) => a + b) / stats.length;
    final satavg = stats.isEmpty
        ? 60.0
        : stats.map((s) => s.satavg).reduce((a, b) => a + b) / stats.length;

    final out = "${await getOutputDirectoryPath()}adaptive_enhanced.mp4";
    final cmd =
        adaptiveEnhanceCommand(input, out, adaptiveEqParams(yavg, satavg));
    log("AutoAnalysis adaptive enhance: $cmd");
    final ok = await FFmpegKit.execute(cmd)
        .then((s) async => ReturnCode.isSuccess(await s.getReturnCode()));
    return ok ? out : null;
  }
}
