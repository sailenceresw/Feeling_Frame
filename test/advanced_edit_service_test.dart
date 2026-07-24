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

    test('grabFrameCommand seeks before input and grabs one frame', () {
      final cmd =
          AdvancedEditService.grabFrameCommand('in.mp4', 'f.jpg', 3.4);
      // -ss must come before -i for a fast seek
      expect(cmd.indexOf('-ss'), lessThan(cmd.indexOf('-i')));
      expect(cmd, contains('-ss 3.40'));
      expect(cmd, contains('-frames:v 1'));
      expect(cmd, endsWith('f.jpg'));
    });
  });

  group('Auto-cut helpers', () {
    test('parseSilences pairs starts and ends, closing open silence at total',
        () {
      const log = 'silence_start: 2.0\n'
          'silence_end: 4.0 | silence_duration: 2.0\n'
          'silence_start: 8.5';
      final s = AdvancedEditService.parseSilences(log, 10);
      expect(s, [
        [2.0, 4.0],
        [8.5, 10.0],
      ]);
    });

    test('keepSegmentsFromSilence inverts silences into keep segments', () {
      final keep = AdvancedEditService.keepSegmentsFromSilence([
        [2.0, 4.0],
        [8.5, 10.0],
      ], 10);
      // keep 0..2 and 4..8.5
      expect(keep, [
        [0.0, 2.0],
        [4.0, 8.5],
      ]);
    });

    test('keepSegmentsFromSilence drops slivers shorter than minKeep', () {
      final keep = AdvancedEditService.keepSegmentsFromSilence([
        [0.05, 5.0],
      ], 5.0);
      // The 0..0.05 sliver is dropped; nothing else to keep.
      expect(keep, isEmpty);
    });

    test('jumpCutFilter builds select/aselect with between() expressions', () {
      final f = AdvancedEditService.jumpCutFilter([
        [0.0, 2.0],
        [4.0, 8.5],
      ]);
      expect(f, contains('select='));
      expect(f, contains('aselect='));
      expect(f, contains('between(t,0.000,2.000)+between(t,4.000,8.500)'));
      expect(f, contains('setpts=N/FRAME_RATE/TB'));
      expect(f, contains('asetpts=N/SR/TB'));
    });

    test('autoEnhanceCommand adjusts colour and keeps audio', () {
      final cmd = AdvancedEditService.autoEnhanceCommand('in.mp4', 'out.mp4');
      expect(cmd, contains('eq=contrast'));
      expect(cmd, contains('-c:a copy'));
    });
  });
}
