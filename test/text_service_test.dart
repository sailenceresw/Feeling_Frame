import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_mobile_app/src/services/text_service.dart';

void main() {
  group('TextService.sanitizeText', () {
    test('replaces straight quotes with a typographic apostrophe', () {
      expect(TextService.sanitizeText("it's"), 'it’s');
    });

    test('drops backslashes and percent signs, and trims', () {
      expect(TextService.sanitizeText('  a\\b%c  '), 'abc');
    });

    test('keeps ordinary text and spaces', () {
      expect(TextService.sanitizeText('Hello World!'), 'Hello World!');
    });
  });

  group('TextService.positionXY', () {
    test('centres horizontally and anchors per position', () {
      expect(TextService.positionXY(TextService.top),
          'x=(w-text_w)/2:y=h*0.08');
      expect(TextService.positionXY(TextService.center),
          'x=(w-text_w)/2:y=(h-text_h)/2');
      expect(TextService.positionXY(TextService.bottom),
          'x=(w-text_w)/2:y=h*0.85');
    });
  });

  group('TextService.drawtextFilter', () {
    test('includes font, text, size, colour and a box by default', () {
      final f = TextService.drawtextFilter(
        fontfile: '/tmp/font.ttf',
        text: 'Hello',
        position: TextService.bottom,
        fontsize: 48,
        color: 'yellow',
      );
      expect(f.contains('drawtext=fontfile=/tmp/font.ttf'), isTrue);
      expect(f.contains("text='Hello'"), isTrue);
      expect(f.contains('fontsize=48'), isTrue);
      expect(f.contains('fontcolor=yellow'), isTrue);
      expect(f.contains('box=1'), isTrue);
    });

    test('omits the box when disabled and adds no enable without a range', () {
      final f = TextService.drawtextFilter(
        fontfile: '/f.ttf',
        text: 'Hi',
        position: TextService.top,
        fontsize: 30,
        box: false,
      );
      expect(f.contains('box=1'), isFalse);
      expect(f.contains('enable='), isFalse);
    });

    test('adds a time window when start/end are given', () {
      final f = TextService.drawtextFilter(
        fontfile: '/f.ttf',
        text: 'Hi',
        position: TextService.center,
        fontsize: 30,
        start: 1.0,
        end: 3.5,
      );
      expect(f.contains("enable='between(t,1,3.5)'"), isTrue);
    });
  });

  group('TextService.textCommand', () {
    test('wraps the filter and copies audio', () {
      final cmd = TextService.textCommand('in.mp4', 'out.mp4', 'drawtext=x');
      expect(cmd.contains('-vf "drawtext=x"'), isTrue);
      expect(cmd.contains('-c:v libx264'), isTrue);
      expect(cmd.contains('-c:a copy'), isTrue);
      expect(cmd.trim().endsWith('out.mp4'), isTrue);
    });
  });
}
