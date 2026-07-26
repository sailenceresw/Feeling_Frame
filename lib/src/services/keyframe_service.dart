import 'dart:developer';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../utils/storage_path.dart';

/// A single keyframe on the pan/zoom timeline. Every keyframe captures a full
/// snapshot of the animatable properties at time [t] (seconds), CapCut-style:
///
/// * [zoom]  — magnification factor, `>= 1.0` (1.0 = no zoom).
/// * [cx],[cy] — the point the camera is centred on, as a fraction of the
///   frame in `0..1` (0.5,0.5 = centre).
///
/// Between two keyframes each property is interpolated **linearly**, so the
/// exported video smoothly pushes in / pans across the clip.
class Keyframe {
  const Keyframe({
    required this.t,
    this.zoom = 1.0,
    this.cx = 0.5,
    this.cy = 0.5,
  });

  final double t;
  final double zoom;
  final double cx;
  final double cy;

  Keyframe copyWith({double? t, double? zoom, double? cx, double? cy}) =>
      Keyframe(
        t: t ?? this.t,
        zoom: zoom ?? this.zoom,
        cx: cx ?? this.cx,
        cy: cy ?? this.cy,
      );
}

/// The interpolated camera state at a moment in time.
typedef KeyframeSample = ({double zoom, double cx, double cy});

/// Builds and runs an animated pan/zoom ("keyframe animation") on top of
/// FFmpeg's `zoompan` filter. All the maths (interpolation + expression
/// building + command construction) lives in pure static helpers so it can be
/// unit tested without a device; the public [render] method probes the source
/// frame rate, runs the command, and returns the output path (or null).
class KeyframeService {
  static const double defaultZoom = 1.0;
  static const double defaultCenter = 0.5;

  // ---- Pure sampling (shared with the live UI preview) ---------------------

  /// Linearly interpolates the [values] (paired with sorted [times]) at time
  /// [t]. Clamps to the first/last value outside the keyframe range and
  /// returns [fallback] when there are no keyframes.
  static double sampleTrack(
    List<double> times,
    List<double> values,
    double t,
    double fallback,
  ) {
    if (times.isEmpty) return fallback;
    if (t <= times.first) return values.first;
    if (t >= times.last) return values.last;
    for (var i = 0; i < times.length - 1; i++) {
      final t0 = times[i], t1 = times[i + 1];
      if (t >= t0 && t <= t1) {
        final span = t1 - t0;
        if (span <= 0) return values[i];
        final f = (t - t0) / span;
        return values[i] + (values[i + 1] - values[i]) * f;
      }
    }
    return values.last;
  }

  /// Samples the full camera state at [t] from a (time-sorted) keyframe list.
  static KeyframeSample sampleAt(List<Keyframe> kfs, double t) {
    if (kfs.isEmpty) {
      return (zoom: defaultZoom, cx: defaultCenter, cy: defaultCenter);
    }
    final times = kfs.map((k) => k.t).toList();
    return (
      zoom: sampleTrack(times, kfs.map((k) => k.zoom).toList(), t, defaultZoom),
      cx: sampleTrack(times, kfs.map((k) => k.cx).toList(), t, defaultCenter),
      cy: sampleTrack(times, kfs.map((k) => k.cy).toList(), t, defaultCenter),
    );
  }

  // ---- Pure expression / command builders (unit tested) --------------------

