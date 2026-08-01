import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_mobile_app/src/services/meme_service.dart';

void main() {
  group('MemeService.memeFilter', () {
    test('top and bottom become white bordered drawtext', () {
      final f = MemeService.memeFilter('/f.ttf',
          top: 'WHEN YOU', bottom: 'SHIP IT', fontSize: 60);
      expect(f.contains("text='WHEN YOU'"), isTrue);
      expect(f.contains("text='SHIP IT'"), isTrue);
      expect(f.contains('fontcolor=white'), isTrue);
      expect(f.contains('borderw=4:bordercolor=black'), isTrue);
      expect(f.contains('y=h*0.04'), isTrue); // top
      expect(f.contains('y=h-text_h-h*0.04'), isTrue); // bottom
    });

    test('only one line still works', () {
      final f = MemeService.memeFilter('/f.ttf', top: 'ONLY TOP');
      expect(f.contains("text='ONLY TOP'"), isTrue);
      expect(f.split('drawtext').length, 2); // one drawtext
    });

    test('no text yields a passthrough null filter', () {
      expect(MemeService.memeFilter('/f.ttf'), 'null');
    });
  });

  group('MemeService.memeCommand', () {
    test('wraps the filter and copies audio', () {
      final cmd = MemeService.memeCommand('in.mp4', 'out.mp4', 'drawtext=x');
      expect(cmd.contains('-vf "drawtext=x"'), isTrue);
      expect(cmd.contains('-c:a copy'), isTrue);
      expect(cmd.trim().endsWith('out.mp4'), isTrue);
    });
  });
}
