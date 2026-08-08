import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_mobile_app/src/services/voiceover_service.dart';

void main() {
  group('VoiceoverService.mixCommand', () {
    test('keeps + ducks the original and mixes the narration', () {
      final cmd = VoiceoverService.mixCommand(
        'v.mp4',
        'voice.wav',
        'out.mp4',
        voiceVolume: 1.0,
        originalVolume: 0.5,
      );
      expect(cmd.contains('[0:a]volume=0.5[o]'), isTrue);
      expect(cmd.contains('[1:a]volume=1[n]'), isTrue);
      expect(cmd.contains('[o][n]amix=inputs=2:duration=first'), isTrue);
      expect(cmd.contains('-map 0:v'), isTrue);
      expect(cmd.contains('-c:v copy'), isTrue);
      expect(cmd.contains('-shortest'), isTrue);
      expect(cmd.trim().endsWith('out.mp4'), isTrue);
    });

    test('replace mode drops the original audio', () {
      final cmd = VoiceoverService.mixCommand('v.mp4', 'voice.wav', 'out.mp4',
          keepOriginal: false);
      expect(cmd.contains('amix'), isFalse);
      expect(cmd.contains('[0:a]'), isFalse);
      expect(cmd.contains('[1:a]volume='), isTrue);
    });

    test('clamps volumes to 0..4', () {
      final cmd = VoiceoverService.mixCommand('v.mp4', 'voice.wav', 'out.mp4',
          voiceVolume: 9, originalVolume: 9);
      expect(cmd.contains('[0:a]volume=4[o]'), isTrue);
      expect(cmd.contains('[1:a]volume=4[n]'), isTrue);
    });
  });
}
