import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../services/volume_service.dart';
import 'video_result_popup.dart';

/// Set the clip's audio volume and optional audio fade in/out.
class VolumeScreen extends StatefulWidget {
  const VolumeScreen({super.key, required this.video, required this.aspectRatio});

  final File video;
  final double aspectRatio;

  @override
  State<VolumeScreen> createState() => _VolumeScreenState();
}

class _VolumeScreenState extends State<VolumeScreen> {
  VideoPlayerController? _controller;
  double _volume = 1.0;
  bool _fadeIn = false;
  bool _fadeOut = false;
  double _duration = 0;
  bool _rendering = false;

  @override
  void initState() {
    super.initState();
    final c = VideoPlayerController.file(widget.video);
    _controller = c;
    c.initialize().then((_) {
      if (!mounted) return;
      c.setVolume(1);
      c.setLooping(true);
      c.play();
      setState(() => _duration = c.value.duration.inMilliseconds / 1000.0);
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
      out = await VolumeService.apply(
        widget.video.path,
        volume: _volume,
        fadeIn: _fadeIn,
        fadeOut: _fadeOut,
        totalSeconds: _duration,
      );
    } catch (e) {
      log('Volume error: $e');
    }
    if (!mounted) return;
    setState(() => _rendering = false);
    if (out == null) {
      _snack("Couldn't apply the volume change");
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
    final c = _controller;
    final ready = c != null && c.value.isInitialized;
    return Scaffold(
      appBar: AppBar(title: const Text('Volume')),
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
                          const SizedBox(width: 70, child: Text('Volume')),
                          Expanded(
                            child: Slider(
                              value: _volume,
                              max: 3.0,
                              divisions: 30,
                              label: '${(_volume * 100).round()}%',
                              onChanged: _rendering
                                  ? null
                                  : (v) {
                                      setState(() => _volume = v);
                                      c.setVolume(v.clamp(0.0, 1.0));
                                    },
                            ),
                          ),
                          SizedBox(
                            width: 48,
                            child: Text('${(_volume * 100).round()}%',
                                textAlign: TextAlign.right),
                          ),
                        ],
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: const Text('Audio fade in'),
                        value: _fadeIn,
                        onChanged: _rendering
                            ? null
                            : (v) => setState(() => _fadeIn = v),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: const Text('Audio fade out'),
                        value: _fadeOut,
                        onChanged: _rendering
                            ? null
                            : (v) => setState(() => _fadeOut = v),
                      ),
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
                              : const Icon(Icons.volume_up_rounded),
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
