import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_mobile_app/src/services/transition_service.dart';

void main() {
  group('TransitionService.transitions', () {
    test('offers a curated catalogue of xfade ids', () {
      expect(TransitionService.transitions.length, greaterThanOrEqualTo(8));
      expect(TransitionService.transitions['Crossfade'], 'fade');
      expect(TransitionService.transitions['Dissolve'], 'dissolve');
    });
  });

  group('TransitionService.transitionCommand', () {
    final cmd = TransitionService.transitionCommand(
      'a.mp4',
      'b.mp4',
      'out.mp4',
      w: 1080,
      h: 1920,
      clip1Duration: 5.0,
      transition: 'wipeleft',
      duration: 1.0,
      fps: 30,
    );

    test('normalises both inputs to the same size/sar/fps/format', () {
      expect(cmd.contains('[0:v]scale=1080:1920,setsar=1,fps=30,format=yuv420p[v0]'),
          isTrue);
      expect(cmd.contains('[1:v]scale=1080:1920,setsar=1,fps=30,format=yuv420p[v1]'),
          isTrue);
    });

    test('xfade starts one duration before clip1 ends (offset = 5 - 1 = 4)', () {
      expect(
        cmd.contains(
            '[v0][v1]xfade=transition=wipeleft:duration=1:offset=4[v]'),
        isTrue,
      );
    });

    test('crossfades the audio and maps both streams', () {
      expect(cmd.contains('[0:a][1:a]acrossfade=d=1[a]'), isTrue);
      expect(cmd.contains('-map "[v]"'), isTrue);
      expect(cmd.contains('-map "[a]"'), isTrue);
      expect(cmd.trim().endsWith('out.mp4'), isTrue);
    });

    test('clamps the offset to 0 when the transition is longer than clip1', () {
      final short = TransitionService.transitionCommand(
        'a.mp4',
        'b.mp4',
        'out.mp4',
        w: 640,
        h: 480,
        clip1Duration: 0.5,
        duration: 1.0,
      );
      expect(short.contains('offset=0[v]'), isTrue);
    });

    test('video-only variant drops audio', () {
      final v = TransitionService.transitionCommand(
        'a.mp4',
        'b.mp4',
        'out.mp4',
        w: 640,
        h: 480,
        clip1Duration: 3.0,
        keepAudio: false,
      );
      expect(v.contains('-an'), isTrue);
      expect(v.contains('acrossfade'), isFalse);
      expect(v.contains('-map "[a]"'), isFalse);
    });
  });
}
