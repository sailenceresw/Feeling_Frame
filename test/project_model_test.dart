import 'package:flutter_test/flutter_test.dart';
import 'package:video_editor_mobile_app/src/models/project_model.dart';

void main() {
  group('ProjectModel', () {
    test('serializes to JSON and back', () {
      final original = ProjectModel(
        path: '/videos/out.mp4',
        title: 'My Project',
        createdAt: DateTime(2024, 3, 21, 14, 30),
        sizeBytes: 1572864,
        durationSeconds: 90,
      );

      final restored = ProjectModel.fromJson(original.toJson());

      expect(restored.path, original.path);
      expect(restored.title, original.title);
      expect(restored.createdAt, original.createdAt);
      expect(restored.sizeBytes, original.sizeBytes);
      expect(restored.durationSeconds, original.durationSeconds);
    });

    test('formats size in megabytes', () {
      final project = ProjectModel(
        path: 'p',
        title: 't',
        createdAt: DateTime.now(),
        sizeBytes: 1572864, // 1.5 MB
        durationSeconds: 0,
      );
      expect(project.formattedSize, '1.5 MB');
    });

    test('formats duration as MM:SSs', () {
      final project = ProjectModel(
        path: 'p',
        title: 't',
        createdAt: DateTime.now(),
        sizeBytes: 0,
        durationSeconds: 90,
      );
      expect(project.formattedDuration, '01:30s');
    });

    test('fromJson tolerates missing optional fields', () {
      final restored = ProjectModel.fromJson({'path': '/videos/x.mp4'});
      expect(restored.path, '/videos/x.mp4');
      expect(restored.title, 'Untitled');
      expect(restored.sizeBytes, 0);
      expect(restored.durationSeconds, 0);
      // createdAt falls back to "now" — just verify it parses to a DateTime.
      expect(restored.createdAt, isA<DateTime>());
    });
  });
}
