import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../services/keyframe_service.dart';
import 'video_result_popup.dart';

/// A CapCut-style keyframe timeline for animated pan & zoom.
///
/// The user scrubs the clip, sets keyframes for zoom + position at chosen
/// times, and the app interpolates between them. The on-screen preview shows
/// the interpolated camera live (via a [Transform]) using the *same* maths
/// ([KeyframeService.sampleAt]) that drives the FFmpeg `zoompan` export, so
/// what you see is what you get.
class KeyframeScreen extends StatefulWidget {
  const KeyframeScreen({super.key, required this.video});

  final File video;

  @override
  State<KeyframeScreen> createState() => _KeyframeScreenState();
}

class _KeyframeScreenState extends State<KeyframeScreen> {
  VideoPlayerController? _controller;
  final List<Keyframe> _keyframes = [];

  double _t = 0.0; // playhead (seconds)
  double _duration = 0.0; // clip length (seconds)

  // Working camera values shown on the sliders / preview at the current time.
  double _zoom = KeyframeService.defaultZoom;
  double _cx = KeyframeService.defaultCenter;
  double _cy = KeyframeService.defaultCenter;

  bool _rendering = false;

  /// Two keyframes closer than this (seconds) are treated as the same one.
  static const double _epsilon = 0.05;

  @override
  void initState() {
    super.initState();
    final c = VideoPlayerController.file(widget.video);
    _controller = c;
    c.initialize().then((_) {
      if (!mounted) return;
      c.setVolume(0);
      c.seekTo(Duration.zero);
      setState(() => _duration = c.value.duration.inMilliseconds / 1000.0);
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  List<Keyframe> _sorted() =>
      [..._keyframes]..sort((a, b) => a.t.compareTo(b.t));

  int _keyframeIndexAt(double t) {
    for (var i = 0; i < _keyframes.length; i++) {
      if ((_keyframes[i].t - t).abs() <= _epsilon) return i;
    }
    return -1;
  }

  /// Moves the playhead, seeks the preview to that frame, and refreshes the
  /// working values to the interpolated camera at that time.
  void _seek(double t) {
    t = t.clamp(0.0, _duration <= 0 ? 0.0 : _duration);
    _controller?.seekTo(Duration(milliseconds: (t * 1000).round()));
    final s = KeyframeService.sampleAt(_sorted(), t);
    setState(() {
      _t = t;
      _zoom = s.zoom;
      _cx = s.cx;
      _cy = s.cy;
    });
  }

  /// Slider handler: updates the working value (and the live preview). If a
  /// keyframe already sits at the playhead it is edited in place; otherwise the
  /// change is provisional until the user presses "Add Keyframe".
  void _onSlider({double? zoom, double? cx, double? cy}) {
    setState(() {
      if (zoom != null) _zoom = zoom;
      if (cx != null) _cx = cx;
      if (cy != null) _cy = cy;
      final idx = _keyframeIndexAt(_t);
      if (idx >= 0) {
        _keyframes[idx] =
            _keyframes[idx].copyWith(zoom: _zoom, cx: _cx, cy: _cy);
      }
    });
  }

  void _addOrUpdateKeyframe() {
    setState(() {
      final idx = _keyframeIndexAt(_t);
      final kf = Keyframe(t: _t, zoom: _zoom, cx: _cx, cy: _cy);
      if (idx >= 0) {
        _keyframes[idx] = kf;
      } else {
        _keyframes.add(kf);
      }
    });
  }

  void _deleteKeyframeAt(double t) {
    final idx = _keyframeIndexAt(t);
    if (idx >= 0) setState(() => _keyframes.removeAt(idx));
  }

  Future<void> _export() async {
    if (_keyframes.length < 2) {
      _snack('Add at least 2 keyframes to animate');
      return;
    }
    final size = _controller!.value.size;
    // Preserve the source aspect ratio; cap the height at 1280 for speed.
    var outW = size.width.round();
    var outH = size.height.round();
    if (outH > 1280) {
      outW = (outW * 1280 / outH).round();
      outH = 1280;
    }
    if (outW.isOdd) outW -= 1;
    if (outH.isOdd) outH -= 1;

    setState(() => _rendering = true);
    String? out;
    try {
      out = await KeyframeService.render(
        widget.video.path,
        _sorted(),
        outW: outW,
        outH: outH,
      );
    } catch (e) {
      log('Keyframe render error: $e');
    }
    if (!mounted) return;
    setState(() => _rendering = false);
    if (out == null) {
      _snack("Couldn't render the animation");
      return;
    }
    showDialog(
      context: context,
      builder: (_) => VideoResultPopup(
        video: File(out!),
        aspectRatio: size.width / size.height,
      ),
    );
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keyframe Animation'),
        content: const Text(
          '1. Drag the timeline to a moment.\n'
          '2. Set Zoom / Horizontal / Vertical.\n'
          '3. Press "Add Keyframe".\n'
          '4. Move to another moment, change the values, add another keyframe.\n\n'
          'The camera glides smoothly between your keyframes. Add 2 or more, '
          'then Export.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final ready = c != null && c.value.isInitialized;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keyframe Animation'),
        actions: [
          IconButton(
            onPressed: _showHelp,
            icon: const Icon(Icons.help_outline),
            tooltip: 'How it works',
          ),
        ],
      ),
      body: !ready
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(child: _preview(c)),
                _timeline(),
                const Divider(height: 1),
                _sliders(),
                _actions(),
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
          child: ClipRect(
            child: Transform.scale(
              scale: _zoom,
              // Scaling about (cx,cy) reproduces zoompan's centred crop.
              alignment: Alignment(_cx * 2 - 1, _cy * 2 - 1),
              child: VideoPlayer(c),
            ),
          ),
        ),
      ),
    );
  }

  Widget _timeline() {
    final dur = _duration <= 0 ? 1.0 : _duration;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          SizedBox(
            height: 26,
            child: LayoutBuilder(
              builder: (context, cons) {
                final w = cons.maxWidth;
                double px(double t) => ((t / dur) * w).clamp(0.0, w);
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: 12,
                      child: Container(height: 2, color: Colors.white24),
                    ),
                    for (final k in _keyframes)
                      Positioned(
                        left: px(k.t) - 7,
                        top: 5,
                        child: GestureDetector(
                          onTap: () => _seek(k.t),
                          child: Transform.rotate(
                            angle: math.pi / 4,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: (k.t - _t).abs() <= _epsilon
                                    ? Colors.amber
                                    : Colors.lightBlueAccent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      left: px(_t) - 1,
                      top: 2,
                      child: Container(
                        width: 2,
                        height: 22,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Slider(
            value: _t.clamp(0.0, dur),
            min: 0,
            max: dur,
            onChanged: _duration <= 0 ? null : _seek,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_t.toStringAsFixed(2)}s',
                  style: const TextStyle(fontSize: 12)),
              Text('${_keyframes.length} keyframe(s)',
                  style: const TextStyle(fontSize: 12)),
              Text('${_duration.toStringAsFixed(2)}s',
                  style: const TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sliders() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          _labeledSlider(
            'Zoom',
            _zoom,
            1.0,
            3.0,
            (v) => _onSlider(zoom: v),
            trailing: '${_zoom.toStringAsFixed(2)}x',
          ),
          _labeledSlider(
            'Horizontal',
            _cx,
            0.0,
            1.0,
            (v) => _onSlider(cx: v),
            trailing: '${(_cx * 100).round()}%',
          ),
          _labeledSlider(
            'Vertical',
            _cy,
            0.0,
            1.0,
            (v) => _onSlider(cy: v),
            trailing: '${(_cy * 100).round()}%',
          ),
        ],
      ),
    );
  }

  Widget _labeledSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    required String trailing,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 78,
          child: Text(label, style: const TextStyle(fontSize: 13)),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: _rendering ? null : onChanged,
          ),
        ),
        SizedBox(
          width: 44,
          child: Text(
            trailing,
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _actions() {
    final atKf = _keyframeIndexAt(_t) >= 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _rendering ? null : _addOrUpdateKeyframe,
              icon: const Icon(Icons.add_location_alt_outlined),
              label: Text(atKf ? 'Update Keyframe' : 'Add Keyframe'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: (atKf && !_rendering) ? () => _deleteKeyframeAt(_t) : null,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete keyframe',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _rendering ? null : _export,
              icon: _rendering
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.movie_filter_outlined),
              label: Text(_rendering ? 'Rendering…' : 'Export'),
            ),
          ),
        ],
      ),
    );
  }
}
