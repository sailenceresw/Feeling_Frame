import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../services/loop_service.dart';
import 'video_result_popup.dart';

/// Repeat a clip N times, or make a forward-then-reverse ping-pong loop.
class LoopScreen extends StatefulWidget {
  const LoopScreen({super.key, required this.video, required this.aspectRatio});

  final File video;
  final double aspectRatio;

  @override
  State<LoopScreen> createState() => _LoopScreenState();
}

class _LoopScreenState extends State<LoopScreen> {
  bool _pingpong = false;
  double _times = 2;
  bool _rendering = false;

  Future<void> _apply() async {
    setState(() => _rendering = true);
    String? out;
    try {
      out = _pingpong
          ? await LoopService.pingpong(widget.video.path)
          : await LoopService.loop(widget.video.path, _times.round());
    } catch (e) {
      log('Loop error: $e');
    }
    if (!mounted) return;
    setState(() => _rendering = false);
    if (out == null) {
      _snack("Couldn't create the loop");
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
      appBar: AppBar(title: const Text('Loop / Ping-pong')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mode'),
                const SizedBox(height: 6),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Repeat'),
                      selected: !_pingpong,
                      onSelected: _rendering
                          ? null
                          : (_) => setState(() => _pingpong = false),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('Ping-pong'),
                      selected: _pingpong,
                      onSelected: _rendering
                          ? null
                          : (_) => setState(() => _pingpong = true),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _pingpong
                      ? 'Plays forward, then smoothly reversed (video only).'
                      : 'Repeats the whole clip back-to-back.',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (!_pingpong) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const SizedBox(width: 74, child: Text('Repeats')),
                      Expanded(
                        child: Slider(
                          value: _times,
                          min: 2,
                          max: 10,
                          divisions: 8,
                          label: '${_times.round()}×',
                          onChanged: _rendering
                              ? null
                              : (v) => setState(() => _times = v),
                        ),
                      ),
                      SizedBox(
                        width: 36,
                        child: Text('${_times.round()}×',
                            textAlign: TextAlign.right),
                      ),
                    ],
                  ),
                ],
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _rendering ? null : _apply,
                    icon: const Icon(Icons.loop_rounded),
                    label: Text(_rendering ? 'Rendering…' : 'Create Loop'),
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
