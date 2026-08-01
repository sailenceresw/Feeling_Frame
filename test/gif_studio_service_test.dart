import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_mobile_app/src/services/gif_studio_service.dart';

void main() {
  group('GifStudioService.gifCommand', () {
    test('standard uses fps/scale and a loop flag', () {
      final cmd = GifStudioService.gifCommand('in.mp4', 'out.gif',
          fps: 15, width: 320, loop: 0);
      expect(cmd.contains('-vf "fps=15,scale=320:-1:flags=lanczos"'), isTrue);
      expect(cmd.contains('-loop 0'), isTrue);
      expect(cmd.contains('palettegen'), isFalse);
      expect(cmd.trim().endsWith('out.gif'), isTrue);
    });

    test('high quality adds a palette pass', () {
      final cmd = GifStudioService.gifCommand('in.mp4', 'out.gif',
          highQuality: true);
      expect(cmd.contains('palettegen[p]'), isTrue);
      expect(cmd.contains('[b][p]paletteuse'), isTrue);
    });
  });
}
