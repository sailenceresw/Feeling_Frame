import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../services/speed_service.dart';
import 'video_result_popup.dart';

/// Slow-motion / fast-forward speed control with a live preview.
///
/// The on-screen player is retimed live via [VideoPlayerController.setPlaybackSpeed]
/// so the chosen speed can be felt before exporting; the export re-times the
/// file with FFmpeg (`setpts` + pitch-corrected `atempo`) via [SpeedService].
class SpeedScreen extends StatefulWidget {
  const SpeedScreen({super.key, required this.video});

  final File video;

  @override
  State<SpeedScreen> createState() => _SpeedScreenState();
}

class _SpeedScreenState extends State<SpeedScreen> {
  VideoPlayerController? _controller;
  double _speed = 1.0;
  bool _keepAudio = true;
  bool _rendering = false;
  double _durationSec = 0.0;

  static const List<double> _presets = [0.25, 0.5, 1.0, 1.5, 2.0, 3.0, 4.0];

  @override
  void initState() {
    super.initState();
    final c = VideoPlayerController.file(widget.video);
    _controller = c;
    c.initialize().then((_) {
      if (!mounted) return;
      c.setLooping(true);
      c.setPlaybackSpeed(_speed);
      c.play();
      setState(() => _durationSec = c.value.duration.inMilliseconds / 1000.0);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _setSpeed(double s) {
    s = double.parse(s.clamp(SpeedService.minSpeed, SpeedService.maxSpeed)
        .toStringAsFixed(2));
    setState(() => _speed = s);
    _controller?.setPlaybackSpeed(s);
  }

  Future<void> _export() async {
    setState(() => _rendering = true);
    String? out;
    try {
      out = await SpeedService.changeSpeed(
        widget.video.path,
        _speed,
        keepAudio: _keepAudio,
      );
    } catch (e) {
      log('Speed render error: $e');
    }
    if (!mounted) return;
    setState(() => _rendering = false);
    if (out == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't change the speed")),
      );
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

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final ready = c != null && c.value.isInitialized;
    final newDuration = _speed > 0 ? _durationSec / _speed : _durationSec;
    return Scaffold(
      appBar: AppBar(title: const Text('Speed')),
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${_speed.toStringAsFixed(2)}x',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                          Text(
                            _speed == 1.0
                                ? 'Normal speed'
                                : (_speed < 1.0 ? 'Slow motion' : 'Fast forward'),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                      Slider(
                        value: _speed.clamp(
                            SpeedService.minSpeed, SpeedService.maxSpeed),
                        min: SpeedService.minSpeed,
                        max: SpeedService.maxSpeed,
                        onChanged: _rendering ? null : _setSpeed,
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final p in _presets)
                            ChoiceChip(
                              label: Text('${_fmtPreset(p)}x'),
                              selected: (_speed - p).abs() < 0.001,
                              onSelected:
                                  _rendering ? null : (_) => _setSpeed(p),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: const Text('Keep audio (pitch-corrected)'),
                        value: _keepAudio,
                        onChanged: _rendering
                            ? null
                            : (v) => setState(() => _keepAudio = v),
                      ),
                      Text(
                        'New length: ~${newDuration.toStringAsFixed(1)}s '
                        '(was ${_durationSec.toStringAsFixed(1)}s)',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 8),
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
                              : const Icon(Icons.speed_rounded),
                          label: Text(_rendering ? 'Rendering…' : 'Apply Speed'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  String _fmtPreset(double p) {
    final s = p.toStringAsFixed(2);
    return s.endsWith('0') && s.contains('.')
        ? s.replaceFirst(RegExp(r'\.?0+$'), '')
        : s;
  }
}
