import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_mobile_app/src/services/compress_service.dart';

void main() {
  group('CompressService.crfFor', () {
    test('smaller-file quality uses a higher CRF', () {
      expect(CompressService.crfFor(CompressQuality.high),
          lessThan(CompressService.crfFor(CompressQuality.balanced)));
      expect(CompressService.crfFor(CompressQuality.balanced),
          lessThan(CompressService.crfFor(CompressQuality.small)));
    });
  });

  group('CompressService.targetHeight (downscale-only)', () {
    test('no scaling when there is no cap', () {
      expect(CompressService.targetHeight(1080, 0), 0);
    });

    test('no scaling when the source is already at/below the cap', () {
      expect(CompressService.targetHeight(720, 720), 0);
      expect(CompressService.targetHeight(480, 720), 0);
    });

    test('scales down a taller source to an even cap height', () {
      expect(CompressService.targetHeight(1080, 720), 720);
      expect(CompressService.targetHeight(1080, 481), 480); // odd -> even
    });
  });

  group('CompressService.compressCommand', () {
    test('re-encodes at the given CRF without scaling when height is 0', () {
      final cmd =
          CompressService.compressCommand('in.mp4', 'out.mp4', crf: 28);
      expect(cmd.contains('-crf 28'), isTrue);
      expect(cmd.contains('scale='), isFalse);
      expect(cmd.contains('-c:v libx264'), isTrue);
      expect(cmd.contains('-c:a aac'), isTrue);
      expect(cmd.trim().endsWith('out.mp4'), isTrue);
    });

    test('adds a downscale filter when height is set', () {
      final cmd = CompressService.compressCommand('in.mp4', 'out.mp4',
          crf: 32, height: 720);
      expect(cmd.contains('-vf scale=-2:720'), isTrue);
      expect(cmd.contains('-crf 32'), isTrue);
    });
  });
}
