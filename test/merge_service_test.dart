import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_mobile_app/src/services/merge_service.dart';

void main() {
  group('MergeService.concatFilter', () {
    test('normalises each input and concats with audio', () {
      final f = MergeService.concatFilter(2, 1080, 1920, 30);
      expect(
        f.contains(
            '[0:v]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,setsar=1,fps=30,format=yuv420p[v0]'),
        isTrue,
      );
      expect(f.contains('[v0][0:a][v1][1:a]concat=n=2:v=1:a=1[v][a]'), isTrue);
    });

    test('video-only variant uses a=0 and no audio labels', () {
      final f = MergeService.concatFilter(3, 720, 1280, 30, withAudio: false);
      expect(f.contains('concat=n=3:v=1:a=0[v]'), isTrue);
      expect(f.contains('[0:a]'), isFalse);
    });
  });

  group('MergeService.mergeCommand', () {
    test('adds an input per clip and maps the concatenated streams', () {
      final cmd = MergeService.mergeCommand(
        ['a.mp4', 'b.mp4'],
        'out.mp4',
        w: 1080,
        h: 1920,
      );
      expect(cmd.contains('-i a.mp4 -i b.mp4'), isTrue);
      expect(cmd.contains('-map "[v]" -map "[a]"'), isTrue);
      expect(cmd.contains('-c:v libx264'), isTrue);
      expect(cmd.trim().endsWith('out.mp4'), isTrue);
    });
  });
}
