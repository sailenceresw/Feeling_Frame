import 'dart:developer';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../utils/storage_path.dart';

/// Sets the clip's audio volume and optional independent audio fade in/out.
/// The video is copied (no re-encode). Command construction is pure/static.
class VolumeService {
  static String _n(double v) {
    var s = v.toStringAsFixed(3);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
    }
    return s.isEmpty ? '0' : s;
  }

  /// Builds the `-af` chain: a volume gain plus optional fades.
  static String audioFilter({
    double volume = 1.0,
    bool fadeIn = false,
    bool fadeOut = false,
    double totalSeconds = 0.0,
    double fadeSeconds = 1.0,
  }) {
    final v = volume.clamp(0.0, 4.0);
    final parts = <String>['volume=${_n(v)}'];
    if (fadeIn) parts.add('afade=t=in:st=0:d=${_n(fadeSeconds)}');
    if (fadeOut && totalSeconds > 0) {
      final start = (totalSeconds - fadeSeconds).clamp(0.0, double.maxFinite);
      parts.add('afade=t=out:st=${_n(start)}:d=${_n(fadeSeconds)}');
    }
    return parts.join(',');
  }

  static String volumeCommand(
    String input,
    String output, {
    double volume = 1.0,
    bool fadeIn = false,
    bool fadeOut = false,
    double totalSeconds = 0.0,
    double fadeSeconds = 1.0,
  }) {
    final af = audioFilter(
      volume: volume,
      fadeIn: fadeIn,
      fadeOut: fadeOut,
      totalSeconds: totalSeconds,
      fadeSeconds: fadeSeconds,
    );
    return '-y -i $input -af "$af" -c:v copy -c:a aac $output';
  }

  static Future<bool> _run(String command) async {
    log('VolumeService command: $command');
    final session = await FFmpegKit.execute(command);
    final rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) return true;
    log('VolumeService failed: ${await session.getOutput()}');
    return false;
  }

  static Future<String?> apply(
    String input, {
    double volume = 1.0,
    bool fadeIn = false,
    bool fadeOut = false,
    double totalSeconds = 0.0,
    double fadeSeconds = 1.0,
  }) async {
    final out = '${await getOutputDirectoryPath()}volume.mp4';
    return await _run(volumeCommand(
      input,
      out,
      volume: volume,
      fadeIn: fadeIn,
      fadeOut: fadeOut,
      totalSeconds: totalSeconds,
      fadeSeconds: fadeSeconds,
    ))
        ? out
        : null;
  }
}
