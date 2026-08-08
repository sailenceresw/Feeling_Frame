import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:flutter/foundation.dart';

/// Captures a rolling buffer of recent FFmpeg logs **and** app-level errors so a
/// user can share them if an operation fails — turning "it didn't work" into an
/// actual error we can act on. Enabled once at startup.
class FfmpegDiagnostics {
  FfmpegDiagnostics._();

  static final List<String> _lines = [];
  static const int _max = 800;

  static void _push(String line) {
    _lines.add(line);
    if (_lines.length > _max) {
      _lines.removeRange(0, _lines.length - _max);
    }
  }

  /// Records an app-level diagnostic line (e.g. a failed AI/caption step).
  static void log(String message) {
    final t = DateTime.now().toIso8601String().substring(11, 19);
    _push('[$t] $message');
  }

  /// Starts capturing FFmpeg logs and uncaught Flutter framework errors.
  static void enable() {
    FFmpegKitConfig.enableLogCallback((log) {
      _push(log.getMessage());
    });
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      log('FlutterError: ${details.exceptionAsString()}');
      previous?.call(details);
    };
  }

  /// The captured diagnostics text (most recent last).
  static String get text =>
      _lines.isEmpty ? 'No activity captured yet.' : _lines.join('\n');

  static void clear() => _lines.clear();
}
