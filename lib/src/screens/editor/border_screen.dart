import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../services/border_service.dart';
import 'video_result_popup.dart';

/// Add a colored or blurred border/frame around the video.
class BorderScreen extends StatefulWidget {
  const BorderScreen({super.key, required this.video});

  final File video;

  @override
  State<BorderScreen> createState() => _BorderScreenState();
}

class _BorderScreenState extends State<BorderScreen> {
  VideoPlayerController? _controller;
  double _border = 40;
  String _color = 'white';
  bool _blurred = false;
  bool _rendering = false;

  static const _colorMap = {
    'white': Colors.white,
    'black': Colors.black,
    'red': Colors.red,
    'yellow': Colors.yellow,
    'cyan': Colors.cyan,
    'pink': Colors.pink,
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
      c.play();
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    setState(() => _rendering = true);
    String? out;
    try {
      out = await BorderService.apply(
        widget.video.path,
        border: _border.round(),
        color: _color,
        blurred: _blurred,
      );
    } catch (e) {
      log('Border error: $e');
    }
    if (!mounted) return;
    setState(() => _rendering = false);
    if (out == null) {
      _snack("Couldn't add the border");
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
    final previewBorder = (_border / 12).clamp(0, 40).toDouble();
    return Scaffold(
      appBar: AppBar(title: const Text('Frame / Border')),
      body: !ready
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.black,
                    padding: EdgeInsets.all(previewBorder),
                    child: Center(
                      child: Container(
                        color: _blurred
                            ? Colors.grey.shade800
                            : _colorMap[_color],
                        padding: EdgeInsets.all(previewBorder),
                        child: AspectRatio(
                          aspectRatio: c.value.aspectRatio == 0
                              ? 1
                              : c.value.aspectRatio,
                          child: VideoPlayer(c),
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
                          const SizedBox(width: 64, child: Text('Width')),
                          Expanded(
                            child: Slider(
                              value: _border,
                              min: 4,
                              max: 160,
                              onChanged: _rendering
                                  ? null
                                  : (v) => setState(() => _border = v),
                            ),
                          ),
                          SizedBox(
                            width: 44,
                            child: Text('${_border.round()}px',
                                textAlign: TextAlign.right),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const SizedBox(width: 64, child: Text('Style')),
                          ChoiceChip(
                            label: const Text('Color'),
                            selected: !_blurred,
                            onSelected: _rendering
                                ? null
                                : (_) => setState(() => _blurred = false),
                          ),
                          const SizedBox(width: 6),
                          ChoiceChip(
                            label: const Text('Blurred'),
                            selected: _blurred,
                            onSelected: _rendering
                                ? null
                                : (_) => setState(() => _blurred = true),
                          ),
                        ],
                      ),
                      if (!_blurred) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final name in BorderService.colors)
                              GestureDetector(
                                onTap: _rendering
                                    ? null
                                    : () => setState(() => _color = name),
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: _colorMap[name],
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _color == name
                                          ? Colors.blue
                                          : Colors.grey,
                                      width: _color == name ? 3 : 1,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _rendering ? null : _apply,
                          icon: _rendering
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.crop_din_rounded),
                          label: Text(_rendering ? 'Applying…' : 'Add Border'),
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
