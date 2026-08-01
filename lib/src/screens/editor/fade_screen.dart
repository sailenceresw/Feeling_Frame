import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../services/fade_service.dart';
import 'video_result_popup.dart';

/// Intro/outro fade from and to black.
class FadeScreen extends StatefulWidget {
  const FadeScreen({super.key, required this.video, required this.aspectRatio});

  final File video;
  final double aspectRatio;

  @override
  State<FadeScreen> createState() => _FadeScreenState();
}

class _FadeScreenState extends State<FadeScreen> {
  VideoPlayerController? _controller;
  bool _fadeIn = true;
  bool _fadeOut = true;
  double _fadeSeconds = 1.0;
  double _duration = 0;
  bool _rendering = false;

  @override
  void initState() {
    super.initState();
    final c = VideoPlayerController.file(widget.video);
    _controller = c;
    c.initialize().then((_) {
      if (!mounted) return;
      setState(() => _duration = c.value.duration.inMilliseconds / 1000.0);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    if (!_fadeIn && !_fadeOut) {
      _snack('Turn on fade in or fade out');
      return;
    }
    setState(() => _rendering = true);
    String? out;
    try {
      out = await FadeService.apply(
        widget.video.path,
        totalSeconds: _duration,
        fadeSeconds: _fadeSeconds,
        fadeIn: _fadeIn,
        fadeOut: _fadeOut,
      );
    } catch (e) {
      log('Fade error: $e');
    }
    if (!mounted) return;
    setState(() => _rendering = false);
    if (out == null) {
      _snack("Couldn't apply the fade");
      return;
    }
    showDialog(
      context: context,
      builder: (_) => VideoResultPopup(
        video: File(out!),
        aspectRatio: widget.aspectRatio,
      ),
    );
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Intro / Outro Fade')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Fade the clip from and to black.',
                    style: TextStyle(fontSize: 13)),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fade in (from black)'),
                  value: _fadeIn,
                  onChanged:
                      _rendering ? null : (v) => setState(() => _fadeIn = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Fade out (to black)'),
                  value: _fadeOut,
                  onChanged:
                      _rendering ? null : (v) => setState(() => _fadeOut = v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 90, child: Text('Duration')),
                    Expanded(
                      child: Slider(
                        value: _fadeSeconds,
                        min: 0.3,
                        max: 3.0,
                        divisions: 27,
                        label: '${_fadeSeconds.toStringAsFixed(1)}s',
                        onChanged: _rendering
                            ? null
                            : (v) => setState(() => _fadeSeconds = v),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text('${_fadeSeconds.toStringAsFixed(1)}s',
                          textAlign: TextAlign.right),
                    ),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _rendering ? null : _apply,
                    icon: const Icon(Icons.gradient_rounded),
                    label: Text(_rendering ? 'Applying…' : 'Apply Fade'),
                  ),
                ),
              ],
            ),
          ),
          if (_rendering)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black54,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
