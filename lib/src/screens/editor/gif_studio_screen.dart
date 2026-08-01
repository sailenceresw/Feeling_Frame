import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../services/gif_studio_service.dart';
import 'video_result_popup.dart';

/// Export a GIF with fps / width / loop / quality controls.
class GifStudioScreen extends StatefulWidget {
  const GifStudioScreen({super.key, required this.video});

  final File video;

  @override
  State<GifStudioScreen> createState() => _GifStudioScreenState();
}

class _GifStudioScreenState extends State<GifStudioScreen> {
  VideoPlayerController? _controller;
  double _fps = 12;
  int _width = 480;
  bool _infinite = true;
  bool _highQuality = true;
  bool _rendering = false;

  static const _widths = {320: 'Small', 480: 'Medium', 640: 'Large'};

  @override
  void initState() {
    super.initState();
    final c = VideoPlayerController.file(widget.video);
    _controller = c;
    c.initialize().then((_) {
      if (!mounted) return;
      c.setVolume(0);
      c.setLooping(true);
      c.play();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    setState(() => _rendering = true);
    String? out;
    try {
      out = await GifStudioService.export(
        widget.video.path,
        fps: _fps.round(),
        width: _width,
        loop: _infinite ? 0 : -1,
        highQuality: _highQuality,
      );
    } catch (e) {
      log('GIF error: $e');
    }
    if (!mounted) return;
    setState(() => _rendering = false);
    if (out == null) {
      _snack("Couldn't create the GIF");
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

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final ready = c != null && c.value.isInitialized;
    return Scaffold(
      appBar: AppBar(title: const Text('GIF Studio')),
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
                        child: VideoPlayer(c),
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
                          const SizedBox(width: 60, child: Text('FPS')),
                          Expanded(
                            child: Slider(
                              value: _fps,
                              min: 5,
                              max: 24,
                              divisions: 19,
                              label: '${_fps.round()}',
                              onChanged: _rendering
                                  ? null
                                  : (v) => setState(() => _fps = v),
                            ),
                          ),
                          SizedBox(
                              width: 34,
                              child: Text('${_fps.round()}',
                                  textAlign: TextAlign.right)),
                        ],
                      ),
                      Row(
                        children: [
                          const Text('Size'),
                          const SizedBox(width: 8),
                          for (final e in _widths.entries)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(e.value),
                                selected: _width == e.key,
                                onSelected: _rendering
                                    ? null
                                    : (_) => setState(() => _width = e.key),
                              ),
                            ),
                        ],
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: const Text('Loop forever'),
                        value: _infinite,
                        onChanged: _rendering
                            ? null
                            : (v) => setState(() => _infinite = v),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: const Text('High quality (palette)'),
                        value: _highQuality,
                        onChanged: _rendering
                            ? null
                            : (v) => setState(() => _highQuality = v),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _rendering ? null : _export,
                          icon: _rendering
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.gif_box_rounded),
                          label: Text(_rendering ? 'Exporting…' : 'Export GIF'),
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