  /// Compact numeric formatting for FFmpeg expressions (trims trailing zeros).
  static String fmt(double v) {
    var s = v.toStringAsFixed(4);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
    }
    return s.isEmpty ? '0' : s;
  }

  /// Builds a piecewise-linear FFmpeg expression (in variable [tVar]) that
  /// reproduces [sampleTrack]: constant before the first / after the last
  /// keyframe, linearly interpolated in between.
  static String piecewiseExpr(
    List<double> times,
    List<double> values, {
    String tVar = 'time',
  }) {
    if (times.isEmpty) return '0';
    if (times.length == 1) return fmt(values.first);
    // Innermost fallback: after the last keyframe hold the last value.
    var expr = fmt(values.last);
    for (var i = times.length - 2; i >= 0; i--) {
      final t0 = times[i], t1 = times[i + 1];
      final v0 = values[i], v1 = values[i + 1];
      final d = t1 - t0;
      final seg = d <= 0
          ? fmt(v1)
          : '(${fmt(v0)}+(${fmt(v1 - v0)})*($tVar-${fmt(t0)})/${fmt(d)})';
      expr = 'if(lt($tVar,${fmt(t1)}),$seg,$expr)';
    }
    // Before the first keyframe hold the first value.
    return 'if(lt($tVar,${fmt(times.first)}),${fmt(values.first)},$expr)';
  }

  /// Builds the `zoompan` filter string for [kfs] rendering at [outW]x[outH]
  /// and [fps]. The zoom window is `iw/zoom` x `ih/zoom`, centred on (cx,cy)
  /// and clamped to stay inside the frame, then scaled back up to full size —
  /// i.e. an animated push-in / pan.
  static String zoompanFilter(
    List<Keyframe> kfs, {
    required int outW,
    required int outH,
    required int fps,
  }) {
    final times = kfs.map((k) => k.t).toList();
    final z = piecewiseExpr(times, kfs.map((k) => k.zoom).toList());
    final cx = piecewiseExpr(times, kfs.map((k) => k.cx).toList());
    final cy = piecewiseExpr(times, kfs.map((k) => k.cy).toList());
    // x/y are the top-left of the zoom window in source pixels; `zoom` here is
    // the current per-frame zoom that zoompan has already evaluated.
    final x = 'clip(iw*($cx)-iw/(2*zoom),0,iw-iw/zoom)';
    final y = 'clip(ih*($cy)-ih/(2*zoom),0,ih-ih/zoom)';
    return "zoompan=z='$z':x='$x':y='$y':d=1:s=${outW}x$outH:fps=$fps";
  }

  /// The full FFmpeg command for the keyframe render.
  static String renderCommand(String input, String output, String filter) =>
      '-y -i $input -vf "$filter" '
      '-c:v libx264 -crf 20 -preset fast -pix_fmt yuv420p -c:a copy $output';

  // ---- Runners -------------------------------------------------------------

  static Future<bool> _run(String command) async {
    log("KeyframeService command: $command");
    final session = await FFmpegKit.execute(command);
    final rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) return true;
    log("KeyframeService failed: ${await session.getOutput()}");
    return false;
  }

  /// Probes the source video's frame rate (frames per second). Falls back to
  /// 30 when it can't be determined; keeping the render fps equal to the
  /// source fps is what preserves audio sync through `zoompan`.
  static Future<int> probeFps(String input) async {
    try {
      final session = await FFprobeKit.getMediaInformation(input);
      final streams = session.getMediaInformation()?.getStreams() ?? [];
      for (final s in streams) {
        if (s.getType() == 'video') {
          final rate = s.getRealFrameRate() ?? s.getAverageFrameRate();
          final fps = _parseRate(rate);
          if (fps != null) return fps;
        }
      }
    } catch (e) {
      log("KeyframeService probeFps error: $e");
    }
    return 30;
  }

  /// Parses an FFmpeg frame-rate string like "30000/1001" or "25/1".
  static int? _parseRate(String? rate) {
    if (rate == null || !rate.contains('/')) return null;
    final parts = rate.split('/');
    final num = double.tryParse(parts[0]) ?? 0;
    final den = double.tryParse(parts[1]) ?? 0;
    if (num <= 0 || den <= 0) return null;
    final v = (num / den).round();
    return v > 0 ? v : null;
  }

  /// Renders the keyframe animation. Requires at least one keyframe. [outW] and
  /// [outH] should be even and preserve the source aspect ratio.
  static Future<String?> render(
    String input,
    List<Keyframe> kfs, {
    required int outW,
    required int outH,
  }) async {
    if (kfs.isEmpty) return null;
    final sorted = [...kfs]..sort((a, b) => a.t.compareTo(b.t));
    final fps = await probeFps(input);
    final filter = zoompanFilter(sorted, outW: outW, outH: outH, fps: fps);
    final out = "${await getOutputDirectoryPath()}keyframes.mp4";
    return await _run(renderCommand(input, out, filter)) ? out : null;
  }
}
