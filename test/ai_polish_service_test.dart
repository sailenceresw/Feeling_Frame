import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_mobile_app/src/services/ai_polish_service.dart';

void main() {
  group('AiPolishService.plan', () {
    test('full pipeline is stabilize -> enhance -> cleanAudio in order', () {
      expect(AiPolishService.plan(), [
        PolishStep.stabilize,
        PolishStep.enhance,
        PolishStep.cleanAudio,
      ]);
    });

    test('respects individual toggles and preserves order', () {
      expect(
        AiPolishService.plan(enhance: false),
        [PolishStep.stabilize, PolishStep.cleanAudio],
      );
      expect(
        AiPolishService.plan(stabilize: false, cleanAudio: false),
        [PolishStep.enhance],
      );
    });

    test('all-off yields an empty plan', () {
      expect(
        AiPolishService.plan(
          stabilize: false,
          enhance: false,
          cleanAudio: false,
        ),
        isEmpty,
      );
    });
  });

  group('AiPolishService.label', () {
    test('every step has a non-empty progress label', () {
      for (final step in PolishStep.values) {
        expect(AiPolishService.label(step).isNotEmpty, isTrue);
      }
    });
  });
}
