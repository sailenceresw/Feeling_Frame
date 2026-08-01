import 'dart:developer';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/storage_path.dart';

/// Text-to-speech voiceover: synthesises narration on-device with the OS TTS
/// engine (flutter_tts), then mixes it over the video with FFmpeg.
///
/// The mix command is a pure static helper (unit tested); the synthesis uses a
/// native TTS engine, so runtime must be validated on a device.
class VoiceoverService {
  static String _n(double v) {
    var s = v.toStringAsFixed(3);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
    }
    return s.isEmpty ? '0' : s;
  }

  /// Mixes [voice] audio over [video]. Keeps the original audio (ducked by
  /// [originalVolume]) unless [keepOriginal] is false. Video is copied.
  static String mixCommand(
    String video,
    String voice,
    String output, {
    double voiceVolume = 1.0,
    double originalVolume = 0.6,
    bool keepOriginal = true,
  }) {
    final vv = voiceVolume.clamp(0.0, 4.0);
    final ov = originalVolume.clamp(0.0, 4.0);
    if (keepOriginal) {
      return '-y -i $video -i $voice -filter_complex '
          '"[0:a]volume=${_n(ov)}[o];[1:a]volume=${_n(vv)}[n];'
          '[o][n]amix=inputs=2:duration=first:dropout_transition=0[a]" '
          '-map 0:v -map "[a]" -c:v copy -c:a aac -shortest $output';
    }
    return '-y -i $video -i $voice -filter_complex '
        '"[1:a]volume=${_n(vv)}[a]" '
        '-map 0:v -map "[a]" -c:v copy -c:a aac -shortest $output';
  }

  static Future<bool> _run(String command) async {
    log('VoiceoverService command: $command');
    final session = await FFmpegKit.execute(command);
    final rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) return true;
    log('VoiceoverService failed: ${await session.getOutput()}');
    return false;
  }

  /// Synthesises [text] to a WAV file using the on-device TTS engine and returns
  /// its path (or null). [rate] 0..1, [pitch] 0.5..2.0.
  static Future<String?> synthesize(
    String text, {
    double rate = 0.5,
    double pitch = 1.0,
    String language = 'en-US',
  }) async {
    if (text.trim().isEmpty) return null;
    try {
      final tts = FlutterTts();
      await tts.setLanguage(language);
      await tts.setSpeechRate(rate);
      await tts.setPitch(pitch);
      await tts.awaitSynthCompletion(true);
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/voiceover.wav';
      final res = await tts.synthesizeToFile(text, path, true);
      final ok = res == 1 || res == '1' || res == true;
      if (ok && await File(path).exists()) return path;
      log('VoiceoverService.synthesize returned $res');
    } catch (e) {
      log('VoiceoverService.synthesize error: $e');
    }
    return null;
  }

  /// Full flow: synthesise [text] and lay it over [video]. Returns the output
  /// path (or null). Falls back to voice-only if the clip has no audio to mix.
  static Future<String?> addVoiceover(
    String video,
    String text, {
    double voiceVolume = 1.0,
    double originalVolume = 0.6,
    bool keepOriginal = true,
    double rate = 0.5,
    double pitch = 1.0,
  }) async {
    final voice = await synthesize(text, rate: rate, pitch: pitch);
    if (voice == null) return null;
    final out = '${await getOutputDirectoryPath()}voiceover.mp4';
    if (await _run(mixCommand(video, voice, out,
        voiceVolume: voiceVolume,
        originalVolume: originalVolume,
        keepOriginal: keepOriginal))) {
      return out;
    }
    if (keepOriginal &&
        await _run(mixCommand(video, voice, out,
            voiceVolume: voiceVolume, keepOriginal: false))) {
      return out;
    }
    return null;
  }
}
