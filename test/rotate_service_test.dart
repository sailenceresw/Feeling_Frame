import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_mobile_app/src/services/rotate_service.dart';

void main() {
  group('RotateService.rotateQuarterCommand', () {
    test('maps quarter turns to the right transpose chain', () {
      expect(RotateService.rotateQuarterCommand('i.mp4', 'o.mp4', 1)
          .contains('-vf transpose=1 '), isTrue);
      expect(RotateService.rotateQuarterCommand('i.mp4', 'o.mp4', 2)
          .contains('-vf transpose=1,transpose=1'), isTrue);
      expect(RotateService.rotateQuarterCommand('i.mp4', 'o.mp4', 3)
          .contains('-vf transpose=2'), isTrue);
    });

    test('0 (or a multiple of 4) is a stream-copy no-op', () {
      final cmd = RotateService.rotateQuarterCommand('i.mp4', 'o.mp4', 4);
      expect(cmd.contains('-c copy'), isTrue);
      expect(cmd.contains('transpose'), isFalse);
    });
  });

  group('RotateService.straightenScale', () {
    test('is 1.0 at zero degrees', () {
      expect(RotateService.straightenScale(1920, 1080, 0), closeTo(1.0, 1e-9));
    });

    test('grows with the tilt angle so corners stay covered', () {
      final s = RotateService.straightenScale(1920, 1080, 10);
      expect(s, greaterThan(1.0));
      // cos(10°)+ (16/9)*sin(10°) ~ 1.294
      expect(s, closeTo(1.294, 0.01));
    });
  });

  group('RotateService.straightenFilter', () {
    test('scales up, rotates and crops back to the frame', () {
      final f = RotateService.straightenFilter(1920, 1080, 5);
      expect(f.contains('scale=iw*'), isTrue);
      expect(f.contains('rotate='), isTrue);
      expect(f.contains('crop=1920:1080'), isTrue);
    });
  });
}
