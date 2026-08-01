import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_mobile_app/src/services/thumbnail_service.dart';

void main() {
  group('ThumbnailService.thumbnailCommand', () {
    test('grabs a single frame at the given time', () {
      final cmd = ThumbnailService.thumbnailCommand('in.mp4', 'out.jpg', 3.5);
      expect(cmd.contains('-ss 3.5 -i in.mp4'), isTrue);
      expect(cmd.contains('-frames:v 1'), isTrue);
      expect(cmd.contains('-vf'), isFalse);
      expect(cmd.trim().endsWith('out.jpg'), isTrue);
    });

    test('adds the title drawtext when provided', () {
      final cmd = ThumbnailService.thumbnailCommand('in.mp4', 'out.jpg', 1,
          drawtext: 'drawtext=x');
      expect(cmd.contains('-vf "drawtext=x"'), isTrue);
      expect(cmd.contains('-frames:v 1'), isTrue);
    });
  });

  group('ThumbnailService.titleFilter', () {
    test('centres the title with a background box', () {
      final f = ThumbnailService.titleFilter('/f.ttf', 'My Cover');
      expect(f.contains("text='My Cover'"), isTrue);
      expect(f.contains('box=1:boxcolor=black@0.5'), isTrue);
      expect(f.contains('x=(w-text_w)/2'), isTrue);
    });
  });
}
