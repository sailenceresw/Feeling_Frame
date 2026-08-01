import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../services/caption_service.dart';
import '../../services/stt_service.dart';
import '../../services/stt_sherpa.dart';
import 'video_result_popup.dart';

/// On-device caption studio: type / paste / import timed captions, preview them
/// live over the video, style them, and burn them in — no cloud, no upload.
class CaptionStudioScreen extends StatefulWidget {
  const CaptionStudioScreen({super.key, required this.video});

  final File video;

  @override
  State<CaptionStudioScreen> createState() => _CaptionStudioScreenState();
}

class _CaptionStudioScreenState extends State<CaptionStudioScreen> {
  VideoPlayerController? _controller;
  final List<CaptionSegment> _segments = [];

  double _t = 0.0;
  double _duration = 0.0;
  int _fontSize = 26;
  String _color = 'white';
  String _position = CaptionService.bottom;
  bool _rendering = false;
  bool _aiBusy = false;
  double? _modelProgress;
  SherpaSpeechRecognizer? _recognizer;

  static const _colorMap = {
    'white': Colors.white,
    'yellow': Colors.yellow,
    'black': Colors.black,
    'red': Colors.red,
    'cyan': Colors.cyan,
    'green': Colors.green,
  };

  @override
  void initState() {
    super.initState();
    final c = VideoPlayerController.file(widget.video);
    _controller = c;
    c.initialize().then((_) {
      if (!mounted) return;
      c.setVolume(0);
      c.setLooping(true);
      c.addListener(_tick);
      c.play();
      setState(() => _duration = c.value.duration.inMilliseconds / 1000.0);
    });
  }

  void _tick() {
    if (!mounted) return;
    final p = _controller?.value.position.inMilliseconds ?? 0;
    setState(() => _t = p / 1000.0);
  }

  @override
  void dispose() {
    _controller?.removeListener(_tick);
    _controller?.dispose();
    _recognizer?.dispose();
    super.dispose();
  }

  CaptionSegment? get _currentCaption {
    for (final s in _segments) {
      if (_t >= s.start && _t <= s.end) return s;
    }
    return null;
  }

  Alignment get _overlayAlign {
    switch (_position) {
      case CaptionService.top:
        return Alignment.topCenter;
      case CaptionService.center:
        return Alignment.center;
      default:
        return Alignment.bottomCenter;
    }
  }

