import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../services/text_service.dart';
import 'video_result_popup.dart';

/// Adds a text overlay / caption burned onto the video, with a live preview
/// that mirrors the exported drawtext (position, size, colour, box, timing).
class TextScreen extends StatefulWidget {
  const TextScreen({super.key, required this.video});

  final File video;

  @override
  State<TextScreen> createState() => _TextScreenState();
}

class _TextScreenState extends State<TextScreen> {
  VideoPlayerController? _controller;
  final TextEditingController _text = TextEditingController();

  String _position = TextService.bottom;
  double _fontFrac = 0.07; // fraction of video height
  String _color = 'white';
  bool _box = true;
  bool _timed = false;
  double _durationSec = 0.0;
  RangeValues _range = const RangeValues(0, 1);
  bool _rendering = false;

  static const _colorMap = {
    'white': Colors.white,
    'black': Colors.black,
    'yellow': Colors.yellow,
    'red': Colors.red,
    'cyan': Colors.cyan,
    'orange': Colors.orange,
  };

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
      final d = c.value.duration.inMilliseconds / 1000.0;
      setState(() {
        _durationSec = d;
        _range = RangeValues(0, d);
      });
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _export() async {
    final txt = _text.text.trim();
    if (txt.isEmpty) {
      _snack('Type some text first');
      return;
    }
    final size = _controller!.value.size;
    final fontsize = (size.height * _fontFrac).round().clamp(8, 4000);
    setState(() => _rendering = true);
    String? out;
    try {
      out = await TextService.addText(
        widget.video.path,
        text: txt,
        position: _position,
        fontsize: fontsize,
        color: _color,
        box: _box,
        start: _timed ? _range.start : null,
        end: _timed ? _range.end : null,
      );
    } catch (e) {
      log('Text render error: $e');
    }
    if (!mounted) return;
    setState(() => _rendering = false);
    if (out == null) {
      _snack("Couldn't add the text");
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

  Alignment get _align {
    switch (_position) {
      case TextService.top:
        return Alignment.topCenter;
      case TextService.center:
        return Alignment.center;
      case TextService.bottom:
      default:
        return Alignment.bottomCenter;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final ready = c != null && c.value.isInitialized;
    return Scaffold(
      appBar: AppBar(title: const Text('Text')),
      body: !ready
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(child: _preview(c)),
                SingleChildScrollView(child: _controls()),
              ],
            ),
    );
  }

  Widget _preview(VideoPlayerController c) {
    return Container(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: c.value.aspectRatio == 0 ? 1 : c.value.aspectRatio,
          child: LayoutBuilder(
            builder: (context, cons) {
              final h = cons.maxHeight;
              final fontSize = h * _fontFrac;
              final padTop = _position == TextService.top ? h * 0.08 : 0.0;
              final padBottom =
                  _position == TextService.bottom ? h * 0.10 : 0.0;
              return Stack(
                children: [
                  Positioned.fill(child: VideoPlayer(c)),
                  Align(
                    alignment: _align,
                    child: Padding(
                      padding: EdgeInsets.only(
                          top: padTop, bottom: padBottom, left: 8, right: 8),
                      child: Container(
                        padding: _box
                            ? const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4)
                            : EdgeInsets.zero,
                        color: _box ? Colors.black54 : null,
                        child: Text(
                          _text.text.isEmpty ? 'Your text' : _text.text,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: fontSize,
                            color: _colorMap[_color],
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
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
          TextField(
            controller: _text,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Text',
              hintText: 'Type your caption…',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(width: 64, child: Text('Position')),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  children: [
                    for (final p in const [
                      TextService.top,
                      TextService.center,
                      TextService.bottom
                    ])
                      ChoiceChip(
                        label: Text(p[0].toUpperCase() + p.substring(1)),
                        selected: _position == p,
                        onSelected: _rendering
                            ? null
                            : (_) => setState(() => _position = p),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const SizedBox(width: 64, child: Text('Size')),
              Expanded(
                child: Slider(
                  value: _fontFrac,
                  min: 0.03,
                  max: 0.16,
                  onChanged: _rendering
                      ? null
                      : (v) => setState(() => _fontFrac = v),
                ),
              ),
            ],
          ),
          Row(
            children: [
              const SizedBox(width: 64, child: Text('Colour')),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final name in TextService.colors)
                      GestureDetector(
                        onTap: _rendering
                            ? null
                            : () => setState(() => _color = name),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _colorMap[name],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _color == name
                                  ? Colors.blue
                                  : Colors.grey,
                              width: _color == name ? 3 : 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Background box'),
            value: _box,
            onChanged: _rendering ? null : (v) => setState(() => _box = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Show only for a time range'),
            value: _timed,
            onChanged: _rendering ? null : (v) => setState(() => _timed = v),
          ),
          if (_timed && _durationSec > 0)
            RangeSlider(
              values: _range,
              min: 0,
              max: _durationSec,
              divisions: (_durationSec * 2).round().clamp(1, 600),
              labels: RangeLabels('${_range.start.toStringAsFixed(1)}s',
                  '${_range.end.toStringAsFixed(1)}s'),
              onChanged: _rendering ? null : (v) => setState(() => _range = v),
            ),
          const SizedBox(height: 4),
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
                  : const Icon(Icons.text_fields_rounded),
              label: Text(_rendering ? 'Rendering…' : 'Add Text'),
            ),
          ),
        ],
      ),
    );
  }
}
