import 'dart:developer';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../utils/storage_path.dart';

/// One-tap audio clean-up built on standard FFmpeg audio filters:
///
/// * de-rumble  — `highpass` removes low-frequency hum/wind.
/// * voice boost — a gentle presence EQ lift around 3 kHz.
/// * denoise    — `afftdn` adaptive FFT noise reduction (hiss/background).
/// * normalize  — `loudnorm` to a broadcast-style target loudness.
///
/// The video stream is copied untouched (fast); only the audio is re-encoded.
/// Command construction is a pure static helper for unit testing.
class AudioCleanupService {
  /// Builds the ordered `-af` chain for the selected options (empty if none).
  static String cleanupFilter({
    bool deRumble = true,
    bool voiceBoost = false,
    bool denoise = true,
    bool normalize = true,
  }) {
    final parts = <String>[];
    if (deRumble) parts.add('highpass=f=100');
    if (voiceBoost) parts.add('equalizer=f=3000:t=q:w=1:g=3');
    if (denoise) parts.add('afftdn=nf=-25');
    if (normalize) parts.add('loudnorm=I=-16:TP=-1.5:LRA=11');
    return parts.join(',');
  }

  /// The full FFmpeg command applying audio filter chain [af] to [input].
  static String cleanupCommand(String input, String output, String af) =>
      '-y -i $input -af "$af" -c:v copy -c:a aac $output';

  static Future<bool> _run(String command) async {
    log('AudioCleanupService command: $command');
    final session = await FFmpegKit.execute(command);
    final rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) return true;
    log('AudioCleanupService failed: ${await session.getOutput()}');
    return false;
  }

  /// Cleans up the audio and returns the output path (or null). Returns null
  /// with no work done if every option is disabled.
  static Future<String?> cleanup(
    String input, {
    bool deRumble = true,
    bool voiceBoost = false,
    bool denoise = true,
    bool normalize = true,
  }) async {
    final af = cleanupFilter(
      deRumble: deRumble,
      voiceBoost: voiceBoost,
      denoise: denoise,
      normalize: normalize,
    );
    if (af.isEmpty) return null;
    final out = '${await getOutputDirectoryPath()}audio_cleaned.mp4';
    return await _run(cleanupCommand(input, out, af)) ? out : null;
  }
}
