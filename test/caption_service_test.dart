import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_mobile_app/src/services/caption_service.dart';

void main() {
  group('CaptionService.toSrt', () {
    test('serialises cues with index, timestamps and text', () {
      final srt = CaptionService.toSrt(const [
        CaptionSegment(start: 0.0, end: 1.5, text: 'Hello'),
        CaptionSegment(start: 1.5, end: 3.0, text: 'World'),
      ]);
      expect(srt.contains('1\n00:00:00,000 --> 00:00:01,500\nHello'), isTrue);
      expect(srt.contains('2\n00:00:01,500 --> 00:00:03,000\nWorld'), isTrue);
    });

    test('sorts by start time and returns empty for no cues', () {
      expect(CaptionService.toSrt(const []), '');
      final srt = CaptionService.toSrt(const [
        CaptionSegment(start: 2.0, end: 3.0, text: 'second'),
        CaptionSegment(start: 0.0, end: 1.0, text: 'first'),
      ]);
      expect(srt.indexOf('first') < srt.indexOf('second'), isTrue);
    });
  });

  group('CaptionService.parseSrt', () {
    test('round-trips through toSrt', () {
      const segs = [
        CaptionSegment(start: 0.0, end: 1.5, text: 'Hello there'),
        CaptionSegment(start: 2.0, end: 4.25, text: 'General Kenobi'),
      ];
      final parsed = CaptionService.parseSrt(CaptionService.toSrt(segs));
      expect(parsed.length, 2);
      expect(parsed[0].text, 'Hello there');
      expect(parsed[1].start, closeTo(2.0, 1e-6));
      expect(parsed[1].end, closeTo(4.25, 1e-6));
    });

    test('accepts a dot millisecond separator (VTT-style)', () {
      final parsed = CaptionService.parseSrt(
          '1\n00:00:01.000 --> 00:00:02.000\nHi\n');
      expect(parsed.length, 1);
      expect(parsed.first.start, closeTo(1.0, 1e-6));
    });
  });

  group('CaptionService.distribute', () {
    test('splits text into evenly-timed cues covering the duration', () {
      final segs = CaptionService.distribute(
          'one two three four five six seven eight', 8.0,
          wordsPerCue: 4);
      expect(segs.length, 2);
      expect(segs.first.start, 0.0);
      expect(segs.last.end, closeTo(8.0, 1e-6));
    });

    test('empty text yields no cues', () {
      expect(CaptionService.distribute('   ', 10.0), isEmpty);
    });
  });

  group('CaptionService.forceStyle', () {
    test('maps position to libass alignment and colour to ASS hex', () {
      expect(CaptionService.forceStyle(position: CaptionService.bottom)
          .contains('Alignment=2'), isTrue);
      expect(CaptionService.forceStyle(position: CaptionService.top)
          .contains('Alignment=8'), isTrue);
      expect(CaptionService.forceStyle(color: 'yellow')
          .contains('PrimaryColour=&H0000FFFF'), isTrue);
    });
  });

  group('CaptionService.burnCommand', () {
    test('uses the subtitles filter with force_style and copies audio', () {
      final cmd = CaptionService.burnCommand(
          'in.mp4', 'out.mp4', '/tmp/c.srt',
          style: 'FontSize=24,Alignment=2');
      expect(cmd.contains("subtitles=/tmp/c.srt:force_style='"), isTrue);
      expect(cmd.contains('-c:v libx264'), isTrue);
      expect(cmd.contains('-c:a copy'), isTrue);
      expect(cmd.trim().endsWith('out.mp4'), isTrue);
    });
  });
}
