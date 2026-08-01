import 'dart:developer';

import 'ai_video_service.dart';
import 'audio_cleanup_service.dart';
import 'auto_analysis_service.dart';

/// A single stage in the AI Polish pipeline.
enum PolishStep { stabilize, enhance, cleanAudio }

/// One-tap "AI Polish": chains the app's proven on-device operations —
/// stabilize shaky footage, adaptively enhance colour, and clean up the audio —
/// each stage feeding the next, entirely offline.
///
/// The step [plan] is a pure function (unit tested); [polish] runs the plan.
class AiPolishService {
  /// Human-readable label for a step (shown as progress while running).
  static String label(PolishStep step) {
    switch (step) {
      case PolishStep.stabilize:
        return 'Stabilizing…';
      case PolishStep.enhance:
        return 'Enhancing colour…';
      case PolishStep.cleanAudio:
        return 'Cleaning audio…';
    }
  }

  /// Builds the ordered list of steps to run for the chosen options. Order is
  /// deliberate: stabilize (geometry) → colour → audio.
  static List<PolishStep> plan({
    bool stabilize = true,
    bool enhance = true,
    bool cleanAudio = true,
  }) {
    return [
      if (stabilize) PolishStep.stabilize,
      if (enhance) PolishStep.enhance,
      if (cleanAudio) PolishStep.cleanAudio,
    ];
  }

  /// Runs the polish pipeline on [input]. Each enabled stage transforms the
  /// output of the previous one; a stage that fails is skipped (best-effort).
  /// Reports the current stage via [onStep]. Returns the final path, or null if
  /// no stage produced a change.
  static Future<String?> polish(
    String input, {
    bool stabilize = true,
    bool enhance = true,
    bool cleanAudio = true,
    void Function(PolishStep step)? onStep,
  }) async {
    final steps = plan(
      stabilize: stabilize,
      enhance: enhance,
      cleanAudio: cleanAudio,
    );
    var current = input;
    var changed = false;

    for (final step in steps) {
      onStep?.call(step);
      String? result;
      try {
        switch (step) {
          case PolishStep.stabilize:
            result = await AiVideoService.stabilizeVideo(current);
            break;
          case PolishStep.enhance:
            result = await AutoAnalysisService.adaptiveEnhance(current);
            break;
          case PolishStep.cleanAudio:
            result = await AudioCleanupService.cleanup(current);
            break;
        }
      } catch (e) {
        log('AiPolishService step ${step.name} failed: $e');
        result = null;
      }
      if (result != null) {
        current = result;
        changed = true;
      }
    }

    return changed ? current : null;
  }
}
