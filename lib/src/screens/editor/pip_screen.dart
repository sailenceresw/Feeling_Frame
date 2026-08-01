import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../services/pip_service.dart';
import 'video_result_popup.dart';

/// Picture-in-Picture editor: overlay a second (inset) video on the main clip.
///
/// The preview stacks two live players so the corner, size, and circle-mask
/// choices are shown exactly as they'll render, then the export bakes it in
/// with FFmpeg's `overlay` filter via [PipService].
class PipScreen extends StatefulWidget {
  const PipScreen({super.key, required this.video});

  final File video;

  @override
  State<PipScreen> createState() => _PipScreenState();
}

class _PipScreenState extends State<PipScreen> {
  VideoPlayerController? _main;
  VideoPlayerController? _pip;
  File? _pipFile;

  String _corner = PipService.bottomRight;
  double _size = 0.3;
  bool _circle = false;
  bool _rendering = false;

  static const _cornerLabels = {
    PipService.topLeft: 'Top L',
    PipService.topRight: 'Top R',
    PipService.bottomLeft: 'Bot L',
    PipService.bottomRight: 'Bot R',
  };

  @override
  void initState() {
    super.initState();
    final c = VideoPlayerController.file(widget.video);
    _main = c;
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
    _main?.dispose();
    _pip?.dispose();
    super.dispose();
  }

  Future<void> _pickPip() async {
    final res = await FilePicker.pickFiles(type: FileType.video);
    final path = res?.files.single.path;
    if (path == null) return;
    await _pip?.dispose();
    final c = VideoPlayerController.file(File(path));
    _pip = c;
    _pipFile = File(path);
    await c.initialize();
    if (!mounted) return;
    c.setVolume(0);
    c.setLooping(true);
    c.play();
    setState(() {});
  }

  Future<void> _export() async {
    final pipFile = _pipFile;
    if (pipFile == null) {
      _snack('Pick an overlay video first');
      return;
    }
    final size = _main!.value.size;
    setState(() => _rendering = true);
    String? out;
    try {
      out = await PipService.applyPip(
        widget.video.path,
        pipFile.path,
        mainW: size.width.round(),
        sizeFraction: _size,
        corner: _corner,
        circle: _circle,
      );
    } catch (e) {
      log('PiP render error: $e');
    }
    if (!mounted) return;
    setState(() => _rendering = false);
    if (out == null) {
      _snack("Couldn't create the picture-in-picture");
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
    final main = _main;
    final ready = main != null && main.value.isInitialized;
    return Scaffold(
      appBar: AppBar(title: const Text('Picture-in-Picture')),
      body: !ready
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(child: _preview(main)),
                _controls(),
              ],
            ),
    );
  }

  Widget _preview(VideoPlayerController main) {
    return Container(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: main.value.aspectRatio == 0 ? 1 : main.value.aspectRatio,
          child: LayoutBuilder(
            builder: (context, cons) {
              final w = cons.maxWidth;
              final h = cons.maxHeight;
              final pip = _pip;
              final pipReady = pip != null && pip.value.isInitialized;
              final pipW = w * _size;
              final pipAspect = pipReady && pip.value.aspectRatio != 0
                  ? pip.value.aspectRatio
                  : 16 / 9;
              final pipH = _circle ? pipW : pipW / pipAspect;
              final margin = w * 0.03;
              final left = _corner == PipService.topLeft ||
                      _corner == PipService.bottomLeft
                  ? margin
                  : w - pipW - margin;
              final top = _corner == PipService.topLeft ||
                      _corner == PipService.topRight
                  ? margin
                  : h - pipH - margin;
              return Stack(
                children: [
                  Positioned.fill(child: VideoPlayer(main)),
                  if (pipReady)
                    Positioned(
                      left: left,
                      top: top,
                      width: pipW,
                      height: pipH,
                      child: _circle
                          ? ClipOval(child: _coverVideo(pip))
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: VideoPlayer(pip),
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

  Widget _coverVideo(VideoPlayerController c) {
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: SizedBox(
        width: c.value.size.width,
        height: c.value.size.height,
        child: VideoPlayer(c),
      ),
    );
  }

  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: _rendering ? null : _pickPip,
            icon: const Icon(Icons.video_library_outlined),
            label: Text(_pipFile == null ? 'Pick Overlay Video' : 'Change Overlay'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(width: 60, child: Text('Corner')),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  children: [
                    for (final c in PipService.corners)
                      ChoiceChip(
                        label: Text(_cornerLabels[c]!),
                        selected: _corner == c,
                        onSelected:
                            _rendering ? null : (_) => setState(() => _corner = c),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const SizedBox(width: 60, child: Text('Size')),
              Expanded(
                child: Slider(
                  value: _size,
                  min: 0.15,
                  max: 0.5,
                  onChanged: _rendering
                      ? null
                      : (v) => setState(() => _size = v),
                ),
              ),
              SizedBox(
                width: 44,
                child: Text('${(_size * 100).round()}%',
                    textAlign: TextAlign.right),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Circle mask'),
            value: _circle,
            onChanged:
                _rendering ? null : (v) => setState(() => _circle = v),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_pipFile == null || _rendering) ? null : _export,
              icon: _rendering
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.picture_in_picture_alt_rounded),
              label: Text(_rendering ? 'Rendering…' : 'Apply Picture-in-Picture'),
            ),
          ),
        ],
      ),
    );
  }
}
