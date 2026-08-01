import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_mobile_app/src/services/audio_cleanup_service.dart';

void main() {
  group('AudioCleanupService.cleanupFilter', () {
    test('default chain: de-rumble, denoise, normalize in order', () {
      expect(
        AudioCleanupService.cleanupFilter(),
        'highpass=f=100,afftdn=nf=-25,loudnorm=I=-16:TP=-1.5:LRA=11',
      );
    });

    test('voice boost inserts a presence EQ after the high-pass', () {
      final f = AudioCleanupService.cleanupFilter(voiceBoost: true);
      expect(f.contains('highpass=f=100,equalizer=f=3000'), isTrue);
    });

    test('each option can be toggled independently', () {
      expect(
        AudioCleanupService.cleanupFilter(
          deRumble: false,
          denoise: true,
          normalize: false,
        ),
        'afftdn=nf=-25',
      );
    });

    test('all options off yields an empty chain', () {
      expect(
        AudioCleanupService.cleanupFilter(
          deRumble: false,
          voiceBoost: false,
          denoise: false,
          normalize: false,
        ),
        '',
      );
    });
  });

  group('AudioCleanupService.cleanupCommand', () {
    test('applies the -af chain and copies the video stream', () {
      final cmd =
          AudioCleanupService.cleanupCommand('in.mp4', 'out.mp4', 'afftdn=nf=-25');
      expect(cmd.contains('-af "afftdn=nf=-25"'), isTrue);
      expect(cmd.contains('-c:v copy'), isTrue);
      expect(cmd.contains('-c:a aac'), isTrue);
      expect(cmd.trim().endsWith('out.mp4'), isTrue);
    });
  });
}
