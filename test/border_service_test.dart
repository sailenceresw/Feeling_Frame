import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_mobile_app/src/services/border_service.dart';

void main() {
  group('BorderService.coloredFilter', () {
    test('pads the frame by the border on all sides', () {
      expect(BorderService.coloredFilter(40, 'white'),
          'pad=iw+80:ih+80:40:40:white');
    });

    test('negative border is treated as 0', () {
      expect(BorderService.coloredFilter(-5, 'black'),
          'pad=iw+0:ih+0:0:0:black');
    });
  });

  group('BorderService.blurredFilter', () {
    test('blurs an enlarged copy behind the centred original', () {
      final f = BorderService.blurredFilter(30);
      expect(f.contains('[0:v]scale=iw+60:ih+60,boxblur=20:5[bg]'), isTrue);
      expect(f.contains('[bg][0:v]overlay=30:30[v]'), isTrue);
    });
  });

  group('BorderService.borderCommand', () {
    test('colored uses -vf pad and copies audio', () {
      final cmd = BorderService.borderCommand('in.mp4', 'out.mp4',
          border: 40, color: 'red');
      expect(cmd.contains('-vf "pad=iw+80'), isTrue);
      expect(cmd.contains('-c:a copy'), isTrue);
      expect(cmd.trim().endsWith('out.mp4'), isTrue);
    });

    test('blurred uses filter_complex and maps [v]', () {
      final cmd = BorderService.borderCommand('in.mp4', 'out.mp4',
          border: 30, blurred: true);
      expect(cmd.contains('-filter_complex'), isTrue);
      expect(cmd.contains('-map "[v]"'), isTrue);
    });
  });
}
