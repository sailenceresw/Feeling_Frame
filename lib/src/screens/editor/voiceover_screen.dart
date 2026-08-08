import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../services/voiceover_service.dart';
import 'video_result_popup.dart';

/// Type a script → on-device text-to-speech narration mixed onto the clip.
class VoiceoverScreen extends StatefulWidget {
  const VoiceoverScreen({
    super.key,
    required this.video,
    required this.aspectRatio,
  });

  final File video;
  final double aspectRatio;

  @override
  State<VoiceoverScreen> createState() => _VoiceoverScreenState();
}

class _VoiceoverScreenState extends State<VoiceoverScreen> {
  final _text = TextEditingController();
  double _rate = 0.5;
  double _pitch = 1.0;
  bool _keepOriginal = true;
  bool _rendering = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (_text.text.trim().isEmpty) {
      _snack('Type some narration first');
      return;
    }
    setState(() => _rendering = true);
    String? out;
    try {
      out = await VoiceoverService.addVoiceover(
        widget.video.path,
        _text.text,
        keepOriginal: _keepOriginal,
        rate: _rate,
        pitch: _pitch,
      );
    } catch (e) {
      log('Voiceover error: $e');
    }
    if (!mounted) return;
    setState(() => _rendering = false);
    if (out == null) {
      _snack("Couldn't create the voiceover (TTS unavailable?)");
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
      appBar: AppBar(title: const Text('Text-to-Speech Voiceover')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Type narration and it will be spoken on-device and mixed '
                  'onto your clip. Nothing is uploaded.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _text,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Narration',
                    hintText: 'What should the voice say?',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const SizedBox(width: 60, child: Text('Speed')),
                    Expanded(
                      child: Slider(
                        value: _rate,
                        min: 0.2,
                        max: 1.0,
                        onChanged: _rendering
                            ? null
                            : (v) => setState(() => _rate = v),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const SizedBox(width: 60, child: Text('Pitch')),
                    Expanded(
                      child: Slider(
                        value: _pitch,
                        min: 0.5,
                        max: 2.0,
                        onChanged: _rendering
                            ? null
                            : (v) => setState(() => _pitch = v),
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: const Text('Keep original audio (ducked)'),
                  value: _keepOriginal,
                  onChanged: _rendering
                      ? null
                      : (v) => setState(() => _keepOriginal = v),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _rendering ? null : _generate,
                    icon: _rendering
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.record_voice_over_rounded),
                    label: Text(_rendering ? 'Generating…' : 'Add Voiceover'),
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
