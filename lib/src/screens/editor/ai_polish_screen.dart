import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../services/ai_polish_service.dart';
import 'video_result_popup.dart';

/// One-tap AI Polish: pick which automatic fixes to run, then let the app
/// stabilize, colour-grade and clean the audio in a single pass.
class AiPolishScreen extends StatefulWidget {
  const AiPolishScreen({
    super.key,
    required this.video,
    required this.aspectRatio,
  });

  final File video;
  final double aspectRatio;

  @override
  State<AiPolishScreen> createState() => _AiPolishScreenState();
}

class _AiPolishScreenState extends State<AiPolishScreen> {
  bool _stabilize = true;
  bool _enhance = true;
  bool _cleanAudio = true;
  bool _running = false;
  PolishStep? _current;

  bool get _anySelected => _stabilize || _enhance || _cleanAudio;

  Future<void> _run() async {
    if (!_anySelected) {
      _snack('Turn on at least one fix');
      return;
    }
    setState(() {
      _running = true;
      _current = null;
    });
    String? out;
    try {
      out = await AiPolishService.polish(
        widget.video.path,
        stabilize: _stabilize,
        enhance: _enhance,
        cleanAudio: _cleanAudio,
        onStep: (step) {
          if (mounted) setState(() => _current = step);
        },
      );
    } catch (e) {
      log('AI Polish error: $e');
    }
    if (!mounted) return;
    setState(() {
      _running = false;
      _current = null;
    });
    if (out == null) {
      _snack("Couldn't polish this clip");
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
      appBar: AppBar(title: const Text('AI Polish')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'One tap to auto-improve your clip. Each fix runs on-device, '
                  'in order.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                _tile(
                  'Stabilize',
                  'Smooths out shaky, handheld footage.',
                  Icons.vibration_rounded,
                  _stabilize,
                  (v) => setState(() => _stabilize = v),
                ),
                _tile(
                  'Enhance colour',
                  'Adaptive contrast, saturation and sharpening.',
                  Icons.auto_fix_high_rounded,
                  _enhance,
                  (v) => setState(() => _enhance = v),
                ),
                _tile(
                  'Clean audio',
                  'Noise reduction and loudness normalization.',
                  Icons.graphic_eq_rounded,
                  _cleanAudio,
                  (v) => setState(() => _cleanAudio = v),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: (_running || !_anySelected) ? null : _run,
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(_running ? 'Polishing…' : 'Polish Video'),
                  ),
                ),
              ],
            ),
          ),
          if (_running) _overlay(),
        ],
      ),
    );
  }

  Widget _tile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: _running ? null : onChanged,
    );
  }

  Widget _overlay() {
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black54,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 12),
              Text(
                _current == null
                    ? 'Preparing…'
                    : AiPolishService.label(_current!),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
