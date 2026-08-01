import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../services/vfx_service.dart';
import 'video_result_popup.dart';

/// Cinematic look: vignette + film grain.
class VfxScreen extends StatefulWidget {
  const VfxScreen({super.key, required this.video});

  final File video;

  @override
  State<VfxScreen> createState() => _VfxScreenState();
}

class _VfxScreenState extends State<VfxScreen> {
  VideoPlayerController? _controller;
  double _vignette = 0.5;
  double _grain = 8;
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

  Future<void> _apply() async {
    setState(() => _rendering = true);
    String? out;
    try {
      out = await VfxService.apply(
        widget.video.path,
        vignette: _vignette,
        grain: _grain.round(),
      );
    } catch (e) {
      log('VFX error: $e');
    }
    if (!mounted) return;
    setState(() => _rendering = false);
    if (out == null) {
      _snack("Couldn't apply the effect");
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
      appBar: AppBar(title: const Text('Vignette & Grain')),
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
                            // Approximate vignette preview.
                            if (_vignette > 0)
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    radius: 0.9,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withValues(
                                          alpha: 0.6 * _vignette),
                                    ],
                                    stops: const [0.6, 1.0],
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
                          const SizedBox(width: 74, child: Text('Vignette')),
                          Expanded(
                            child: Slider(
                              value: _vignette,
                              max: 1.0,
                              onChanged: _rendering
                                  ? null
                                  : (v) => setState(() => _vignette = v),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const SizedBox(width: 74, child: Text('Grain')),
                          Expanded(
                            child: Slider(
                              value: _grain,
                              max: 40,
                              onChanged: _rendering
                                  ? null
                                  : (v) => setState(() => _grain = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
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
                              : const Icon(Icons.movie_creation_outlined),
                          label: Text(_rendering ? 'Applying…' : 'Apply'),
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
