import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import 'stt_service.dart';

/// Concrete on-device [SpeechRecognizer] using sherpa-onnx (ONNX Runtime) with
/// the Whisper tiny.en model. ONNX Runtime processes raw audio samples, so this
/// has **no FFmpeg dependency** and does not conflict with ffmpeg_kit.
///
/// The model (~40 MB) is downloaded and cached on first use. Because it relies
/// on native ONNX libraries and a downloaded model, it must be validated on a
/// real device — the build is CI-checked but runtime is device-verified.
class SherpaSpeechRecognizer implements SpeechRecognizer {
  SherpaSpeechRecognizer({this.onModelProgress});

  /// Reports model-download progress in 0..1 (only while downloading).
  final void Function(double fraction)? onModelProgress;

  static const String modelUrl =
      'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/'
      'sherpa-onnx-whisper-tiny.en.tar.bz2';
  static const String _dirName = 'sherpa-onnx-whisper-tiny.en';
  static const String _encoderName = 'tiny.en-encoder.int8.onnx';
  static const String _decoderName = 'tiny.en-decoder.int8.onnx';
  static const String _tokensName = 'tiny.en-tokens.txt';

  sherpa.OfflineRecognizer? _recognizer;
  bool _bindingsInited = false;

  Future<Directory> _modelDir() async {
    final base = await getApplicationSupportDirectory();
    return Directory('${base.path}/$_dirName');
  }

  Future<Map<String, String>?> _resolveModelFiles() async {
    final dir = await _modelDir();
    final encoder = File('${dir.path}/$_encoderName');
    final decoder = File('${dir.path}/$_decoderName');
    final tokens = File('${dir.path}/$_tokensName');
    if (await encoder.exists() &&
        await decoder.exists() &&
        await tokens.exists()) {
      return {
        'encoder': encoder.path,
        'decoder': decoder.path,
        'tokens': tokens.path,
      };
    }
    return null;
  }

  @override
  Future<bool> isReady() async => (await _resolveModelFiles()) != null;

  /// Downloads and extracts the model on first use. Returns true when the model
  /// files are present.
  Future<bool> ensureModel() async {
    if (await _resolveModelFiles() != null) return true;
    try {
      final dir = await _modelDir();
      if (!await dir.exists()) await dir.create(recursive: true);

      final request = http.Request('GET', Uri.parse(modelUrl));
      final response = await request.send();
      if (response.statusCode != 200) {
        log('SherpaSpeechRecognizer: model download HTTP ${response.statusCode}');
        return false;
      }
      final total = response.contentLength ?? 0;
      final bytes = <int>[];
      var received = 0;
      await for (final chunk in response.stream) {
        bytes.addAll(chunk);
        received += chunk.length;
        if (total > 0) onModelProgress?.call(received / total);
      }

      // .tar.bz2 -> tar -> flat files.
      final tarBytes = BZip2Decoder().decodeBytes(bytes);
      final archive = TarDecoder().decodeBytes(tarBytes);
      for (final entry in archive) {
        if (!entry.isFile) continue;
        final name = entry.name.split('/').last;
        if (name.isEmpty) continue;
        await File('${dir.path}/$name').writeAsBytes(entry.content as List<int>);
      }
      return (await _resolveModelFiles()) != null;
    } catch (e) {
      log('SherpaSpeechRecognizer.ensureModel error: $e');
      return false;
    }
  }

  Future<sherpa.OfflineRecognizer?> _recognizerOrNull() async {
    if (_recognizer != null) return _recognizer;
    final files = await _resolveModelFiles();
    if (files == null) return null;
    if (!_bindingsInited) {
      sherpa.initBindings();
      _bindingsInited = true;
    }
    final config = sherpa.OfflineRecognizerConfig(
      model: sherpa.OfflineModelConfig(
        whisper: sherpa.OfflineWhisperModelConfig(
          encoder: files['encoder']!,
          decoder: files['decoder']!,
          tailPaddings: 2000,
          enableTokenTimestamps: true,
        ),
        tokens: files['tokens']!,
        numThreads: 2,
        debug: false,
        modelType: 'whisper',
      ),
    );
    _recognizer = sherpa.OfflineRecognizer(config);
    return _recognizer;
  }

  @override
  Future<List<TranscribedToken>> transcribe(
    Float32List samples,
    int sampleRate,
  ) async {
    final recognizer = await _recognizerOrNull();
    if (recognizer == null) return [];

    final result = <TranscribedToken>[];
    // Whisper works on ~30s windows; process the audio in 25s chunks and offset
    // each chunk's token times by where the chunk starts.
    const windowSeconds = 25;
    final window = windowSeconds * sampleRate;
    for (var offset = 0; offset < samples.length; offset += window) {
      final end = (offset + window) > samples.length
          ? samples.length
          : offset + window;
      final chunk = Float32List.sublistView(samples, offset, end);
      final baseTime = offset / sampleRate;
      final chunkDuration = (end - offset) / sampleRate;

      final stream = recognizer.createStream();
      stream.acceptWaveform(samples: chunk, sampleRate: sampleRate);
      recognizer.decode(stream);
      final decoded = recognizer.getResult(stream);
      stream.free();

      final tokens = decoded.tokens;
      final times = decoded.timestamps;
      for (var i = 0; i < tokens.length; i++) {
        final t = i < times.length
            ? times[i]
            : (tokens.isEmpty ? 0.0 : chunkDuration * i / tokens.length);
        result.add(TranscribedToken(tokens[i], baseTime + t));
      }
    }
    return result;
  }

  void dispose() {
    _recognizer?.free();
    _recognizer = null;
  }
}
