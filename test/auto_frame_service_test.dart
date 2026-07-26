import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_mobile_app/src/services/auto_frame_service.dart';

void main() {
  group('AutoFrameService.smartCropRect', () {
    test('vertical crop from a landscape frame is full height, even dims', () {
      // 1920x1080 -> 9:16 crop should be 608x1080 (height-limited)
      final r = AutoFrameService.smartCropRect(
        subjectCx: 960,
        subjectCy: 540,
        frameW: 1920,
        frameH: 1080,
        targetAspect: 9 / 16,
      );
      final x = r[0], y = r[1], w = r[2], h = r[3];
      expect(h, 1080);
      expect(w, 608); // round(1080*9/16)=608, already even
      expect(w.isEven, true);
      expect(h.isEven, true);
      expect(x, 960 - 608 ~/ 2); // centered on subject
      expect(y, 0);
    });

    test('clamps the crop to the left edge when subject is near it', () {
      final r = AutoFrameService.smartCropRect(
        subjectCx: 50,
        subjectCy: 540,
        frameW: 1920,
        frameH: 1080,
        targetAspect: 9 / 16,
      );
      expect(r[0], 0);
    });

    test('clamps the crop to the right edge when subject is near it', () {
      final r = AutoFrameService.smartCropRect(
        subjectCx: 1900,
        subjectCy: 540,
        frameW: 1920,
        frameH: 1080,
        targetAspect: 9 / 16,
      );
      expect(r[0] + r[2], 1920);
    });

    test('crop never exceeds the frame', () {
      final r = AutoFrameService.smartCropRect(
        subjectCx: 500,
        subjectCy: 500,
        frameW: 1000,
        frameH: 1000,
        targetAspect: 9 / 16,
      );
      final x = r[0], y = r[1], w = r[2], h = r[3];
      expect(x >= 0, true);
      expect(y >= 0, true);
      expect(x + w <= 1000, true);
      expect(y + h <= 1000, true);
    });
  });

  group('AutoFrameService.autoFrameCommand', () {
    test('crops to the rect and scales to the target height', () {
      final cmd = AutoFrameService.autoFrameCommand(
          'in.mp4', 'out.mp4', [100, 0, 608, 1080],
          outH: 1280);
      expect(cmd, contains('crop=608:1080:100:0'));
      expect(cmd, contains('scale=-2:1280'));
      expect(cmd, contains('-c:a copy'));
      expect(cmd, endsWith('out.mp4'));
    });
  });
}
