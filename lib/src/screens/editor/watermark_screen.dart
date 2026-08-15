import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../services/watermark_service.dart';
import 'video_result_popup.dart';

/// Overlay a logo / watermark image onto the video, with a live preview.
class WatermarkScreen extends StatefulWidget {
  const WatermarkScreen({super.key, required this.video});

  final File video;

  @override
  State<WatermarkScreen> createState() => _WatermarkScreenState();
}

class _WatermarkScreenState extends State<WatermarkScreen> {
  VideoPlayerController? _controller;
  File? _logo;
  String _corner = WatermarkService.bottomRight;
  double _size = 0.18;
  double _opacity = 0.7;
  bool _rendering = false;

  static const _cornerLabels = {
    WatermarkService.topLeft: 'Top L',
    WatermarkService.topRight: 'Top R',
    WatermarkService.bottomLeft: 'Bot L',
    WatermarkService.bottomRight: 'Bot R',
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

  Future<void> _pickLogo() async {
    final res = await FilePicker.pickFiles(type: FileType.image);
    final path = res?.files.single.path;
    if (path != null) setState(() => _logo = File(path));
  }

  Future<void> _apply() async {
    final logo = _logo;
    if (logo == null) {
      _snack('Pick a logo image first');
      return;
    }
    final size = _controller!.value.size;
    setState(() => _rendering = true);
    String? out;
    try {
      out = await WatermarkService.apply(
        widget.video.path,
        logo.path,
        mainW: size.width.round(),
        sizeFraction: _size,
        opacity: _opacity,
        corner: _corner,
      );
    } catch (e) {
      log('Watermark error: $e');
    }
    if (!mounted) return;
    setState(() => _rendering = false);
    if (out == null) {
      _snack("Couldn't add the watermark");
      return;
    }
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
      appBar: AppBar(title: const Text('Watermark / Logo')),
      body: !ready
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(child: _preview(c)),
                _controls(),
              ],
            ),
    );
  }

  Widget _preview(VideoPlayerController c) {
    return Container(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: c.value.aspectRatio == 0 ? 1 : c.value.aspectRatio,
          child: LayoutBuilder(
            builder: (context, cons) {
              final w = cons.maxWidth;
              final logo = _logo;
              final wmW = w * _size;
              final margin = w * 0.03;
              final left = _corner == WatermarkService.topLeft ||
                      _corner == WatermarkService.bottomLeft
                  ? margin
                  : null;
              final right = left == null ? margin : null;
              final top = _corner == WatermarkService.topLeft ||
                      _corner == WatermarkService.topRight
                  ? margin
                  : null;
              final bottom = top == null ? margin : null;
              return Stack(
                children: [
                  Positioned.fill(child: VideoPlayer(c)),
                  if (logo != null)
                    Positioned(
                      left: left,
                      right: right,
                      top: top,
                      bottom: bottom,
                      width: wmW,
                      child: Opacity(
                        opacity: _opacity,
                        child: Image.file(logo, fit: BoxFit.contain),
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

  Widget _controls() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: _rendering ? null : _pickLogo,
              icon: const Icon(Icons.image_outlined),
              label: Text(_logo == null ? 'Pick Logo Image' : 'Change Logo'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(width: 62, child: Text('Corner')),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    children: [
                      for (final c in WatermarkService.corners)
                        ChoiceChip(
                          label: Text(_cornerLabels[c]!),
                          selected: _corner == c,
                          onSelected: _rendering
                              ? null
                              : (_) => setState(() => _corner = c),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const SizedBox(width: 62, child: Text('Size')),
                Expanded(
                  child: Slider(
                    value: _size,
                    min: 0.06,
                    max: 0.4,
                    onChanged:
                        _rendering ? null : (v) => setState(() => _size = v),
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Text('${(_size * 100).round()}%',
                      textAlign: TextAlign.right),
                ),
              ],
            ),
            Row(
              children: [
                const SizedBox(width: 62, child: Text('Opacity')),
                Expanded(
                  child: Slider(
                    value: _opacity,
                    min: 0.1,
                    max: 1.0,
                    onChanged: _rendering
                        ? null
                        : (v) => setState(() => _opacity = v),
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Text('${(_opacity * 100).round()}%',
                      textAlign: TextAlign.right),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_logo == null || _rendering) ? null : _apply,
                icon: _rendering
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.branding_watermark_rounded),
                label: Text(_rendering ? 'Applying…' : 'Add Watermark'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
