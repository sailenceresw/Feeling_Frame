import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_mobile_app/src/services/crop_service.dart';

void main() {
  group('CropService.cropCommand', () {
    test('crops to the region and copies audio', () {
      final cmd = CropService.cropCommand('in.mp4', 'out.mp4',
          rx: 100, ry: 50, rw: 400, rh: 300);
      expect(cmd.contains('-vf "crop=400:300:100:50"'), isTrue);
      expect(cmd.contains('-c:a copy'), isTrue);
      expect(cmd.trim().endsWith('out.mp4'), isTrue);
    });

    test('rounds odd region size to even', () {
      final cmd = CropService.cropCommand('in.mp4', 'out.mp4',
          rx: 0, ry: 0, rw: 401, rh: 301);
      expect(cmd.contains('crop=400:300:0:0'), isTrue);
    });
  });
}
