import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:video_player/video_player.dart';

import '../../services/merge_service.dart';
import 'video_result_popup.dart';

/// Join several clips into one (the current clip is first).
class MergeScreen extends StatefulWidget {
  const MergeScreen({super.key, required this.video});

  final File video;

  @override
  State<MergeScreen> createState() => _MergeScreenState();
}

class _MergeScreenState extends State<MergeScreen> {
  VideoPlayerController? _controller;
  late final List<String> _clips = [widget.video.path];
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

  Future<void> _addClips() async {
    final res =
        await FilePicker.pickFiles(type: FileType.video, allowMultiple: true);
    if (res == null) return;
    setState(() {
      for (final f in res.files) {
        if (f.path != null) _clips.add(f.path!);
      }
    });
  }

  Future<void> _merge() async {
    if (_clips.length < 2) {
      _snack('Add at least one more clip');
      return;
    }
    final size = _controller!.value.size;
    setState(() => _rendering = true);
    String? out;
    try {
      out = await MergeService.merge(
        _clips,
        w: size.width.round(),
        h: size.height.round(),
      );
    } catch (e) {
      log('Merge error: $e');
    }
    if (!mounted) return;
    setState(() => _rendering = false);
    if (out == null) {
      _snack("Couldn't merge the clips");
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
      appBar: AppBar(title: const Text('Merge Clips')),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _clips.length,
                  itemBuilder: (context, i) => ListTile(
                    leading: CircleAvatar(child: Text('${i + 1}')),
                    title: Text(p.basename(_clips[i]),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: i == 0 ? const Text('Current clip') : null,
                    trailing: i == 0
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: _rendering
                                ? null
                                : () => setState(() => _clips.removeAt(i)),
                          ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _rendering ? null : _addClips,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Clips'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: (_rendering || _clips.length < 2)
                            ? null
                            : _merge,
                        icon: const Icon(Icons.merge_type_rounded),
                        label: Text(_rendering
                            ? 'Merging…'
                            : 'Merge ${_clips.length} Clips'),
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
