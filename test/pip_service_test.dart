import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_mobile_app/src/services/pip_service.dart';

void main() {
  group('PipService.overlayXY', () {
    test('places the inset in each corner with the margin', () {
      expect(PipService.overlayXY(PipService.topLeft, 20), '20:20');
      expect(PipService.overlayXY(PipService.topRight, 20), 'W-w-20:20');
      expect(PipService.overlayXY(PipService.bottomLeft, 20), '20:H-h-20');
      expect(PipService.overlayXY(PipService.bottomRight, 20), 'W-w-20:H-h-20');
    });
  });

  group('PipService.insetWidth', () {
    test('is a fraction of the main width, rounded to even', () {
      expect(PipService.insetWidth(1000, 0.3), 300);
      expect(PipService.insetWidth(1001, 0.3), 300); // 300.3 -> 300 (even)
      expect(PipService.insetWidth(999, 0.3), 300); // 299.7 -> 300 (even)
    });

    test('never drops below 2', () {
      expect(PipService.insetWidth(1, 0.3), 2);
    });
  });

  group('PipService.pipCommand (rectangular)', () {
    final cmd = PipService.pipCommand(
      'main.mp4',
      'pip.mp4',
      'out.mp4',
      mainW: 1000,
      sizeFraction: 0.3,
      corner: PipService.bottomRight,
      margin: 30,
    );

    test('scales the inset and overlays it bottom-right', () {
      expect(cmd.contains('[1:v]scale=300:-2[pip]'), isTrue);
      expect(cmd.contains('[0:v][pip]overlay=W-w-30:H-h-30[v]'), isTrue);
    });

    test('keeps the main audio and re-encodes video', () {
      expect(cmd.contains('-map "[v]"'), isTrue);
      expect(cmd.contains('-map 0:a?'), isTrue);
      expect(cmd.contains('-c:v libx264'), isTrue);
      expect(cmd.contains('-c:a copy'), isTrue);
      expect(cmd.trim().endsWith('out.mp4'), isTrue);
    });

    test('is not circular', () {
      expect(cmd.contains('geq'), isFalse);
    });
  });

  group('PipService.pipCommand (circle)', () {
    final cmd = PipService.pipCommand(
      'main.mp4',
      'pip.mp4',
      'out.mp4',
      mainW: 1000,
      sizeFraction: 0.25,
      corner: PipService.topLeft,
      margin: 20,
      circle: true,
    );

    test('scales to a square and alpha-masks a circle via geq', () {
      expect(cmd.contains('scale=250:250'), isTrue);
      expect(cmd.contains('format=rgba'), isTrue);
      expect(cmd.contains('geq='), isTrue);
      expect(cmd.contains('hypot(X-250/2,Y-250/2)'), isTrue);
    });

    test('still overlays at the requested corner', () {
      expect(cmd.contains('overlay=20:20[v]'), isTrue);
    });
  });
}
