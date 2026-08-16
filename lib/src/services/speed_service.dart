import '../utils/ffmpeg_cmd.dart';
import '../utils/storage_path.dart';

/// Changes the playback speed of a clip (slow-motion or fast-forward) with
/// FFmpeg. Video timing uses `setpts`; audio uses `atempo`, which is limited to
/// 0.5–2.0 per instance, so extreme speeds are produced by chaining several
/// `atempo` filters whose product equals the requested speed.
///
/// Command construction is kept in pure static helpers so it can be unit
/// tested without a device.
class SpeedService {
  static const double minSpeed = 0.25;
  static const double maxSpeed = 4.0;

  /// Compact number formatting for FFmpeg args (trims trailing zeros).
  static String fmt(double v) {
    var s = v.toStringAsFixed(4);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
    }
    return s.isEmpty ? '0' : s;
  }

  /// Decomposes [speed] into a list of `atempo` factors, each within FFmpeg's
  /// valid 0.5–2.0 range, whose product is [speed].
  static List<double> atempoFactors(double speed) {
    final factors = <double>[];
    var s = speed;
    while (s > 2.0) {
      factors.add(2.0);
      s /= 2.0;
    }
    while (s < 0.5) {
      factors.add(0.5);
      s /= 0.5; // == s * 2
    }
    factors.add(s);
    return factors;
  }

  /// Builds the chained `atempo` audio filter for [speed], e.g. speed 4.0 ->
  /// "atempo=2,atempo=2".
  static String atempoChain(double speed) =>
      atempoFactors(speed).map((f) => 'atempo=${fmt(f)}').join(',');

  /// Builds the FFmpeg command that retimes [input] to [speed]x. When
  /// [keepAudio] is false the audio is dropped (common for slow-motion);
  /// otherwise it is retimed with pitch correction via [atempoChain].
  static String speedCommand(
    String input,
    String output,
    double speed, {
    bool keepAudio = true,
  }) {
    final video = 'setpts=PTS/${fmt(speed)}';
    if (!keepAudio) {
      return '-y -i ${FfmpegCmd.q(input)} -filter_complex "[0:v]$video[v]" '
          '-map "[v]" -c:v libx264 -crf 20 -preset fast -an ${FfmpegCmd.q(output)}';
    }
    return '-y -i ${FfmpegCmd.q(input)} -filter_complex '
        '"[0:v]$video[v];[0:a]${atempoChain(speed)}[a]" '
        '-map "[v]" -map "[a]" -c:v libx264 -crf 20 -preset fast ${FfmpegCmd.q(output)}';
  }

  /// Retimes [input] to [speed]x and returns the output path (or null). If
  /// keeping audio fails (e.g. the clip has no audio track), it retries without
  /// audio so the operation still succeeds.
  static Future<String?> changeSpeed(
    String input,
    double speed, {
    bool keepAudio = true,
  }) async {
    final out = '${await getOutputDirectoryPath()}speed_${fmt(speed)}x.mp4';
    if (await FfmpegCmd.run(
        speedCommand(input, out, speed, keepAudio: keepAudio),
        tag: 'Speed')) {
      return out;
    }
    if (keepAudio) {
      if (await FfmpegCmd.run(
          speedCommand(input, out, speed, keepAudio: false),
          tag: 'Speed')) {
        return out;
      }
    }
    return null;
  }
}
