import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_mobile_app/src/services/slideshow_service.dart';

void main() {
  group('SlideshowService.slideshowCommand', () {
    test('loops each image for the duration and concats them', () {
      final cmd = SlideshowService.slideshowCommand(
        ['a.jpg', 'b.jpg', 'c.jpg'],
        'out.mp4',
        w: 1080,
        h: 1920,
        secondsPer: 3,
      );
      expect(cmd.contains('-loop 1 -t 3 -i a.jpg'), isTrue);
      expect(cmd.contains('-loop 1 -t 3 -i c.jpg'), isTrue);
      expect(cmd.contains('concat=n=3:v=1:a=0[v]'), isTrue);
      expect(cmd.contains('-map "[v]"'), isTrue);
      expect(cmd.trim().endsWith('out.mp4'), isTrue);
    });

    test('adds a looped music input, its audio map and -shortest', () {
      final cmd = SlideshowService.slideshowCommand(
        ['a.jpg', 'b.jpg'],
        'out.mp4',
        w: 1080,
        h: 1080,
        music: 'song.mp3',
      );
      expect(cmd.contains('-stream_loop -1 -i song.mp3'), isTrue);
      expect(cmd.contains('-map 2:a'), isTrue); // index 2 = after the 2 images
      expect(cmd.contains('-shortest'), isTrue);
      expect(cmd.contains('-c:a aac'), isTrue);
    });

    test('no music means no audio map or audio codec', () {
      final cmd = SlideshowService.slideshowCommand(['a.jpg'], 'out.mp4',
          w: 720, h: 720);
      expect(cmd.contains('-c:a'), isFalse);
      expect(cmd.contains('-map 1:a'), isFalse);
      expect(cmd.contains('-stream_loop'), isFalse);
    });
  });
}
