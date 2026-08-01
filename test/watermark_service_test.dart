import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_mobile_app/src/services/watermark_service.dart';

void main() {
  group('WatermarkService.overlayXY', () {
    test('positions the watermark in each corner with the margin', () {
      expect(WatermarkService.overlayXY(WatermarkService.topLeft, 20), '20:20');
      expect(WatermarkService.overlayXY(WatermarkService.topRight, 20),
          'W-w-20:20');
      expect(WatermarkService.overlayXY(WatermarkService.bottomLeft, 20),
          '20:H-h-20');
      expect(WatermarkService.overlayXY(WatermarkService.bottomRight, 20),
          'W-w-20:H-h-20');
    });
  });

  group('WatermarkService.watermarkWidth', () {
    test('is a fraction of the main width, rounded to even, min 2', () {
      expect(WatermarkService.watermarkWidth(1000, 0.18), 180);
      expect(WatermarkService.watermarkWidth(999, 0.18), 180); // 179.8 -> 180
      expect(WatermarkService.watermarkWidth(1, 0.18), 2);
    });
  });

  group('WatermarkService.watermarkCommand', () {
    test('scales, applies opacity via colorchannelmixer, and overlays', () {
      final cmd = WatermarkService.watermarkCommand(
        'v.mp4',
        'logo.png',
        'out.mp4',
        mainW: 1000,
        sizeFraction: 0.18,
        opacity: 0.5,
        corner: WatermarkService.bottomRight,
        margin: 30,
      );
      expect(cmd.contains('[1:v]scale=180:-1,format=rgba'), isTrue);
      expect(cmd.contains('colorchannelmixer=aa=0.5[wm]'), isTrue);
      expect(cmd.contains('[0:v][wm]overlay=W-w-30:H-h-30[v]'), isTrue);
      expect(cmd.contains('-map "[v]"'), isTrue);
      expect(cmd.contains('-map 0:a?'), isTrue);
      expect(cmd.contains('-c:a copy'), isTrue);
      expect(cmd.trim().endsWith('out.mp4'), isTrue);
    });

    test('clamps opacity into 0..1', () {
      final cmd = WatermarkService.watermarkCommand(
        'v.mp4',
        'logo.png',
        'out.mp4',
        mainW: 1000,
        opacity: 5.0,
      );
      expect(cmd.contains('colorchannelmixer=aa=1[wm]'), isTrue);
    });
  });
}
