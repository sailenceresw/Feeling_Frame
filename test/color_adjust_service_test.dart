import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_mobile_app/src/services/color_adjust_service.dart';

void main() {
  group('ColorAdjustService.colorFilter', () {
    test('defaults produce a neutral eq only', () {
      final f = ColorAdjustService.colorFilter();
      expect(f, 'eq=brightness=0:contrast=1:saturation=1');
      expect(f.contains('colorbalance'), isFalse);
    });

    test('warmth adds a colorbalance stage (warm = +red, -blue)', () {
      final f = ColorAdjustService.colorFilter(warmth: 1.0);
      expect(f.contains('colorbalance=rm=0.3:bm=-0.3'), isTrue);
    });

    test('cooling reverses the balance', () {
      final f = ColorAdjustService.colorFilter(warmth: -1.0);
      expect(f.contains('colorbalance=rm=-0.3:bm=0.3'), isTrue);
    });

    test('values are clamped to valid ranges', () {
      final f = ColorAdjustService.colorFilter(
        brightness: 5,
        contrast: 9,
        saturation: 9,
      );
      expect(f.contains('brightness=1'), isTrue);
      expect(f.contains('contrast=2'), isTrue);
      expect(f.contains('saturation=3'), isTrue);
    });
  });

  group('ColorAdjustService.colorCommand', () {
    test('wraps the filter and copies audio', () {
      final cmd = ColorAdjustService.colorCommand('in.mp4', 'out.mp4');
      expect(cmd.contains('-vf "eq='), isTrue);
      expect(cmd.contains('-c:a copy'), isTrue);
      expect(cmd.trim().endsWith('out.mp4'), isTrue);
    });
  });
}
