import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../services/compress_service.dart';
import 'video_result_popup.dart';

/// Reduce a video's file size — pick a quality level and an optional resolution
/// cap, then re-encode.
class CompressScreen extends StatefulWidget {
  const CompressScreen({
    super.key,
    required this.video,
    required this.aspectRatio,
  });

  final File video;
  final double aspectRatio;

  @override
  State<CompressScreen> createState() => _CompressScreenState();
}

class _CompressScreenState extends State<CompressScreen> {
  VideoPlayerController? _controller;
  CompressQuality _quality = CompressQuality.balanced;
  int _maxHeight = 0; // 0 = keep original resolution
  bool _rendering = false;
  int _sourceHeight = 0;
  double _originalMb = 0;

  static const _resolutions = {
    0: 'Original',
    1080: '1080p',
    720: '720p',
    480: '480p',
  };

  @override
  void initState() {
    super.initState();
    try {
      _originalMb = widget.video.lengthSync() / (1024 * 1024);
    } catch (_) {}
    final c = VideoPlayerController.file(widget.video);
    _controller = c;
    c.initialize().then((_) {
      if (!mounted) return;
      setState(() => _sourceHeight = c.value.size.height.round());
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _compress() async {
    setState(() => _rendering = true);
    String? out;
    try {
      out = await CompressService.compress(
        widget.video.path,
        quality: _quality,
        maxHeight: _maxHeight,
        sourceHeight: _sourceHeight,
      );
    } catch (e) {
      log('Compress error: $e');
    }
    if (!mounted) return;
    setState(() => _rendering = false);
    if (out == null) {
      _snack("Couldn't compress this clip");
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
      appBar: AppBar(title: const Text('Compress')),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Original size: ${_originalMb.toStringAsFixed(1)} MB'
                  '${_sourceHeight > 0 ? '  ·  ${_sourceHeight}p' : ''}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text('Quality'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final q in CompressQuality.values)
                      ChoiceChip(
                        label: Text(CompressService.qualityLabel(q)),
                        selected: _quality == q,
                        onSelected: _rendering
                            ? null
                            : (_) => setState(() => _quality = q),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Resolution'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    for (final entry in _resolutions.entries)
                      ChoiceChip(
                        label: Text(entry.value),
                        selected: _maxHeight == entry.key,
                        onSelected: _rendering
                            ? null
                            : (_) => setState(() => _maxHeight = entry.key),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _hint(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _rendering ? null : _compress,
                    icon: const Icon(Icons.compress_rounded),
                    label: Text(_rendering ? 'Compressing…' : 'Compress'),
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

  String _hint() {
    final scaling = _maxHeight > 0 &&
        _sourceHeight > 0 &&
        _sourceHeight > _maxHeight;
    switch (_quality) {
      case CompressQuality.high:
        return scaling
            ? 'Light compression, downscaled to ${_maxHeight}p.'
            : 'Light compression — near-original quality.';
      case CompressQuality.balanced:
        return scaling
            ? 'Balanced size/quality, downscaled to ${_maxHeight}p.'
            : 'A good balance of size and quality.';
      case CompressQuality.small:
        return scaling
            ? 'Smallest file, downscaled to ${_maxHeight}p.'
            : 'Strong compression for the smallest file.';
    }
  }
}
