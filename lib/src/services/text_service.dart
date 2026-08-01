import 'dart:developer';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

import '../utils/storage_path.dart';

/// Burns a text overlay / caption onto a video with FFmpeg's `drawtext`.
///
/// The overlay can be placed top / centre / bottom, sized, coloured, given a
/// translucent background box, and limited to a time window. `drawtext` needs a
/// real font file on disk, so the bundled Quicksand font is copied out of the
/// app assets on first use.
///
/// The sanitiser and command builders are pure static helpers for unit testing;
/// the font copy and FFmpeg run happen only at runtime.
class TextService {
  static const String top = 'top';
  static const String center = 'center';
  static const String bottom = 'bottom';

  /// Named colours offered in the UI (all understood by FFmpeg drawtext).
  static const List<String> colors = [
    'white',
    'black',
    'yellow',
    'red',
    'cyan',
    'orange',
  ];

  /// Makes arbitrary user text safe to embed inside a single-quoted `drawtext`
  /// value: drops backslashes, turns straight quotes into a typographic
  /// apostrophe (so they can't terminate the quoted value), and removes `%`
  /// (which would trigger drawtext's text expansion).
  static String sanitizeText(String input) {
    var s = input.replaceAll('\\', '');
    s = s.replaceAll("'", '’');
    s = s.replaceAll('%', '');
    return s.trim();
  }

  /// The drawtext x:y expression for [position], centred horizontally.
  static String positionXY(String position) {
    switch (position) {
      case top:
        return 'x=(w-text_w)/2:y=h*0.08';
      case center:
        return 'x=(w-text_w)/2:y=(h-text_h)/2';
      case bottom:
      default:
        return 'x=(w-text_w)/2:y=h*0.85';
    }
  }

  /// Builds the `drawtext` filter. [text] must already be sanitised.
  static String drawtextFilter({
    required String fontfile,
    required String text,
    required String position,
    required int fontsize,
    String color = 'white',
    bool box = true,
    double? start,
    double? end,
  }) {
    final buf = StringBuffer("drawtext=fontfile=$fontfile:text='$text'");
    buf.write(':${positionXY(position)}:fontsize=$fontsize:fontcolor=$color');
    if (box) buf.write(':box=1:boxcolor=black@0.5:boxborderw=12');
    if (start != null && end != null) {
      buf.write(":enable='between(t,${_n(start)},${_n(end)})'");
    }
    return buf.toString();
  }

  static String _n(double v) {
    var s = v.toStringAsFixed(2);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
    }
    return s.isEmpty ? '0' : s;
  }

  /// The full FFmpeg command wrapping [drawtext].
  static String textCommand(String input, String output, String drawtext) =>
      '-y -i $input -vf "$drawtext" '
      '-c:v libx264 -crf 20 -preset fast -c:a copy $output';

  static Future<bool> _run(String command) async {
    log('TextService command: $command');
    final session = await FFmpegKit.execute(command);
    final rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) return true;
    log('TextService failed: ${await session.getOutput()}');
    return false;
  }

  /// Copies the bundled Quicksand font to a temp file (once) and returns its
  /// on-disk path for drawtext.
  static Future<String> ensureFont() async {
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/Quicksand-Bold.ttf');
    if (!await f.exists()) {
      final data = await rootBundle.load('assets/fonts/Quicksand-Bold.ttf');
      await f.writeAsBytes(data.buffer.asUint8List());
    }
    return f.path;
  }

  /// Burns [text] onto [input] and returns the output path (or null).
  static Future<String?> addText(
    String input, {
    required String text,
    required String position,
    required int fontsize,
    String color = 'white',
    bool box = true,
    double? start,
    double? end,
  }) async {
    final safe = sanitizeText(text);
    if (safe.isEmpty) return null;
    final font = await ensureFont();
    final filter = drawtextFilter(
      fontfile: font,
      text: safe,
      position: position,
      fontsize: fontsize,
      color: color,
      box: box,
      start: start,
      end: end,
    );
    final out = '${await getOutputDirectoryPath()}text.mp4';
    return await _run(textCommand(input, out, filter)) ? out : null;
  }
}
