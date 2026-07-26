import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_mobile_app/src/services/keyframe_service.dart';

void main() {
  group('KeyframeService.sampleTrack', () {
    final times = [0.0, 1.0, 2.0];
    final values = [1.0, 2.0, 4.0];

    test('returns fallback when there are no keyframes', () {
      expect(KeyframeService.sampleTrack([], [], 0.5, 1.0), 1.0);
    });

    test('holds the first value before the first keyframe', () {
      expect(KeyframeService.sampleTrack(times, values, -5.0, 0.0), 1.0);
    });

    test('holds the last value after the last keyframe', () {
      expect(KeyframeService.sampleTrack(times, values, 99.0, 0.0), 4.0);
    });

    test('interpolates linearly between keyframes', () {
      // Halfway between (0,1) and (1,2) -> 1.5
      expect(KeyframeService.sampleTrack(times, values, 0.5, 0.0), 1.5);
      // Halfway between (1,2) and (2,4) -> 3.0
      expect(KeyframeService.sampleTrack(times, values, 1.5, 0.0), 3.0);
    });

    test('returns the exact value at a keyframe time', () {
      expect(KeyframeService.sampleTrack(times, values, 1.0, 0.0), 2.0);
    });
  });

  group('KeyframeService.sampleAt', () {
    test('returns neutral defaults with no keyframes', () {
      final s = KeyframeService.sampleAt([], 0.0);
      expect(s.zoom, 1.0);
      expect(s.cx, 0.5);
      expect(s.cy, 0.5);
    });

    test('interpolates all three properties together', () {
      final kfs = [
        const Keyframe(t: 0.0, zoom: 1.0, cx: 0.0, cy: 0.0),
        const Keyframe(t: 2.0, zoom: 2.0, cx: 1.0, cy: 1.0),
      ];
      final s = KeyframeService.sampleAt(kfs, 1.0);
      expect(s.zoom, closeTo(1.5, 1e-9));
      expect(s.cx, closeTo(0.5, 1e-9));
      expect(s.cy, closeTo(0.5, 1e-9));
    });
  });

  group('KeyframeService.fmt', () {
    test('trims trailing zeros and dangling dots', () {
      expect(KeyframeService.fmt(1.0), '1');
      expect(KeyframeService.fmt(2.0), '2');
      expect(KeyframeService.fmt(0.5), '0.5');
      expect(KeyframeService.fmt(0.0), '0');
    });
  });

  group('KeyframeService.piecewiseExpr', () {
    test('a single keyframe collapses to a constant', () {
      expect(KeyframeService.piecewiseExpr([1.5], [2.0]), '2');
    });

    test('holds the first value before the first keyframe', () {
      final expr = KeyframeService.piecewiseExpr([0.0, 1.0], [1.0, 2.0]);
      // Guarded by an `if(lt(time, t0), v0, ...)` clamp on the low end.
      expect(expr.startsWith('if(lt(time,0),1,'), isTrue);
    });

    test('builds a linear segment between two keyframes', () {
      final expr = KeyframeService.piecewiseExpr([0.0, 2.0], [1.0, 2.0]);
      // slope term (v1-v0)=1 over span 2, offset from t0=0
      expect(expr.contains('(1+(1)*(time-0)/2)'), isTrue);
      expect(expr.contains('if(lt(time,2)'), isTrue);
    });
  });

  group('KeyframeService.zoompanFilter', () {
    final kfs = [
      const Keyframe(t: 0.0, zoom: 1.0, cx: 0.5, cy: 0.5),
      const Keyframe(t: 2.0, zoom: 1.6, cx: 0.3, cy: 0.7),
    ];

    test('emits a zoompan filter at the requested size and fps', () {
      final f =
          KeyframeService.zoompanFilter(kfs, outW: 720, outH: 1280, fps: 30);
      expect(f.startsWith('zoompan='), isTrue);
      expect(f.contains('s=720x1280'), isTrue);
      expect(f.contains(':fps=30'), isTrue);
      expect(f.contains('d=1'), isTrue);
    });

    test('single-quotes the z/x/y expressions so commas are protected', () {
      final f =
          KeyframeService.zoompanFilter(kfs, outW: 720, outH: 1280, fps: 30);
      expect(f.contains("z='"), isTrue);
      expect(f.contains("x='clip("), isTrue);
      expect(f.contains("y='clip("), isTrue);
    });
  });

  group('KeyframeService.renderCommand', () {
    test('wraps the filter and re-encodes video while copying audio', () {
      final cmd = KeyframeService.renderCommand('in.mp4', 'out.mp4', 'zoompan=x');
      expect(cmd.contains('-i in.mp4'), isTrue);
      expect(cmd.contains('-vf "zoompan=x"'), isTrue);
      expect(cmd.contains('-c:v libx264'), isTrue);
      expect(cmd.contains('-c:a copy'), isTrue);
      expect(cmd.trim().endsWith('out.mp4'), isTrue);
    });
  });
}
