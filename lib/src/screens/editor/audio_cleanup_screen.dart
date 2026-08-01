import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../services/audio_cleanup_service.dart';
import 'video_result_popup.dart';

/// One-tap audio clean-up: pick which fixes to apply, then render.
class AudioCleanupScreen extends StatefulWidget {
  const AudioCleanupScreen({
    super.key,
    required this.video,
    required this.aspectRatio,
  });

  final File video;
  final double aspectRatio;

  @override
  State<AudioCleanupScreen> createState() => _AudioCleanupScreenState();
}

class _AudioCleanupScreenState extends State<AudioCleanupScreen> {
  bool _deRumble = true;
  bool _denoise = true;
  bool _normalize = true;
  bool _voiceBoost = false;
  bool _rendering = false;

  bool get _anySelected =>
      _deRumble || _denoise || _normalize || _voiceBoost;

  Future<void> _apply() async {
    if (!_anySelected) {
      _snack('Turn on at least one clean-up option');
      return;
    }
    setState(() => _rendering = true);
    String? out;
    try {
      out = await AudioCleanupService.cleanup(
        widget.video.path,
        deRumble: _deRumble,
        denoise: _denoise,
        normalize: _normalize,
        voiceBoost: _voiceBoost,
      );
    } catch (e) {
      log('Audio cleanup error: $e');
    }
    if (!mounted) return;
    setState(() => _rendering = false);
    if (out == null) {
      _snack("Couldn't clean up the audio");
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
      appBar: AppBar(title: const Text('Audio Cleanup')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Improve the sound of your clip. The video is untouched — only '
              'the audio is processed.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            _tile(
              'Reduce background noise',
              'Removes hiss and steady background noise.',
              _denoise,
              (v) => setState(() => _denoise = v),
            ),
            _tile(
              'Normalize loudness',
              'Evens out and lifts quiet audio to a standard level.',
              _normalize,
              (v) => setState(() => _normalize = v),
            ),
            _tile(
              'Remove low rumble',
              'Cuts wind and low-frequency hum.',
              _deRumble,
              (v) => setState(() => _deRumble = v),
            ),
            _tile(
              'Voice boost',
              'Adds presence so speech sits clearer.',
              _voiceBoost,
              (v) => setState(() => _voiceBoost = v),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_rendering || !_anySelected) ? null : _apply,
                icon: _rendering
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.graphic_eq_rounded),
                label: Text(_rendering ? 'Processing…' : 'Clean Up Audio'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: _rendering ? null : onChanged,
    );
  }
}
