import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_mobile_app/src/services/speed_service.dart';

double _product(List<double> xs) => xs.fold(1.0, (a, b) => a * b);

void main() {
  group('SpeedService.atempoFactors', () {
    for (final speed in [0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 3.0, 4.0]) {
      test('factors multiply back to $speed and each stay within 0.5..2.0', () {
        final f = SpeedService.atempoFactors(speed);
        expect(_product(f), closeTo(speed, 1e-9));
        for (final x in f) {
          expect(x, greaterThanOrEqualTo(0.5));
          expect(x, lessThanOrEqualTo(2.0));
        }
      });
    }

    test('extreme fast speed chains multiple atempo stages', () {
      expect(SpeedService.atempoFactors(4.0), [2.0, 2.0]);
    });

    test('extreme slow speed chains multiple atempo stages', () {
      expect(SpeedService.atempoFactors(0.25), [0.5, 0.5]);
    });

    test('a mid speed is a single factor', () {
      expect(SpeedService.atempoFactors(1.5), [1.5]);
    });
  });

  group('SpeedService.atempoChain', () {
    test('joins factors with commas', () {
      expect(SpeedService.atempoChain(4.0), 'atempo=2,atempo=2');
      expect(SpeedService.atempoChain(1.5), 'atempo=1.5');
    });
  });

  group('SpeedService.speedCommand', () {
    test('retimes video with setpts and audio with atempo when keeping audio',
        () {
      final cmd = SpeedService.speedCommand('in.mp4', 'out.mp4', 2.0);
      expect(cmd.contains('[0:v]setpts=PTS/2[v]'), isTrue);
      expect(cmd.contains('[0:a]atempo=2[a]'), isTrue);
      expect(cmd.contains('-map "[v]"'), isTrue);
      expect(cmd.contains('-map "[a]"'), isTrue);
      expect(cmd.contains('-an'), isFalse);
    });

    test('drops audio when keepAudio is false', () {
      final cmd =
          SpeedService.speedCommand('in.mp4', 'out.mp4', 0.5, keepAudio: false);
      expect(cmd.contains('[0:v]setpts=PTS/0.5[v]'), isTrue);
      expect(cmd.contains('-an'), isTrue);
      expect(cmd.contains('atempo'), isFalse);
      expect(cmd.contains('[0:a]'), isFalse);
    });

    test('re-encodes video and ends with the output path', () {
      final cmd = SpeedService.speedCommand('in.mp4', 'out.mp4', 4.0);
      expect(cmd.contains('-c:v libx264'), isTrue);
      // 4x needs a two-stage atempo chain
      expect(cmd.contains('[0:a]atempo=2,atempo=2[a]'), isTrue);
      expect(cmd.trim().endsWith('out.mp4'), isTrue);
    });
  });
}
