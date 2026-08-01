import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../services/split_screen_service.dart';
import 'video_result_popup.dart';

/// Combine the current clip with a second one into a split screen.
class SplitScreenScreen extends StatefulWidget {
  const SplitScreenScreen({super.key, required this.video});

  final File video;

  @override
  State<SplitScreenScreen> createState() => _SplitScreenScreenState();
}

class _SplitScreenScreenState extends State<SplitScreenScreen> {
  VideoPlayerController? _controller;
  String? _second;
  bool _horizontal = true;
  bool _rendering = false;

  @override
  void initState() {
    super.initState();
    final c = VideoPlayerController.file(widget.video);
    _controller = c;
    c.initialize().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _pickSecond() async {
    final res = await FilePicker.pickFiles(type: FileType.video);
    final path = res?.files.single.path;
    if (path != null) setState(() => _second = path);
  }

  Future<void> _combine() async {
    final second = _second;
    if (second == null) {
      _snack('Pick a second clip first');
      return;
    }
    final size = _controller!.value.size;
    setState(() => _rendering = true);
    String? out;
    try {
      out = await SplitScreenService.combine(
        widget.video.path,
        second,
        w: size.width.round(),
        h: size.height.round(),
        horizontal: _horizontal,
      );
    } catch (e) {
      log('Split screen error: $e');
    }
    if (!mounted) return;
    setState(() => _rendering = false);
    if (out == null) {
      _snack("Couldn't create the split screen");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Split Screen')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Combine this clip with a second one, side-by-side or stacked. '
              'Both are scaled to fill their half.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _rendering ? null : _pickSecond,
              icon: const Icon(Icons.video_library_outlined),
              label: Text(_second == null ? 'Pick Second Clip' : 'Change Clip'),
            ),
            const SizedBox(height: 16),
            const Text('Layout'),
            const SizedBox(height: 6),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Side by side'),
                  selected: _horizontal,
                  onSelected: _rendering
                      ? null
                      : (_) => setState(() => _horizontal = true),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Stacked'),
                  selected: !_horizontal,
                  onSelected: _rendering
                      ? null
                      : (_) => setState(() => _horizontal = false),
                ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_second == null || _rendering) ? null : _combine,
                icon: _rendering
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.splitscreen_rounded),
                label: Text(_rendering ? 'Rendering…' : 'Create Split Screen'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
