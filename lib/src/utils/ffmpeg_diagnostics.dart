import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';

/// Captures a rolling buffer of the most recent FFmpeg log lines so a user can
/// share them if an operation fails — turning "it didn't work" into an actual
/// error we can act on. Enabled once at startup.
class FfmpegDiagnostics {
  FfmpegDiagnostics._();

  static final List<String> _lines = [];
  static const int _max = 600;

  /// Starts capturing FFmpeg logs. Safe to call once after FFmpegKit init.
  static void enable() {
    FFmpegKitConfig.enableLogCallback((log) {
      final msg = log.getMessage();
      _lines.add(msg);
      if (_lines.length > _max) {
        _lines.removeRange(0, _lines.length - _max);
      }
    });
  }

  /// The captured log text (most recent last).
  static String get text =>
      _lines.isEmpty ? 'No FFmpeg activity captured yet.' : _lines.join();

  static void clear() => _lines.clear();
}
