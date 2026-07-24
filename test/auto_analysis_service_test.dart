import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_mobile_app/src/services/auto_analysis_service.dart';

FrameStat f(double t, double ydif) => FrameStat(t, ydif: ydif);

void main() {
  group('parseFrameStats', () {
    test('extracts pts_time and signalstats values per frame', () {
      const log = '''
[Parsed_metadata_1 @ 0x1] frame:0    pts:0      pts_time:0
[Parsed_metadata_1 @ 0x1] lavfi.signalstats.YAVG=100.5
[Parsed_metadata_1 @ 0x1] lavfi.signalstats.SATAVG=42.0
[Parsed_metadata_1 @ 0x1] lavfi.signalstats.YDIF=2.5
[Parsed_metadata_1 @ 0x1] frame:1    pts:512    pts_time:0.5
[Parsed_metadata_1 @ 0x1] lavfi.signalstats.YAVG=110.0
[Parsed_metadata_1 @ 0x1] lavfi.signalstats.YDIF=25.0
''';
      final stats = AutoAnalysisService.parseFrameStats(log);
      expect(stats, hasLength(2));
      expect(stats[0].t, 0);
      expect(stats[0].yavg, 100.5);
      expect(stats[0].satavg, 42.0);
      expect(stats[0].ydif, 2.5);
      expect(stats[1].t, 0.5);
      expect(stats[1].ydif, 25.0);
    });

    test('returns empty list for unrelated log text', () {
      expect(AutoAnalysisService.parseFrameStats('nothing here'), isEmpty);
    });
  });

  group('shakyIntervals', () {
    test('merges consecutive spikes and pads the interval', () {
      final stats = [
        f(0.0, 2), f(0.5, 2),
        f(1.0, 30), f(1.2, 28), f(1.4, 31), // shaky burst 1.0..1.4
        f(1.8, 3), f(2.2, 2),
      ];
      final iv = AutoAnalysisService.shakyIntervals(stats, 3.0,
          threshold: 18, pad: 0.15);
      expect(iv, hasLength(1));
      expect(iv[0][0], closeTo(0.85, 1e-9));
      expect(iv[0][1], closeTo(1.55, 1e-9));
    });

    test('ignores single-frame blips shorter than minDuration', () {
      final stats = [f(0.0, 2), f(0.5, 40), f(1.0, 2)];
      final iv = AutoAnalysisService.shakyIntervals(stats, 2.0,
          threshold: 18, minDuration: 0.25);
      expect(iv, isEmpty);
    });

    test('clamps padding at clip boundaries', () {
      final stats = [f(0.0, 30), f(0.2, 30), f(0.4, 30)];
      final iv = AutoAnalysisService.shakyIntervals(stats, 0.5,
          threshold: 18, pad: 0.2);
      expect(iv, hasLength(1));
      expect(iv[0][0], 0.0);
      expect(iv[0][1], 0.5);
    });
  });

  group('adaptiveEqParams', () {
    test('lifts gamma and boosts saturation for dark, dull footage', () {
      final eq = AutoAnalysisService.adaptiveEqParams(60, 20);
      expect(eq, contains('gamma=1.12'));
      expect(eq, contains('saturation=1.15'));
      // brightness positive but clamped
      expect(eq, contains('brightness=0.08'));
    });

    test('keeps saturation neutral for already-colourful footage', () {
      final eq = AutoAnalysisService.adaptiveEqParams(128, 120);
      expect(eq, contains('saturation=1.00'));
      expect(eq, contains('gamma=1.00'));
      expect(eq, contains('brightness=0.000'));
    });

    test('tames highlights for overexposed footage', () {
      final eq = AutoAnalysisService.adaptiveEqParams(200, 60);
      expect(eq, contains('gamma=0.96'));
      // negative brightness, clamped at -0.06
      expect(eq, contains('brightness=-0.06'));
    });
  });
}
