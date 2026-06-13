import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_mobile_app/src/utils/srt_builder.dart';

Map<String, dynamic> word(String w, double start, double end) =>
    {'word': w, 'start': start, 'end': end};

void main() {
  group('srtTimestamp', () {
    test('formats zero', () {
      expect(srtTimestamp(0), '00:00:00,000');
    });

    test('formats sub-second values with milliseconds', () {
      expect(srtTimestamp(1.5), '00:00:01,500');
    });

    test('formats hours, minutes and seconds', () {
      expect(srtTimestamp(3661.25), '01:01:01,250');
    });
  });

  group('buildSrt', () {
    test('returns empty string for no words', () {
      expect(buildSrt([]), '');
    });

    test('builds a single cue for a short phrase', () {
      final srt = buildSrt([
        word('hello', 0.0, 0.5),
        word('world', 0.5, 1.0),
      ]);
      expect(srt, contains('1\n'));
      expect(srt, contains('00:00:00,000 --> 00:00:01,000'));
      expect(srt, contains('hello world'));
      // Only one cue.
      expect(srt, isNot(contains('\n2\n')));
    });

    test('starts a new cue after maxWords words', () {
      final words = List.generate(
        8,
        (i) => word('w$i', i * 0.2, i * 0.2 + 0.2),
      );
      final srt = buildSrt(words);
      // 8 words with maxWords=7 -> two cues.
      expect(srt, contains('\n2\n'));
      expect(srt, contains('w7'));
    });

    test('starts a new cue when the span exceeds maxSpanSeconds', () {
      final srt = buildSrt([
        word('slow', 0.0, 4.0), // span 4.0 >= 3.5 -> cue flushed
        word('next', 4.0, 4.5),
      ]);
      expect(srt, contains('\n2\n'));
      expect(srt, contains('00:00:04,000 --> 00:00:04,500'));
    });
  });
}