  Future<void> _editSegment({CaptionSegment? existing}) async {
    final now = _t;
    final textCtl =
        TextEditingController(text: existing?.text ?? '');
    var start = existing?.start ?? now;
    var end = existing?.end ?? (now + 2).clamp(0.0, _duration);

    final result = await showDialog<CaptionSegment>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'Add caption' : 'Edit caption'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textCtl,
                autofocus: true,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Caption text',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Text('Start: ${start.toStringAsFixed(2)}s'),
              Slider(
                value: start.clamp(0.0, _duration),
                max: _duration <= 0 ? 1 : _duration,
                onChanged: (v) => setLocal(() {
                  start = v;
                  if (end < start) end = start;
                }),
              ),
              Text('End: ${end.toStringAsFixed(2)}s'),
              Slider(
                value: end.clamp(0.0, _duration),
                max: _duration <= 0 ? 1 : _duration,
                onChanged: (v) => setLocal(() {
                  end = v;
                  if (start > end) start = end;
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (textCtl.text.trim().isEmpty) return;
                Navigator.pop(
                  ctx,
                  CaptionSegment(
                    start: start,
                    end: end < start ? start + 0.5 : end,
                    text: textCtl.text.trim(),
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (existing != null) _segments.remove(existing);
        _segments.add(result);
        _segments.sort((a, b) => a.start.compareTo(b.start));
      });
    }
  }

  Future<void> _pasteScript() async {
    final ctl = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Paste script → auto-time'),
        content: TextField(
          controller: ctl,
          autofocus: true,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Paste your script here…',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctl.text),
            child: const Text('Distribute'),
          ),
        ],
      ),
    );
    if (text != null && text.trim().isNotEmpty) {
      final segs = CaptionService.distribute(text, _duration);
      setState(() {
        _segments
          ..clear()
          ..addAll(segs);
      });
    }
  }

  Future<void> _importSrt() async {
    final res = await FilePicker.pickFiles(type: FileType.any);
    final path = res?.files.single.path;
    if (path == null) return;
    try {
      final content = await File(path).readAsString();
      final segs = CaptionService.parseSrt(content);
      if (segs.isEmpty) {
        _snack('No captions found in that file');
        return;
      }
      setState(() {
        _segments
          ..clear()
          ..addAll(segs);
      });
    } catch (e) {
      log('SRT import error: $e');
      _snack("Couldn't read that file");
    }
  }

  Future<void> _burn() async {
    if (_segments.isEmpty) {
      _snack('Add at least one caption first');
      return;
    }
    setState(() => _rendering = true);
    String? out;
    try {
      out = await CaptionService.burnSegments(
        widget.video.path,
        _segments,
        fontSize: _fontSize,
        color: _color,
        position: _position,
      );
    } catch (e) {
      log('Caption burn error: $e');
    }
    if (!mounted) return;
    setState(() => _rendering = false);
    if (out == null) {
      _snack("Couldn't add the captions");
      return;
    }
    final size = _controller!.value.size;
    showDialog(
      context: context,
      builder: (_) => VideoResultPopup(
        video: File(out!),
        aspectRatio: size.height == 0 ? 1 : size.width / size.height,
      ),
    );
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  /// On-device AI: transcribe the clip's speech and fill the caption timeline.
  /// Downloads the ~40 MB model once (with confirmation) on first use.
  Future<void> _autoGenerate() async {
    final recognizer = _recognizer ??= SherpaSpeechRecognizer(
      onModelProgress: (f) {
        if (mounted) setState(() => _modelProgress = f);
      },
    );

    if (!await recognizer.isReady()) {
      if (!mounted) return;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Download AI captions model?'),
          content: const Text(
            'On-device speech-to-text needs a one-time ~40 MB model download. '
            'It then runs fully offline — nothing is uploaded.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Download'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      setState(() {
        _aiBusy = true;
        _modelProgress = 0;
      });
      final got = await recognizer.ensureModel();
      if (!mounted) return;
      if (!got) {
        setState(() => _aiBusy = false);
        _snack('Model download failed — check your connection');
        return;
      }
    }

    setState(() {
      _aiBusy = true;
      _modelProgress = null;
    });
    List<CaptionSegment>? segs;
    try {
      segs = await SttService.transcribeToCaptions(widget.video.path, recognizer);
    } catch (e) {
      log('Auto-caption error: $e');
    }
    if (!mounted) return;
    setState(() => _aiBusy = false);
    if (segs == null || segs.isEmpty) {
      _snack('No speech detected');
      return;
    }
    setState(() {
      _segments
        ..clear()
        ..addAll(segs!);
    });
    _snack('Generated ${segs.length} captions');
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final ready = c != null && c.value.isInitialized;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Captions'),
        actions: [
          IconButton(
            tooltip: 'Auto-generate (on-device AI)',
            onPressed: (_rendering || _aiBusy) ? null : _autoGenerate,
            icon: const Icon(Icons.auto_awesome),
          ),
          IconButton(
            tooltip: 'Import SRT',
            onPressed: _rendering ? null : _importSrt,
            icon: const Icon(Icons.file_upload_outlined),
          ),
        ],
      ),
      body: !ready
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  children: [
                    _preview(c),
                    _styleBar(),
                    Expanded(child: _segmentList()),
                    _bottomBar(),
                  ],
                ),
                if (_aiBusy) _aiOverlay(),
              ],
            ),
    );
  }

  Widget _aiOverlay() {
    final p = _modelProgress;
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black54,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(value: p),
              const SizedBox(height: 12),
              Text(
                p != null
                    ? 'Downloading model… ${(p * 100).round()}%'
                    : 'Transcribing on-device…',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _preview(VideoPlayerController c) {
    final caption = _currentCaption;
    return Container(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: c.value.aspectRatio == 0 ? 1 : c.value.aspectRatio,
          child: LayoutBuilder(
            builder: (context, cons) {
              final videoH = c.value.size.height;
              final previewFont = videoH > 0
                  ? _fontSize * cons.maxHeight / videoH
                  : _fontSize.toDouble();
              return Stack(
                children: [
                  Positioned.fill(child: VideoPlayer(c)),
                  if (caption != null)
                    Align(
                      alignment: _overlayAlign,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          color: Colors.black54,
                          child: Text(
                            caption.text,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: previewFont,
                              color: _colorMap[_color],
                              fontWeight: FontWeight.bold,
                              height: 1.15,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _styleBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Size'),
              Expanded(
                child: Slider(
                  value: _fontSize.toDouble(),
                  min: 14,
                  max: 64,
                  onChanged: _rendering
                      ? null
                      : (v) => setState(() => _fontSize = v.round()),
                ),
              ),
              for (final name in _colorMap.keys)
                GestureDetector(
                  onTap: _rendering ? null : () => setState(() => _color = name),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _colorMap[name],
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _color == name ? Colors.blue : Colors.grey,
                        width: _color == name ? 3 : 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Row(
            children: [
              const Text('Position'),
              const SizedBox(width: 8),
              for (final p in const [
                CaptionService.top,
                CaptionService.center,
                CaptionService.bottom
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ChoiceChip(
                    label: Text(p[0].toUpperCase() + p.substring(1)),
                    selected: _position == p,
                    onSelected: _rendering
                        ? null
                        : (_) => setState(() => _position = p),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _segmentList() {
    if (_segments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No captions yet.\nAdd one at the playhead, paste a script, or '
            'import an SRT.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: _segments.length,
      itemBuilder: (context, i) {
        final s = _segments[i];
        final active = _t >= s.start && _t <= s.end;
        return ListTile(
          dense: true,
          tileColor: active ? Colors.blue.withValues(alpha: 0.12) : null,
          title: Text(s.text, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text(
              '${s.start.toStringAsFixed(1)}s → ${s.end.toStringAsFixed(1)}s'),
          onTap: () => _editSegment(existing: s),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => setState(() => _segments.remove(s)),
          ),
        );
      },
    );
  }

  Widget _bottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _rendering ? null : () => _editSegment(),
                    icon: const Icon(Icons.add),
                    label: const Text('At playhead'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _rendering ? null : _pasteScript,
                    icon: const Icon(Icons.notes_rounded),
                    label: const Text('Paste script'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _rendering ? null : _burn,
                icon: _rendering
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.closed_caption_rounded),
                label: Text(_rendering ? 'Burning…' : 'Burn Captions'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
