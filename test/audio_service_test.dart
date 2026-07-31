import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_mobile_app/src/services/audio_service.dart';

void main() {
  group('AudioService.fmt', () {
    test('trims trailing zeros', () {
      expect(AudioService.fmt(0.6), '0.6');
      expect(AudioService.fmt(1.0), '1');
      expect(AudioService.fmt(0.0), '0');
    });
  });

  group('AudioService.addMusicCommand (mix mode)', () {
    final cmd = AudioService.addMusicCommand(
      'v.mp4',
      'song.mp3',
      'out.mp4',
      totalSeconds: 10.0,
      musicVolume: 0.6,
      originalVolume: 0.8,
    );

    test('mixes original + music with amix', () {
      expect(cmd.contains('amix=inputs=2:duration=first'), isTrue);
      expect(cmd.contains('[0:a]volume=0.8[o]'), isTrue);
      expect(cmd.contains('[1:a]volume=0.6'), isTrue);
    });

    test('fades the music in at 0 and out before the end', () {
      expect(cmd.contains('afade=t=in:st=0:d=1'), isTrue);
      // out-fade starts at totalSeconds - fadeSeconds = 9
      expect(cmd.contains('afade=t=out:st=9:d=1'), isTrue);
    });

    test('copies video, encodes aac, loops music, and is length-safe', () {
      expect(cmd.contains('-c:v copy'), isTrue);
      expect(cmd.contains('-c:a aac'), isTrue);
      expect(cmd.contains('-stream_loop -1'), isTrue);
      expect(cmd.contains('-shortest'), isTrue);
      expect(cmd.contains('-map 0:v'), isTrue);
      expect(cmd.contains('-map "[a]"'), isTrue);
    });
  });

  group('AudioService.addMusicCommand (replace mode)', () {
    final cmd = AudioService.addMusicCommand(
      'v.mp4',
      'song.mp3',
      'out.mp4',
      totalSeconds: 10.0,
      keepOriginal: false,
    );

    test('does not reference the original audio or amix', () {
      expect(cmd.contains('amix'), isFalse);
      expect(cmd.contains('[0:a]'), isFalse);
    });

    test('still maps the music as the output audio', () {
      expect(cmd.contains('[1:a]volume='), isTrue);
      expect(cmd.contains('[a]'), isTrue);
      expect(cmd.contains('-map 0:v'), isTrue);
    });
  });

  group('AudioService.addMusicCommand (toggles)', () {
    test('fade disabled omits afade', () {
      final cmd = AudioService.addMusicCommand('v.mp4', 's.mp3', 'o.mp4',
          totalSeconds: 10.0, fade: false);
      expect(cmd.contains('afade'), isFalse);
    });

    test('loop disabled omits -stream_loop', () {
      final cmd = AudioService.addMusicCommand('v.mp4', 's.mp3', 'o.mp4',
          totalSeconds: 10.0, loopMusic: false);
      expect(cmd.contains('-stream_loop'), isFalse);
    });

    test('clamps out-fade start to 0 for very short clips', () {
      final cmd = AudioService.addMusicCommand('v.mp4', 's.mp3', 'o.mp4',
          totalSeconds: 0.5, fadeSeconds: 1.0);
      expect(cmd.contains('afade=t=out:st=0:d=1'), isTrue);
    });

    test('volume is clamped to the 0..4 range', () {
      final cmd = AudioService.addMusicCommand('v.mp4', 's.mp3', 'o.mp4',
          totalSeconds: 10.0, keepOriginal: false, musicVolume: 9.0);
      expect(cmd.contains('[1:a]volume=4'), isTrue);
    });
  });
}
