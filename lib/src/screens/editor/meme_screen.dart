import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../services/meme_service.dart';
import 'video_result_popup.dart';

/// Classic top/bottom meme captions.
class MemeScreen extends StatefulWidget {
  const MemeScreen({super.key, required this.video});

  final File video;

  @override
  State<MemeScreen> createState() => _MemeScreenState();
}

class _MemeScreenState extends State<MemeScreen> {
  VideoPlayerController? _controller;
  final _top = TextEditingController();
  final _bottom = TextEditingController();
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
    _top.dispose();
    _bottom.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    if (_top.text.trim().isEmpty && _bottom.text.trim().isEmpty) {
      _snack('Type a top or bottom caption');
      return;
    }
    final size = _controller!.value.size;
    final fontSize = (size.height * 0.08).round().clamp(12, 4000);
    setState(() => _rendering = true);
    String? out;
    try {
      out = await MemeService.generate(
        widget.video.path,
        top: _top.text,
        bottom: _bottom.text,
        fontSize: fontSize,
      );
    } catch (e) {
      log('Meme error: $e');
    }
    if (!mounted) return;
    setState(() => _rendering = false);
    if (out == null) {
      _snack("Couldn't create the meme");
      return;
    }
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

  TextStyle get _memeStyle => const TextStyle(
        fontSize: 22,
        color: Colors.white,
        fontWeight: FontWeight.w900,
        shadows: [
          Shadow(color: Colors.black, offset: Offset(-1.5, -1.5)),
          Shadow(color: Colors.black, offset: Offset(1.5, -1.5)),
          Shadow(color: Colors.black, offset: Offset(1.5, 1.5)),
          Shadow(color: Colors.black, offset: Offset(-1.5, 1.5)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final ready = c != null && c.value.isInitialized;
    return Scaffold(
      appBar: AppBar(title: const Text('Meme')),
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
                            Align(
                              alignment: Alignment.topCenter,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(_top.text.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: _memeStyle),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(_bottom.text.toUpperCase(),
                                    textAlign: TextAlign.center,
                                    style: _memeStyle),
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
                      TextField(
                        controller: _top,
                        onChanged: (_) => setState(() {}),
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Top text',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _bottom,
                        onChanged: (_) => setState(() {}),
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Bottom text',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
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
                              : const Icon(Icons.sentiment_very_satisfied),
                          label: Text(_rendering ? 'Rendering…' : 'Make Meme'),
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
