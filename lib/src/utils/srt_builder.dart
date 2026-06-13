/// Pure helpers to build SRT subtitle files from word-level timings.
/// Kept free of I/O so they can be unit tested.

/// Formats [seconds] as an SRT timestamp: HH:MM:SS,mmm.
String srtTimestamp(double seconds) {
  final d = Duration(milliseconds: (seconds * 1000).round());
  final h = d.inHours.toString().padLeft(2, '0');
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  final ms = d.inMilliseconds.remainder(1000).toString().padLeft(3, '0');
  return '$h:$m:$s,$ms';
}

/// Groups word timings into short caption cues and renders SRT content.
///
/// Each entry of [words] must contain:
/// - 'word'  : String
/// - 'start' : double (seconds)
/// - 'end'   : double (seconds)
///
/// A new cue starts once a chunk reaches [maxWords] words or spans more than
/// [maxSpanSeconds]. Returns an empty string when [words] is empty.
String buildSrt(
  List<Map<String, dynamic>> words, {
  int maxWords = 7,
  double maxSpanSeconds = 3.5,
}) {
  if (words.isEmpty) return '';

  final buffer = StringBuffer();
  int index = 1;
  List<Map<String, dynamic>> chunk = [];

  void flushChunk() {
    if (chunk.isEmpty) return;
    buffer
      ..writeln(index++)
      ..writeln('${srtTimestamp(chunk.first['start'] as double)} --> '
          '${srtTimestamp(chunk.last['end'] as double)}')
      ..writeln(chunk.map((w) => w['word']).join(' '))
      ..writeln();
    chunk = [];
  }

  for (final w in words) {
    chunk.add(w);
    final span = (w['end'] as double) - (chunk.first['start'] as double);
    if (chunk.length >= maxWords || span >= maxSpanSeconds) flushChunk();
  }
  flushChunk();

  return buffer.toString();
}
