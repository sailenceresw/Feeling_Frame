import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_mobile_app/src/services/fade_service.dart';

void main() {
  group('FadeService.videoFade', () {
    test('fades in at 0 and out before the end', () {
      final f = FadeService.videoFade(10, 1);
      expect(f, 'fade=t=in:st=0:d=1,fade=t=out:st=9:d=1');
    });

    test('in-only omits the out fade', () {
      final f = FadeService.videoFade(10, 1, fadeOut: false);
      expect(f, 'fade=t=in:st=0:d=1');
    });

    test('out-only omits the in fade', () {
      final f = FadeService.videoFade(10, 2, fadeIn: false);
      expect(f, 'fade=t=out:st=8:d=2');
    });
  });

  group('FadeService.audioFade', () {
    test('mirrors the video fade with afade', () {
      expect(FadeService.audioFade(10, 1),
          'afade=t=in:st=0:d=1,afade=t=out:st=9:d=1');
    });
  });

  group('FadeService.fadeCommand', () {
    test('applies both video and audio fades', () {
      final cmd = FadeService.fadeCommand('in.mp4', 'out.mp4',
          totalSeconds: 8, fadeSeconds: 1);
      expect(cmd.contains('-vf "fade=t=in:st=0:d=1,fade=t=out:st=7:d=1"'),
          isTrue);
      expect(cmd.contains('-af "afade=t=in'), isTrue);
      expect(cmd.trim().endsWith('out.mp4'), isTrue);
    });
  });
}
