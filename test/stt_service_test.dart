import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_mobile_app/src/services/stt_service.dart';

/// Builds a minimal 16-bit mono PCM WAV from [samples] (already in -1..1).
Uint8List _makeWav(List<double> samples, {int sampleRate = 16000}) {
  final dataLen = samples.length * 2;
  final bytes = BytesBuilder();
  final bd = ByteData(44);
  // RIFF header
  bd.setUint8(0, 0x52); // R
  bd.setUint8(1, 0x49); // I
  bd.setUint8(2, 0x46); // F
  bd.setUint8(3, 0x46); // F
  bd.setUint32(4, 36 + dataLen, Endian.little);
  bd.setUint8(8, 0x57); // W
  bd.setUint8(9, 0x41); // A
  bd.setUint8(10, 0x56); // V
  bd.setUint8(11, 0x45); // E
  // fmt chunk
  bd.setUint8(12, 0x66); // f
  bd.setUint8(13, 0x6d); // m
  bd.setUint8(14, 0x74); // t
  bd.setUint8(15, 0x20); // space
  bd.setUint32(16, 16, Endian.little);
  bd.setUint16(20, 1, Endian.little); // PCM
  bd.setUint16(22, 1, Endian.little); // mono
  bd.setUint32(24, sampleRate, Endian.little);
  bd.setUint32(28, sampleRate * 2, Endian.little);
  bd.setUint16(32, 2, Endian.little);
  bd.setUint16(34, 16, Endian.little);
  // data chunk
  bd.setUint8(36, 0x64); // d
  bd.setUint8(37, 0x61); // a
  bd.setUint8(38, 0x74); // t
  bd.setUint8(39, 0x61); // a
  bd.setUint32(40, dataLen, Endian.little);
  bytes.add(bd.buffer.asUint8List());
  final pcm = ByteData(dataLen);
  for (var i = 0; i < samples.length; i++) {
    pcm.setInt16(i * 2, (samples[i] * 32767).round(), Endian.little);
  }
  bytes.add(pcm.buffer.asUint8List());
  return bytes.toBytes();
}

void main() {
  group('SttService.extractAudioCommand', () {
    test('extracts mono 16kHz s16le WAV', () {
      final cmd = SttService.extractAudioCommand('in.mp4', 'out.wav');
      expect(cmd.contains('-ac 1'), isTrue);
      expect(cmd.contains('-ar 16000'), isTrue);
      expect(cmd.contains('-c:a pcm_s16le'), isTrue);
      expect(cmd.contains('-vn'), isTrue);
      expect(cmd.trim().endsWith('out.wav'), isTrue);
    });
  });

  group('SttService.wavToFloat32', () {
    test('decodes PCM samples back to normalised floats', () {
      final wav = _makeWav([0.0, 0.5, -0.5, 1.0, -1.0]);
      final out = SttService.wavToFloat32(wav);
      expect(out.length, 5);
      expect(out[0], closeTo(0.0, 1e-3));
      expect(out[1], closeTo(0.5, 1e-3));
      expect(out[2], closeTo(-0.5, 1e-3));
      expect(out[3], closeTo(1.0, 1e-3));
      expect(out[4], closeTo(-1.0, 1e-3));
    });

    test('finds the data chunk even with an extra chunk before it', () {
      // Prepend a 'LIST' chunk between fmt and data to shift the offset.
      final base = _makeWav([0.25, -0.25]);
      final builder = BytesBuilder();
      builder.add(base.sublist(0, 36)); // up to end of fmt
      final list = ByteData(12);
      list.setUint8(0, 0x4c); // L
      list.setUint8(1, 0x49); // I
      list.setUint8(2, 0x53); // S
      list.setUint8(3, 0x54); // T
      list.setUint32(4, 4, Endian.little);
      list.setUint32(8, 0, Endian.little);
      builder.add(list.buffer.asUint8List());
      builder.add(base.sublist(36)); // original data chunk
      final out = SttService.wavToFloat32(builder.toBytes());
      expect(out.length, 2);
      expect(out[0], closeTo(0.25, 1e-3));
      expect(out[1], closeTo(-0.25, 1e-3));
    });
  });

  group('SttService.groupTokensIntoCaptions', () {
    test('groups tokens into cues by span and closes on audio end', () {
      final tokens = [
        const TranscribedToken('▁Hello', 0.0),
        const TranscribedToken('▁world', 0.5),
        const TranscribedToken('▁this', 4.0),
        const TranscribedToken('▁is', 4.3),
      ];
      final segs =
          SttService.groupTokensIntoCaptions(tokens, 6.0, maxSpan: 3.5);
      expect(segs.length, greaterThanOrEqualTo(2));
      // sentencepiece '▁' markers become spaces and are tidied.
      expect(segs.first.text, 'Hello world');
      expect(segs.first.start, 0.0);
      expect(segs.last.end, 6.0);
    });

    test('empty tokens yield no captions', () {
      expect(SttService.groupTokensIntoCaptions([], 5.0), isEmpty);
    });

    test('flushes a cue when it reaches the character limit', () {
      final tokens = [
        for (var i = 0; i < 20; i++) TranscribedToken('word ', i * 0.1),
      ];
      final segs =
          SttService.groupTokensIntoCaptions(tokens, 2.0, maxChars: 20);
      expect(segs.length, greaterThan(1));
    });
  });
}
