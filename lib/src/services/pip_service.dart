import 'dart:developer';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../utils/storage_path.dart';

/// Picture-in-Picture: overlays a second (inset) video on top of the main clip
/// with FFmpeg's `overlay` filter — reaction / webcam style. The inset can sit
/// in any corner, be sized as a fraction of the main width, and be optionally
/// masked to a circle.
///
/// Command construction is a pure static helper for unit testing.
class PipService {
  static const String topLeft = 'topLeft';
  static const String topRight = 'topRight';
  static const String bottomLeft = 'bottomLeft';
  static const String bottomRight = 'bottomRight';

  static const List<String> corners = [
    topLeft,
    topRight,
    bottomLeft,
    bottomRight,
  ];

  /// The overlay x:y expression for [corner] with a [margin] (in pixels). Uses
  /// the overlay filter's W/H (main) and w/h (inset) variables.
  static String overlayXY(String corner, int margin) {
    switch (corner) {
      case topLeft:
        return '$margin:$margin';
      case topRight:
        return 'W-w-$margin:$margin';
      case bottomLeft:
        return '$margin:H-h-$margin';
      case bottomRight:
      default:
        return 'W-w-$margin:H-h-$margin';
    }
  }

  /// Even inset width in pixels for a [sizeFraction] of [mainW].
  static int insetWidth(int mainW, double sizeFraction) {
    var s = (mainW * sizeFraction).round();
    if (s.isOdd) s -= 1;
    return s < 2 ? 2 : s;
  }

  /// Builds the FFmpeg PiP command. [main] is the base clip, [pip] the inset.
  /// When [circle] is true the inset is scaled to a square and alpha-masked to
  /// a circle via `geq`; otherwise it keeps its aspect ratio. The main clip's
  /// audio is kept (the inset's audio is dropped).
  static String pipCommand(
    String main,
    String pip,
    String output, {
    required int mainW,
    double sizeFraction = 0.3,
    String corner = bottomRight,
    int? margin,
    bool circle = false,
  }) {
    final s = insetWidth(mainW, sizeFraction);
    final m = margin ?? (mainW * 0.03).round();
    final xy = overlayXY(corner, m);

    final String pipChain;
    if (circle) {
      pipChain = '[1:v]scale=$s:$s,format=rgba,'
          "geq=r='r(X,Y)':g='g(X,Y)':b='b(X,Y)':"
          "a='if(lte(hypot(X-$s/2,Y-$s/2),$s/2),255,0)'[pip]";
    } else {
      pipChain = '[1:v]scale=$s:-2[pip]';
    }

    return '-y -i $main -i $pip -filter_complex '
        '"$pipChain;[0:v][pip]overlay=$xy[v]" '
        '-map "[v]" -map 0:a? -c:v libx264 -crf 20 -preset fast -c:a copy '
        '$output';
  }

  static Future<bool> _run(String command) async {
    log('PipService command: $command');
    final session = await FFmpegKit.execute(command);
    final rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) return true;
    log('PipService failed: ${await session.getOutput()}');
    return false;
  }

  /// Renders the PiP and returns the output path (or null). If a circle mask
  /// was requested but fails (the per-pixel `geq` mask can be fragile on some
  /// builds), it retries with a plain rectangular inset so the op still works.
  static Future<String?> applyPip(
    String main,
    String pip, {
    required int mainW,
    double sizeFraction = 0.3,
    String corner = bottomRight,
    bool circle = false,
  }) async {
    final out = '${await getOutputDirectoryPath()}pip.mp4';
    if (await _run(pipCommand(main, pip, out,
        mainW: mainW,
        sizeFraction: sizeFraction,
        corner: corner,
        circle: circle))) {
      return out;
    }
    if (circle) {
      if (await _run(pipCommand(main, pip, out,
          mainW: mainW,
          sizeFraction: sizeFraction,
          corner: corner,
          circle: false))) {
        return out;
      }
    }
    return null;
  }
}
