import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../services/transition_service.dart';
import 'video_result_popup.dart';

/// Joins the current clip with a second clip using a chosen transition.
class TransitionScreen extends StatefulWidget {
  const TransitionScreen({super.key, required this.video});

  final File video;

  @override
  State<TransitionScreen> createState() => _TransitionScreenState();
}

class _TransitionScreenState extends State<TransitionScreen> {
  VideoPlayerController? _main;
  VideoPlayerController? _second;
  File? _secondFile;

  String _transitionName = 'Crossfade';
  double _duration = 1.0;
  bool _keepAudio = true;
  bool _rendering = false;

  @override
  void initState() {
    super.initState();
    final c = VideoPlayerController.file(widget.video);
    _main = c;
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
    _main?.dispose();
    _second?.dispose();
    super.dispose();
  }

  Future<void> _pickSecond() async {
    final res = await FilePicker.pickFiles(type: FileType.video);
    final path = res?.files.single.path;
    if (path == null) return;
    await _second?.dispose();
    final c = VideoPlayerController.file(File(path));
    _second = c;
    _secondFile = File(path);
    await c.initialize();
    if (!mounted) return;
    c.setVolume(0);
    c.setLooping(true);
    c.play();
    setState(() {});
  }

  Future<void> _export() async {
    final second = _secondFile;
    if (second == null) {
      _snack('Pick a second clip first');
      return;
    }
    final size = _main!.value.size;
    final dur1 = _main!.value.duration.inMilliseconds / 1000.0;
    // Keep the transition shorter than clip 1 so there is footage to blend.
    final d = _duration.clamp(0.1, (dur1 - 0.05).clamp(0.1, 5.0));
    setState(() => _rendering = true);
    String? out;
    try {
      out = await TransitionService.joinWithTransition(
        widget.video.path,
        second.path,
        w: size.width.round(),
        h: size.height.round(),
        clip1Duration: dur1,
        transition: TransitionService.transitions[_transitionName] ?? 'fade',
        duration: d,
        keepAudio: _keepAudio,
      );
    } catch (e) {
      log('Transition render error: $e');
    }
    if (!mounted) return;
    setState(() => _rendering = false);
    if (out == null) {
      _snack("Couldn't join the clips");
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
    final main = _main;
    final ready = main != null && main.value.isInitialized;
    return Scaffold(
      appBar: AppBar(title: const Text('Transition')),
      body: !ready
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(child: _clipsPreview(main)),
                SingleChildScrollView(child: _controls()),
              ],
            ),
    );
  }

  Widget _clipsPreview(VideoPlayerController main) {
    final second = _second;
    final secondReady = second != null && second.value.isInitialized;
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(child: _clipTile('Clip 1', main)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.arrow_forward_rounded, color: Colors.white70),
          ),
          Expanded(
            child: secondReady
                ? _clipTile('Clip 2', second)
                : _emptyClipTile(),
          ),
        ],
      ),
    );
  }

  Widget _clipTile(String label, VideoPlayerController c) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: AspectRatio(
            aspectRatio: c.value.aspectRatio == 0 ? 1 : c.value.aspectRatio,
            child: VideoPlayer(c),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _emptyClipTile() {
    return GestureDetector(
      onTap: _rendering ? null : _pickSecond,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_circle_outline, color: Colors.white70),
              SizedBox(height: 6),
              Text('Add clip 2',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
            onPressed: _rendering ? null : _pickSecond,
            icon: const Icon(Icons.video_library_outlined),
            label: Text(_secondFile == null ? 'Pick Second Clip' : 'Change Clip'),
          ),
          const SizedBox(height: 12),
          const Text('Transition'),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final name in TransitionService.transitions.keys)
                ChoiceChip(
                  label: Text(name),
                  selected: _transitionName == name,
                  onSelected: _rendering
                      ? null
                      : (_) => setState(() => _transitionName = name),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 74, child: Text('Duration')),
              Expanded(
                child: Slider(
                  value: _duration,
                  min: 0.3,
                  max: 2.0,
                  divisions: 17,
                  onChanged:
                      _rendering ? null : (v) => setState(() => _duration = v),
                ),
              ),
              SizedBox(
                width: 44,
                child: Text('${_duration.toStringAsFixed(1)}s',
                    textAlign: TextAlign.right),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Crossfade audio'),
            value: _keepAudio,
            onChanged:
                _rendering ? null : (v) => setState(() => _keepAudio = v),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_secondFile == null || _rendering) ? null : _export,
              icon: _rendering
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.movie_filter_rounded),
              label: Text(_rendering ? 'Rendering…' : 'Join Clips'),
            ),
          ),
        ],
      ),
    );
  }
}
