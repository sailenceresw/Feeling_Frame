import 'dart:developer';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import 'ffmpeg_diagnostics.dart';

/// Helpers that make FFmpeg commands reliable on real devices.
///
/// Android/iOS paths from the gallery or cache often contain spaces or
/// special characters. Unquoted paths are the #1 reason FFmpeg "does nothing"
/// on device while unit tests (which use clean temp paths) stay green.
class FfmpegCmd {
  FfmpegCmd._();

  /// Quote a filesystem path for safe use inside an FFmpeg command string.
  static String q(String path) {
    final escaped = path.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
    return '"$escaped"';
  }

  /// Run [command], log diagnostics, return true on success.
  /// On failure, records the FFmpeg output so Settings → Share diagnostics
  /// actually contains something useful.
  static Future<bool> run(String command, {String tag = 'FFmpeg'}) async {
    log('$tag command: $command');
    FfmpegDiagnostics.log('$tag start: $command');
    final session = await FFmpegKit.execute(command);
    final code = await session.getReturnCode();
    final output = await session.getOutput() ?? '';
    if (ReturnCode.isSuccess(code)) {
      FfmpegDiagnostics.log('$tag ok');
      return true;
    }
    log('$tag failed rc=$code\n$output');
    FfmpegDiagnostics.log('$tag FAILED rc=$code\n$output');
    return false;
  }

  /// Same as [run] but returns a short human-readable error (or null on success).
  static Future<String?> runOrError(String command,
      {String tag = 'FFmpeg'}) async {
    log('$tag command: $command');
    FfmpegDiagnostics.log('$tag start: $command');
    final session = await FFmpegKit.execute(command);
    final code = await session.getReturnCode();
    final output = await session.getOutput() ?? '';
    if (ReturnCode.isSuccess(code)) {
      FfmpegDiagnostics.log('$tag ok');
      return null;
    }
    log('$tag failed rc=$code\n$output');
    FfmpegDiagnostics.log('$tag FAILED rc=$code\n$output');
    // Surface the last meaningful line so the snackbar is not empty.
    final lines = output
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final last = lines.isEmpty ? 'FFmpeg error $code' : lines.last;
    return last.length > 120 ? '${last.substring(0, 117)}...' : last;
  }
}
