import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_mobile_app/src/services/blur_region_service.dart';

void main() {
  group('BlurRegionService.regionFilter', () {
    test('blur mode crops the region and box-blurs it, then overlays back', () {
      final f = BlurRegionService.regionFilter(100, 50, 200, 120);
      expect(f.contains('[0:v]crop=200:120:100:50,boxblur=20:3[fg]'), isTrue);
      expect(f.contains('[0:v][fg]overlay=100:50[v]'), isTrue);
    });

    test('pixelate mode downscales then nearest-neighbour upscales', () {
      final f = BlurRegionService.regionFilter(0, 0, 200, 200,
          mode: RegionMode.pixelate);
      expect(f.contains('scale=iw/12:ih/12:flags=neighbor'), isTrue);
      expect(f.contains('scale=200:200:flags=neighbor'), isTrue);
    });

    test('odd region dimensions are rounded to even', () {
      final f = BlurRegionService.regionFilter(10, 10, 201, 121);
      expect(f.contains('crop=200:120:10:10'), isTrue);
    });
  });

  group('BlurRegionService.regionCommand', () {
    test('maps the composited video and keeps audio', () {
      final cmd =
          BlurRegionService.regionCommand('in.mp4', 'out.mp4', 0, 0, 100, 100);
      expect(cmd.contains('-map "[v]"'), isTrue);
      expect(cmd.contains('-map 0:a?'), isTrue);
      expect(cmd.contains('-c:a copy'), isTrue);
      expect(cmd.trim().endsWith('out.mp4'), isTrue);
    });
  });
}
