import 'dart:developer';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

import '../utils/srt_builder.dart';
import '../utils/storage_path.dart';

/// A single timed caption cue.
class CaptionSegment {
  const CaptionSegment({
    required this.start,
    required this.end,
    required this.text,
  });

  final double start; // seconds
  final double end; // seconds
  final String text;

  CaptionSegment copyWith({double? start, double? end, String? text}) =>
      CaptionSegment(
        start: start ?? this.start,
        end: end ?? this.end,
        text: text ?? this.text,
      );
}

/// On-device, cloud-free captions: build/parse SRT, style it, and burn it into
/// the video with FFmpeg's `subtitles` (libass) filter. All the string work is
/// in pure static helpers for unit testing.
///
/// This replaces the need for the old Google Cloud speech transcription path:
/// captions can be typed, pasted-and-auto-timed, or imported from an SRT, and
/// are rendered entirely on the device.
class CaptionService {
  // ASS colours are &HAABBGGRR (AA=00 opaque, then Blue Green Red).
  static const Map<String, String> assColors = {
    'white': '&H00FFFFFF',
    'yellow': '&H0000FFFF',
    'black': '&H00000000',
    'red': '&H000000FF',
    'cyan': '&H00FFFF00',
    'green': '&H0000FF00',
  };

  static const String bottom = 'bottom';
  static const String center = 'center';
  static const String top = 'top';

  // ---- SRT (pure) ----------------------------------------------------------

  /// Serialises [segments] to SRT text (sorted by start time).
  static String toSrt(List<CaptionSegment> segments) {
    if (segments.isEmpty) return '';
    final sorted = [...segments]..sort((a, b) => a.start.compareTo(b.start));
    final buf = StringBuffer();
    var i = 1;
    for (final s in sorted) {
      buf
        ..writeln(i++)
        ..writeln('${srtTimestamp(s.start)} --> ${srtTimestamp(s.end)}')
        ..writeln(s.text.trim())
        ..writeln();
    }
    return buf.toString();
  }

  static final RegExp _timeRe = RegExp(
    r'(\d{2}):(\d{2}):(\d{2})[,.](\d{3})\s*-->\s*(\d{2}):(\d{2}):(\d{2})[,.](\d{3})',
  );

  /// Parses SRT (or VTT-ish) [content] into segments. Tolerant of both `,` and
  /// `.` millisecond separators and of stray index lines.
  static List<CaptionSegment> parseSrt(String content) {
    final segments = <CaptionSegment>[];
    final blocks =
        content.replaceAll('\r\n', '\n').trim().split(RegExp(r'\n[ \t]*\n'));
    for (final block in blocks) {
      final lines = block.split('\n');
      var tIdx = -1;
      for (var i = 0; i < lines.length; i++) {
        if (_timeRe.hasMatch(lines[i])) {
          tIdx = i;
          break;
        }
      }
      if (tIdx < 0) continue;
      final m = _timeRe.firstMatch(lines[tIdx])!;
      final start = _hmsToSeconds(m, 1);
      final end = _hmsToSeconds(m, 5);
      final text = lines.sublist(tIdx + 1).join('\n').trim();
      if (text.isEmpty) continue;
      segments.add(CaptionSegment(start: start, end: end, text: text));
    }
    return segments;
  }

  static double _hmsToSeconds(Match m, int g) =>
      int.parse(m.group(g)!) * 3600 +
      int.parse(m.group(g + 1)!) * 60 +
      int.parse(m.group(g + 2)!) +
      int.parse(m.group(g + 3)!) / 1000.0;

  /// Splits a block of [text] into evenly-timed cues across [totalSeconds]
  /// (~[wordsPerCue] words each) — a quick way to caption from a script.
  static List<CaptionSegment> distribute(
    String text,
    double totalSeconds, {
    int wordsPerCue = 6,
  }) {
    final words = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty || totalSeconds <= 0) return [];
    final cues = <List<String>>[];
    for (var i = 0; i < words.length; i += wordsPerCue) {
      cues.add(words.sublist(i, (i + wordsPerCue).clamp(0, words.length)));
    }
    final per = totalSeconds / cues.length;
    return [
      for (var i = 0; i < cues.length; i++)
        CaptionSegment(
          start: i * per,
          end: (i + 1) * per,
          text: cues[i].join(' '),
        ),
    ];
  }

  // ---- Styling + command (pure) --------------------------------------------

  /// Builds a libass `force_style` string for the `subtitles` filter.
  static String forceStyle({
    int fontSize = 24,
    String color = 'white',
    int outline = 2,
    String position = bottom,
  }) {
    final align = position == top
        ? 8
        : position == center
            ? 5
            : 2;
    final colour = assColors[color] ?? assColors['white']!;
    return 'FontName=Quicksand,FontSize=$fontSize,'
        'PrimaryColour=$colour,Outline=$outline,BorderStyle=1,Alignment=$align';
  }

  /// The FFmpeg command that burns [srtPath] into [input] with optional
  /// [style] (a force_style string).
  static String burnCommand(
    String input,
    String output,
    String srtPath, {
    String style = '',
  }) {
    final styleArg = style.isEmpty ? '' : ":force_style='$style'";
    return '-y -i $input -vf "subtitles=$srtPath$styleArg" '
        '-c:v libx264 -crf 20 -preset fast -c:a copy $output';
  }

  // ---- Runner --------------------------------------------------------------

  static Future<bool> _run(String command) async {
    log('CaptionService command: $command');
    final session = await FFmpegKit.execute(command);
    final rc = await session.getReturnCode();
    if (ReturnCode.isSuccess(rc)) return true;
    log('CaptionService failed: ${await session.getOutput()}');
    return false;
  }

  /// Writes [segments] to an SRT file and burns them into [input]. Returns the
  /// output path (or null).
  static Future<String?> burnSegments(
    String input,
    List<CaptionSegment> segments, {
    int fontSize = 24,
    String color = 'white',
    String position = bottom,
  }) async {
    if (segments.isEmpty) return null;
    final dir = await getOutputDirectoryPath();
    final srtPath = '${dir}captions_edit.srt';
    await File(srtPath).writeAsString(toSrt(segments));
    final out = '${dir}captioned.mp4';
    final style =
        forceStyle(fontSize: fontSize, color: color, position: position);
    return await _run(burnCommand(input, out, srtPath, style: style))
        ? out
        : null;
  }
}
