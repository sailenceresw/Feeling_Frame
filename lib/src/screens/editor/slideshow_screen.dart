import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../services/slideshow_service.dart';
import 'video_result_popup.dart';

/// Build a photo slideshow video (with optional music).
class SlideshowScreen extends StatefulWidget {
  const SlideshowScreen({super.key});

  @override
  State<SlideshowScreen> createState() => _SlideshowScreenState();
}

class _SlideshowScreenState extends State<SlideshowScreen> {
  final List<String> _images = [];
  String? _music;
  double _secondsPer = 2.5;
  bool _portrait = true; // 9:16 vs 16:9
  bool _rendering = false;

  Future<void> _pickImages() async {
    final res =
        await FilePicker.pickFiles(type: FileType.image, allowMultiple: true);
    if (res == null) return;
    setState(() {
      for (final f in res.files) {
        if (f.path != null) _images.add(f.path!);
      }
    });
  }

  Future<void> _pickMusic() async {
    final res = await FilePicker.pickFiles(type: FileType.audio);
    final path = res?.files.single.path;
    if (path != null) setState(() => _music = path);
  }

  Future<void> _build() async {
    if (_images.isEmpty) {
      _snack('Add some photos first');
      return;
    }
    final w = _portrait ? 1080 : 1920;
    final h = _portrait ? 1920 : 1080;
    setState(() => _rendering = true);
    String? out;
    try {
      out = await SlideshowService.build(
        _images,
        w: w,
        h: h,
        secondsPer: _secondsPer,
        music: _music,
      );
    } catch (e) {
      log('Slideshow error: $e');
    }
    if (!mounted) return;
    setState(() => _rendering = false);
    if (out == null) {
      _snack("Couldn't build the slideshow");
      return;
    }
    showDialog(
      context: context,
      builder: (_) => VideoResultPopup(
        video: File(out!),
        aspectRatio: w / h,
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
      appBar: AppBar(title: const Text('Photo Slideshow')),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _images.isEmpty
                    ? const Center(
                        child: Text('Add photos to build a slideshow'))
                    : GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                        itemCount: _images.length,
                        itemBuilder: (context, i) => Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.file(File(_images[i]),
                                  fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: _rendering
                                    ? null
                                    : () => setState(() => _images.removeAt(i)),
                                child: const CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.black54,
                                  child: Icon(Icons.close,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _rendering ? null : _pickImages,
                            icon: const Icon(Icons.add_photo_alternate_outlined),
                            label: const Text('Add Photos'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _rendering ? null : _pickMusic,
                            icon: const Icon(Icons.library_music_outlined),
                            label: Text(_music == null ? 'Music' : 'Music ✓'),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('Per photo'),
                        Expanded(
                          child: Slider(
                            value: _secondsPer,
                            min: 1,
                            max: 5,
                            divisions: 8,
                            label: '${_secondsPer.toStringAsFixed(1)}s',
                            onChanged: _rendering
                                ? null
                                : (v) => setState(() => _secondsPer = v),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text('Shape'),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Portrait 9:16'),
                          selected: _portrait,
                          onSelected: _rendering
                              ? null
                              : (_) => setState(() => _portrait = true),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text('Landscape 16:9'),
                          selected: !_portrait,
                          onSelected: _rendering
                              ? null
                              : (_) => setState(() => _portrait = false),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            (_images.isEmpty || _rendering) ? null : _build,
                        icon: const Icon(Icons.slideshow_rounded),
                        label: Text(_rendering ? 'Building…' : 'Build Slideshow'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
