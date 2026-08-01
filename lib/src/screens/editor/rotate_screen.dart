import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../services/rotate_service.dart';
import 'video_result_popup.dart';

/// Rotate 90°/180° and straighten a tilted horizon.
class RotateScreen extends StatefulWidget {
  const RotateScreen({super.key, required this.video});

  final File video;

  @override
  State<RotateScreen> createState() => _RotateScreenState();
}

class _RotateScreenState extends State<RotateScreen> {
  VideoPlayerController? _controller;
  double _straighten = 0.0; // degrees
  bool _rendering = false;

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

  Future<void> _run(Future<String?> Function() op) async {
    setState(() => _rendering = true);
    String? out;
    try {
      out = await op();
    } catch (e) {
      log('Rotate error: $e');
    }
    if (!mounted) return;
    setState(() => _rendering = false);
    if (out == null) {
      _snack("Couldn't apply the rotation");
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
      appBar: AppBar(title: const Text('Rotate & Straighten')),
      body: !ready
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.black,
                    child: Center(
                      child: ClipRect(
                        child: Transform.rotate(
                          angle: _straighten * math.pi / 180,
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
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _rotBtn('90° Left', Icons.rotate_left_rounded, 3),
                          _rotBtn('90° Right', Icons.rotate_right_rounded, 1),
                          _rotBtn('180°', Icons.flip_camera_android_rounded, 2),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const SizedBox(width: 74, child: Text('Straighten')),
                          Expanded(
                            child: Slider(
                              value: _straighten,
                              min: -10,
                              max: 10,
                              onChanged: _rendering
                                  ? null
                                  : (v) => setState(() => _straighten = v),
                            ),
                          ),
                          SizedBox(
                            width: 40,
                            child: Text('${_straighten.toStringAsFixed(0)}°',
                                textAlign: TextAlign.right),
                          ),
                        ],
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: (_rendering || _straighten == 0)
                              ? null
                              : () {
                                  final size = _controller!.value.size;
                                  _run(() => RotateService.straighten(
                                        widget.video.path,
                                        w: size.width.round(),
                                        h: size.height.round(),
                                        degrees: _straighten,
                                      ));
                                },
                          icon: _rendering
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.straighten_rounded),
                          label: Text(
                              _rendering ? 'Applying…' : 'Apply Straighten'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _rotBtn(String label, IconData icon, int quarterTurns) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          onPressed: _rendering
              ? null
              : () => _run(
                  () => RotateService.rotateQuarter(widget.video.path, quarterTurns)),
          icon: Icon(icon),
        ),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
