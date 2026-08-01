import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../services/crop_service.dart';
import 'video_result_popup.dart';

/// Free crop to a draggable/resizable box.
class CropRegionScreen extends StatefulWidget {
  const CropRegionScreen({super.key, required this.video});

  final File video;

  @override
  State<CropRegionScreen> createState() => _CropRegionScreenState();
}

class _CropRegionScreenState extends State<CropRegionScreen> {
  VideoPlayerController? _controller;
  double _left = 0.1;
  double _top = 0.1;
  double _w = 0.8;
  double _h = 0.8;
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
    final size = _controller!.value.size;
    final sw = size.width, sh = size.height;
    final rx = (_left * sw).round().clamp(0, sw.round());
    final ry = (_top * sh).round().clamp(0, sh.round());
    final rw = (_w * sw).round().clamp(2, sw.round() - rx);
    final rh = (_h * sh).round().clamp(2, sh.round() - ry);
    setState(() => _rendering = true);
    String? out;
    try {
      out = await CropService.crop(widget.video.path,
          rx: rx, ry: ry, rw: rw, rh: rh);
    } catch (e) {
      log('Crop error: $e');
    }
    if (!mounted) return;
    setState(() => _rendering = false);
    if (out == null) {
      _snack("Couldn't crop this clip");
      return;
    }
    showDialog(
      context: context,
      builder: (_) => VideoResultPopup(
        video: File(out!),
        aspectRatio: rh == 0 ? 1 : rw / rh,
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
      appBar: AppBar(title: const Text('Crop')),
      body: !ready
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Container(
                    color: Colors.black,
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: c.value.aspectRatio == 0
                            ? 1
                            : c.value.aspectRatio,
                        child: LayoutBuilder(
                          builder: (context, cons) {
                            final pw = cons.maxWidth, ph = cons.maxHeight;
                            return Stack(
                              children: [
                                Positioned.fill(child: VideoPlayer(c)),
                                Positioned(
                                  left: _left * pw,
                                  top: _top * ph,
                                  width: _w * pw,
                                  height: _h * ph,
                                  child: GestureDetector(
                                    onPanUpdate: _rendering
                                        ? null
                                        : (d) => setState(() {
                                              _left = (_left + d.delta.dx / pw)
                                                  .clamp(0.0, 1 - _w);
                                              _top = (_top + d.delta.dy / ph)
                                                  .clamp(0.0, 1 - _h);
                                            }),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.amber, width: 2),
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.open_with,
                                            color: Colors.white70),
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
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _sizeSlider('Width', _w, (v) => setState(() {
                            _w = v;
                            if (_left + _w > 1) _left = 1 - _w;
                          })),
                      _sizeSlider('Height', _h, (v) => setState(() {
                            _h = v;
                            if (_top + _h > 1) _top = 1 - _h;
                          })),
                      const SizedBox(height: 6),
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
                              : const Icon(Icons.crop_rounded),
                          label: Text(_rendering ? 'Cropping…' : 'Crop'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _sizeSlider(String label, double value, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 60, child: Text(label)),
        Expanded(
          child: Slider(
            value: value.clamp(0.1, 1.0),
            min: 0.1,
            max: 1.0,
            onChanged: _rendering ? null : onChanged,
          ),
        ),
      ],
    );
  }
}
