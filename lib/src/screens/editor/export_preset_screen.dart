import 'dart:developer';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../services/export_preset_service.dart';
import 'video_result_popup.dart';

/// Export a clip at the exact size a social platform expects, with a chosen
/// fit mode and a live preview of the result frame.
class ExportPresetScreen extends StatefulWidget {
  const ExportPresetScreen({super.key, required this.video});

  final File video;

  @override
  State<ExportPresetScreen> createState() => _ExportPresetScreenState();
}

class _ExportPresetScreenState extends State<ExportPresetScreen> {
  VideoPlayerController? _controller;
  int _presetIndex = 0;
  ExportFit _fit = ExportFit.fill;
  bool _rendering = false;

  ExportPreset get _preset => ExportPresetService.presets[_presetIndex];

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
    super.dispose();
  }

  Future<void> _export() async {
    setState(() => _rendering = true);
    String? out;
    try {
      out = await ExportPresetService.export(
        widget.video.path,
        _preset,
        fit: _fit,
      );
    } catch (e) {
      log('Export preset error: $e');
    }
    if (!mounted) return;
    setState(() => _rendering = false);
    if (out == null) {
      _snack("Couldn't export this clip");
      return;
    }
    showDialog(
      context: context,
      builder: (_) => VideoResultPopup(
        video: File(out!),
        aspectRatio: _preset.width / _preset.height,
      ),
    );
  }

  void _snack(String m) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final ready = c != null && c.value.isInitialized;
    return Scaffold(
      appBar: AppBar(title: const Text('Social Export')),
      body: !ready
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(child: _preview(c)),
                _controls(),
              ],
            ),
    );
  }

  Widget _preview(VideoPlayerController c) {
    final videoBox = SizedBox(
      width: c.value.size.width,
      height: c.value.size.height,
      child: VideoPlayer(c),
    );
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(12),
      child: Center(
        child: AspectRatio(
          aspectRatio: _preset.width / _preset.height,
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_fit == ExportFit.blur)
                  ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: FittedBox(fit: BoxFit.cover, child: videoBox),
                  ),
                FittedBox(
                  fit: _fit == ExportFit.fill ? BoxFit.cover : BoxFit.contain,
                  child: videoBox,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _controls() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Platform'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var i = 0; i < ExportPresetService.presets.length; i++)
                  ChoiceChip(
                    label: Text(
                        '${ExportPresetService.presets[i].name} · ${ExportPresetService.presets[i].ratio}'),
                    selected: _presetIndex == i,
                    onSelected: _rendering
                        ? null
                        : (_) => setState(() => _presetIndex = i),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            const Text('Fit'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                for (final fit in ExportFit.values)
                  ChoiceChip(
                    label: Text(ExportPresetService.fitLabel(fit)),
                    selected: _fit == fit,
                    onSelected:
                        _rendering ? null : (_) => setState(() => _fit = fit),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Output: ${_preset.width} × ${_preset.height}',
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
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.ios_share_rounded),
                label: Text(_rendering ? 'Exporting…' : 'Export'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
