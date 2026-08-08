import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../services/color_adjust_service.dart';
import 'video_result_popup.dart';

/// Manual colour grading with brightness / contrast / saturation / warmth.
class ColorAdjustScreen extends StatefulWidget {
  const ColorAdjustScreen({super.key, required this.video});

  final File video;

  @override
  State<ColorAdjustScreen> createState() => _ColorAdjustScreenState();
}

class _ColorAdjustScreenState extends State<ColorAdjustScreen> {
  VideoPlayerController? _controller;
  double _brightness = 0.0;
  double _contrast = 1.0;
  double _saturation = 1.0;
  double _warmth = 0.0;
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
      out = await ColorAdjustService.apply(
        widget.video.path,
        brightness: _brightness,
        contrast: _contrast,
        saturation: _saturation,
        warmth: _warmth,
      );
    } catch (e) {
      log('Color adjust error: $e');
    }
    if (!mounted) return;
    setState(() => _rendering = false);
    if (out == null) {
      _snack("Couldn't apply the colour changes");
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

  void _reset() => setState(() {
        _brightness = 0.0;
        _contrast = 1.0;
        _saturation = 1.0;
        _warmth = 0.0;
      });

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final ready = c != null && c.value.isInitialized;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Adjust'),
        actions: [
          TextButton(
            onPressed: _rendering ? null : _reset,
            child: const Text('Reset'),
          ),
        ],
      ),
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
                        child: _livePreview(VideoPlayer(c)),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _slider('Brightness', _brightness, -0.5, 0.5,
                          (v) => setState(() => _brightness = v)),
                      _slider('Contrast', _contrast, 0.5, 1.8,
                          (v) => setState(() => _contrast = v)),
                      _slider('Saturation', _saturation, 0.0, 2.5,
                          (v) => setState(() => _saturation = v)),
                      _slider('Warmth', _warmth, -1.0, 1.0,
                          (v) => setState(() => _warmth = v)),
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
                              : const Icon(Icons.tune_rounded),
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

  /// Applies the current brightness/contrast/saturation/warmth to [child] live
  /// via chained colour matrices — an approximate real-time preview of what the
  /// FFmpeg export will produce.
  Widget _livePreview(Widget child) {
    const lumR = 0.2126, lumG = 0.7152, lumB = 0.0722;
    final b = _brightness, c = _contrast, s = _saturation, w = _warmth;
    final inv = 1 - s;
    final co = 128 * (1 - c);
    Widget out = child;
    // brightness (additive)
    out = ColorFiltered(
      colorFilter: ColorFilter.matrix(<double>[
        1, 0, 0, 0, b * 255,
        0, 1, 0, 0, b * 255,
        0, 0, 1, 0, b * 255,
        0, 0, 0, 1, 0,
      ]),
      child: out,
    );
    // contrast (scale around mid-grey)
    out = ColorFiltered(
      colorFilter: ColorFilter.matrix(<double>[
        c, 0, 0, 0, co,
        0, c, 0, 0, co,
        0, 0, c, 0, co,
        0, 0, 0, 1, 0,
      ]),
      child: out,
    );
    // saturation (luma-preserving)
    out = ColorFiltered(
      colorFilter: ColorFilter.matrix(<double>[
        inv * lumR + s, inv * lumG, inv * lumB, 0, 0,
        inv * lumR, inv * lumG + s, inv * lumB, 0, 0,
        inv * lumR, inv * lumG, inv * lumB + s, 0, 0,
        0, 0, 0, 1, 0,
      ]),
      child: out,
    );
    // warmth (+red / -blue, or the reverse)
    out = ColorFiltered(
      colorFilter: ColorFilter.matrix(<double>[
        1, 0, 0, 0, w * 30,
        0, 1, 0, 0, 0,
        0, 0, 1, 0, -w * 30,
        0, 0, 0, 1, 0,
      ]),
      child: out,
    );
    return out;
  }

  Widget _slider(String label, double value, double min, double max,
      ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(width: 84, child: Text(label, style: const TextStyle(fontSize: 13))),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: _rendering ? null : onChanged,
          ),
        ),
      ],
    );
  }
}
