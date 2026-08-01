import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_mobile_app/src/services/split_screen_service.dart';

void main() {
  group('SplitScreenService.splitFilter', () {
    test('horizontal halves the width and hstacks', () {
      final f = SplitScreenService.splitFilter(1080, 1920);
      expect(f.contains('scale=540:1920'), isTrue);
      expect(f.contains('[l][r]hstack=inputs=2[v]'), isTrue);
    });

    test('vertical halves the height and vstacks', () {
      final f = SplitScreenService.splitFilter(1080, 1920, horizontal: false);
      expect(f.contains('scale=1080:960'), isTrue);
      expect(f.contains('[l][r]vstack=inputs=2[v]'), isTrue);
    });

    test('mixes both audio tracks', () {
      final f = SplitScreenService.splitFilter(1080, 1920);
      expect(f.contains('[0:a][1:a]amix=inputs=2:duration=shortest[a]'), isTrue);
    });
  });

  group('SplitScreenService.splitCommand', () {
    test('takes two inputs, maps v+a and is length-bound', () {
      final cmd = SplitScreenService.splitCommand('a.mp4', 'b.mp4', 'out.mp4',
          w: 1280, h: 720);
      expect(cmd.contains('-i a.mp4 -i b.mp4'), isTrue);
      expect(cmd.contains('-map "[v]" -map "[a]"'), isTrue);
      expect(cmd.contains('-shortest'), isTrue);
      expect(cmd.trim().endsWith('out.mp4'), isTrue);
    });
  });
}
