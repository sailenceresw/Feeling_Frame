import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_mobile_app/src/services/advanced_edit_service.dart';

void main() {
  group('AdvancedEditService command builders', () {
    test('gifCommand includes input, fps/scale and loop', () {
      final cmd = AdvancedEditService.gifCommand('in.mp4', 'out.gif');
      expect(cmd, contains('-i in.mp4'));
      expect(cmd, contains('fps=12'));
      expect(cmd, contains('-loop 0'));
      expect(cmd, endsWith('out.gif'));
    });

    test('extractAudioCommand drops video and encodes mp3', () {
      final cmd = AdvancedEditService.extractAudioCommand('in.mp4', 'a.mp3');
      expect(cmd, contains('-vn'));
      expect(cmd, contains('libmp3lame'));
      expect(cmd, endsWith('a.mp3'));
    });

    test('boomerangCommand reverses and concats forward+reverse', () {
      final cmd = AdvancedEditService.boomerangCommand('in.mp4', 'out.mp4');
      expect(cmd, contains('reverse'));
      expect(cmd, contains('concat=n=2:v=1:a=0'));
      expect(cmd, contains('-an'));
    });

    test('fadeCommand computes the out-fade start from total duration', () {
      final cmd =
          AdvancedEditService.fadeCommand('in.mp4', 'out.mp4', 10, fade: 1.0);
      // out-fade should start at 10 - 1 = 9.00
      expect(cmd, contains('fade=t=out:st=9.00:d=1.0'));
      expect(cmd, contains('afade=t=out:st=9.00:d=1.0'));
    });

    test('fadeCommand clamps out-fade start to zero for very short clips', () {
      final cmd =
          AdvancedEditService.fadeCommand('in.mp4', 'out.mp4', 0.5, fade: 1.0);
      // 0.5 - 1.0 would be negative; must clamp to 0.00
      expect(cmd, contains('fade=t=out:st=0.00:d=1.0'));
    });
  });
}
