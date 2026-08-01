import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../services/text_service.dart';
import '../../services/thumbnail_service.dart';
import 'video_result_popup.dart';

/// Design a cover/thumbnail: scrub to a frame, add a title, export an image.
class ThumbnailDesignerScreen extends StatefulWidget {
  const ThumbnailDesignerScreen({super.key, required this.video});

  final File video;

  @override
  State<ThumbnailDesignerScreen> createState() =>
      _ThumbnailDesignerScreenState();
}

class _ThumbnailDesignerScreenState extends State<ThumbnailDesignerScreen> {
  VideoPlayerController? _controller;
  final _title = TextEditingController();
  double _t = 0;
  double _duration = 0;
  String _position = TextService.bottom;
  bool _rendering = false;

  @override
  void initState() {
    super.initState();
    final c = VideoPlayerController.file(widget.video);
    _controller = c;
    c.initialize().then((_) {
      if (!mounted) return;
      c.setVolume(0);
      c.seekTo(Duration.zero);
      setState(() => _duration = c.value.duration.inMilliseconds / 1000.0);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _title.dispose();
    super.dispose();
  }

  void _seek(double t) {
    _controller?.seekTo(Duration(milliseconds: (t * 1000).round()));
    setState(() => _t = t);
  }

  Future<void> _generate() async {
    final size = _controller!.value.size;
    final fontSize = (size.height * 0.09).round().clamp(12, 4000);
    setState(() => _rendering = true);
    String? out;
    try {
      out = await ThumbnailService.generate(
        widget.video.path,
        seconds: _t,
        title: _title.text,
        position: _position,
        fontSize: fontSize,
      );
    } catch (e) {
      log('Thumbnail error: $e');
    }
    if (!mounted) return;
    setState(() => _rendering = false);
    if (out == null) {
      _snack("Couldn't create the cover");
      return;
    }
    showDialog(
      context: context,
      builder: (_) => CoverResultPopup(cover: File(out!)),
    );
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  Alignment get _align {
    switch (_position) {
      case TextService.top:
        return Alignment.topCenter;
      case TextService.center:
        return Alignment.center;
      default:
        return Alignment.bottomCenter;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final ready = c != null && c.value.isInitialized;
    final dur = _duration <= 0 ? 1.0 : _duration;
    return Scaffold(
      appBar: AppBar(title: const Text('Thumbnail / Cover')),
      body: !ready
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.black,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio:
                            c.value.aspectRatio == 0 ? 1 : c.value.aspectRatio,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            VideoPlayer(c),
                            if (_title.text.trim().isNotEmpty)
                              Align(
                                alignment: _align,
                                child: Container(
                                  margin: const EdgeInsets.all(16),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  color: Colors.black54,
                                  child: Text(
                                    _title.text,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('Frame'),
                          Expanded(
                            child: Slider(
                              value: _t.clamp(0, dur),
                              max: dur,
                              onChanged: _rendering ? null : _seek,
                            ),
                          ),
                          Text('${_t.toStringAsFixed(1)}s'),
                        ],
                      ),
                      TextField(
                        controller: _title,
                        onChanged: (_) => setState(() {}),
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Title (optional)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Position'),
                          const SizedBox(width: 8),
                          for (final p in const [
                            TextService.top,
                            TextService.center,
                            TextService.bottom
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label:
                                    Text(p[0].toUpperCase() + p.substring(1)),
                                selected: _position == p,
                                onSelected: _rendering
                                    ? null
                                    : (_) => setState(() => _position = p),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _rendering ? null : _generate,
                          icon: _rendering
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.image_rounded),
                          label: Text(_rendering ? 'Saving…' : 'Save Cover'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
