import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_mobile_app/src/services/loop_service.dart';

void main() {
  group('LoopService.loopCommand', () {
    test('repeats N times via stream_loop N-1 and stream copy', () {
      final cmd = LoopService.loopCommand('in.mp4', 'out.mp4', 3);
      expect(cmd.contains('-stream_loop 2 -i in.mp4'), isTrue);
      expect(cmd.contains('-c copy'), isTrue);
      expect(cmd.trim().endsWith('out.mp4'), isTrue);
    });

    test('times < 1 is clamped (no negative stream_loop)', () {
      final cmd = LoopService.loopCommand('in.mp4', 'out.mp4', 0);
      expect(cmd.contains('-stream_loop 0'), isTrue);
    });
  });

  group('LoopService.pingpongCommand', () {
    test('reverses and concatenates forward+reverse, video only', () {
      final cmd = LoopService.pingpongCommand('in.mp4', 'out.mp4');
      expect(cmd.contains('[0:v]reverse[r];[0:v][r]concat=n=2:v=1[v]'), isTrue);
      expect(cmd.contains('-map "[v]"'), isTrue);
      expect(cmd.contains('-an'), isTrue);
    });
  });
}
