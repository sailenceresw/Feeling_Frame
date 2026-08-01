import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_mobile_app/src/services/export_preset_service.dart';

void main() {
  group('ExportPresetService.presets', () {
    test('covers the common platform aspect ratios', () {
      final ratios = ExportPresetService.presets.map((p) => p.ratio).toSet();
      expect(ratios.containsAll({'9:16', '16:9', '1:1', '4:5'}), isTrue);
    });

    test('dimensions match the stated ratio', () {
      final tiktok = ExportPresetService.presets
          .firstWhere((p) => p.ratio == '9:16' && p.name.contains('TikTok'));
      expect(tiktok.width, 1080);
      expect(tiktok.height, 1920);
    });
  });

  group('ExportPresetService.exportCommand', () {
    test('fill crops to completely cover the frame', () {
      final cmd = ExportPresetService.exportCommand(
        'in.mp4',
        'out.mp4',
        w: 1080,
        h: 1920,
      );
      expect(
        cmd.contains(
            'scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920'),
        isTrue,
      );
      expect(cmd.contains('boxblur'), isFalse);
      expect(cmd.contains('-c:v libx264'), isTrue);
      expect(cmd.trim().endsWith('out.mp4'), isTrue);
    });

    test('black bars scale-down and pad', () {
      final cmd = ExportPresetService.exportCommand(
        'in.mp4',
        'out.mp4',
        w: 1920,
        h: 1080,
        fit: ExportFit.bars,
      );
      expect(cmd.contains('force_original_aspect_ratio=decrease'), isTrue);
      expect(cmd.contains('pad=1920:1080:(ow-iw)/2:(oh-ih)/2:black'), isTrue);
    });

    test('blurred bars composite a blurred background behind the fitted clip',
        () {
      final cmd = ExportPresetService.exportCommand(
        'in.mp4',
        'out.mp4',
        w: 1080,
        h: 1080,
        fit: ExportFit.blur,
      );
      expect(cmd.contains('boxblur=20:5[bg]'), isTrue);
      expect(cmd.contains('[bg][fg]overlay=(W-w)/2:(H-h)/2[v]'), isTrue);
      expect(cmd.contains('-map "[v]"'), isTrue);
      expect(cmd.contains('-map 0:a?'), isTrue);
    });
  });

  group('ExportPresetService.fitLabel', () {
    test('every fit mode has a label', () {
      for (final fit in ExportFit.values) {
        expect(ExportPresetService.fitLabel(fit).isNotEmpty, isTrue);
      }
    });
  });
}
