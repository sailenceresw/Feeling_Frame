import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_mobile_app/src/services/vfx_service.dart';

void main() {
  group('VfxService.vfxFilter', () {
    test('combines vignette and grain when both are on', () {
      final f = VfxService.vfxFilter(vignette: 0.5, grain: 10);
      expect(f.contains('vignette=angle=PI/'), isTrue);
      expect(f.contains('noise=alls=10:allf=t+u'), isTrue);
    });

    test('grain 0 omits noise', () {
      final f = VfxService.vfxFilter(vignette: 0.5, grain: 0);
      expect(f.contains('noise='), isFalse);
      expect(f.contains('vignette='), isTrue);
    });

    test('vignette 0 omits vignette', () {
      final f = VfxService.vfxFilter(vignette: 0, grain: 8);
      expect(f.contains('vignette='), isFalse);
      expect(f.contains('noise='), isTrue);
    });

    test('both off yields a passthrough null filter', () {
      expect(VfxService.vfxFilter(vignette: 0, grain: 0), 'null');
    });
  });

  group('VfxService.vfxCommand', () {
    test('wraps the filter and copies audio', () {
      final cmd = VfxService.vfxCommand('in.mp4', 'out.mp4');
      expect(cmd.contains('-vf "'), isTrue);
      expect(cmd.contains('-c:a copy'), isTrue);
      expect(cmd.trim().endsWith('out.mp4'), isTrue);
    });
  });
}
