import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_mobile_app/src/services/volume_service.dart';

void main() {
  group('VolumeService.audioFilter', () {
    test('just a volume gain by default', () {
      expect(VolumeService.audioFilter(volume: 0.5), 'volume=0.5');
    });

    test('adds fades when requested', () {
      final f = VolumeService.audioFilter(
        volume: 1.0,
        fadeIn: true,
        fadeOut: true,
        totalSeconds: 10,
        fadeSeconds: 1,
      );
      expect(f.contains('afade=t=in:st=0:d=1'), isTrue);
      expect(f.contains('afade=t=out:st=9:d=1'), isTrue);
    });

    test('clamps volume to 0..4', () {
      expect(VolumeService.audioFilter(volume: 9).startsWith('volume=4'), isTrue);
    });

    test('fade-out needs a known duration', () {
      final f = VolumeService.audioFilter(volume: 1, fadeOut: true);
      expect(f.contains('afade=t=out'), isFalse);
    });
  });

  group('VolumeService.volumeCommand', () {
    test('applies the -af chain and copies the video stream', () {
      final cmd = VolumeService.volumeCommand('in.mp4', 'out.mp4', volume: 0.8);
      expect(cmd.contains('-af "volume=0.8"'), isTrue);
      expect(cmd.contains('-c:v copy'), isTrue);
      expect(cmd.trim().endsWith('out.mp4'), isTrue);
    });
  });
}
