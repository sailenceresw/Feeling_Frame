import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../utils/storage_path.dart';
import 'caption_service.dart';

/// A recognised token (or word) with its start time in seconds.
class TranscribedToken {
  const TranscribedToken(this.text, this.start);

  final String text;
  final double start;
}

/// Abstraction over a speech-to-text backend so the audio pipeline and the UI
/// don't depend on any particular engine. The concrete on-device implementation
/// (sherpa-onnx) lives behind this interface and can be swapped/mocked.
abstract class SpeechRecognizer {
  /// Whether the recognizer is ready (model present/loaded).
  Future<bool> isReady();

  /// Transcribes mono [samples] captured at [sampleRate] Hz into timed tokens.
  Future<List<TranscribedToken>> transcribe(
    Float32List samples,
    int sampleRate,
  );
}

/// Speech-to-text pipeline: extract mono 16 kHz audio with FFmpeg, decode it to
/// normalised samples, run a [SpeechRecognizer], and turn the timed tokens into
/// [CaptionSegment]s ready for the Caption Studio.
///
/// The FFmpeg command, WAV decoding and token grouping are pure/static so they
/// are unit tested without a device or a model.
class SttService {
  /// Extracts mono 16 kHz signed-16-bit PCM WAV — the format ASR models expect.
  static String extractAudioCommand(String input, String output) =>
      '-y -i $input -vn -ac 1 -ar 16000 -c:a pcm_s16le $output';

  /// Decodes a 16-bit PCM WAV byte buffer into normalised (-1..1) mono samples.
  /// Locates the `data` sub-chunk rather than assuming a fixed 44-byte header.
  static Float32List wavToFloat32(Uint8List bytes) {
    final bd = bytes.buffer.asByteData(bytes.offsetInBytes);
    var offset = 12; // skip 'RIFF' + size + 'WAVE'
    var dataStart = -1;
    var dataLen = 0;
    while (offset + 8 <= bytes.length) {
      final id = String.fromCharCodes(bytes, offset, offset + 4);
      final size = bd.getUint32(offset + 4, Endian.little);
      if (id == 'data') {
        dataStart = offset + 8;
        dataLen = size;
        break;
      }
      offset += 8 + size + (size & 1); // chunks are word-aligned
    }
    if (dataStart < 0) {
      dataStart = 44; // fallback to the canonical header size
      dataLen = bytes.length - 44;
    }
    final end = (dataStart + dataLen) > bytes.length
        ? bytes.length
        : dataStart + dataLen;
    final count = ((end - dataStart) ~/ 2).clamp(0, 1 << 30);
    final out = Float32List(count);
    for (var i = 0; i < count; i++) {
      out[i] = bd.getInt16(dataStart + i * 2, Endian.little) / 32768.0;
    }
    return out;
  }

  /// Groups timed [tokens] into caption cues. A new cue is flushed once the
  /// text reaches [maxChars] or the cue spans [maxSpan] seconds. [audioEnd]
  /// closes the final cue.
  static List<CaptionSegment> groupTokensIntoCaptions(
    List<TranscribedToken> tokens,
    double audioEnd, {
    int maxChars = 42,
    double maxSpan = 3.5,
  }) {
    if (tokens.isEmpty) return [];
    final segments = <CaptionSegment>[];
    final buf = StringBuffer();
    var start = tokens.first.start;

    for (var i = 0; i < tokens.length; i++) {
      if (buf.isEmpty) start = tokens[i].start;
      buf.write(tokens[i].text);
      final nextStart =
          i + 1 < tokens.length ? tokens[i + 1].start : audioEnd;
      final span = nextStart - start;
      final last = i == tokens.length - 1;
      if (buf.length >= maxChars || span >= maxSpan || last) {
        final text = _tidy(buf.toString());
        if (text.isNotEmpty) {
          segments.add(CaptionSegment(
            start: start,
            end: nextStart <= start ? start + 0.5 : nextStart,
            text: text,
          ));
        }
        buf.clear();
      }
    }
    return segments;
  }

  /// Collapses BPE/word-piece markers and repeated whitespace into clean text.
  static String _tidy(String raw) {
    return raw
        .replaceAll('▁', ' ') // sentencepiece '▁' word boundary
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static Future<String?> _extractWav(String input) async {
    final out = '${await getOutputDirectoryPath()}stt_audio.wav';
    log('SttService extract: $input');
    final session = await FFmpegKit.execute(extractAudioCommand(input, out));
    if (ReturnCode.isSuccess(await session.getReturnCode())) return out;
    log('SttService extract failed: ${await session.getOutput()}');
    return null;
  }

  /// Full pipeline: [videoPath] -> WAV -> samples -> [recognizer] -> captions.
  /// Returns null if audio extraction fails or nothing is recognised.
  static Future<List<CaptionSegment>?> transcribeToCaptions(
    String videoPath,
    SpeechRecognizer recognizer,
  ) async {
    final wav = await _extractWav(videoPath);
    if (wav == null) return null;
    final bytes = await _readBytes(wav);
    if (bytes == null) return null;
    final samples = wavToFloat32(bytes);
    if (samples.isEmpty) return null;
    final tokens = await recognizer.transcribe(samples, 16000);
    if (tokens.isEmpty) return null;
    final audioEnd = samples.length / 16000.0;
    return groupTokensIntoCaptions(tokens, audioEnd);
  }

  static Future<Uint8List?> _readBytes(String path) async {
    try {
      return await File(path).readAsBytes();
    } catch (e) {
      log('SttService read error: $e');
      return null;
    }
  }
}
