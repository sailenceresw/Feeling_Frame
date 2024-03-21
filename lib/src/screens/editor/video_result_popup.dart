import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:fraction/fraction.dart';
import 'package:gallery_saver_updated/gallery_saver.dart';
import 'package:path/path.dart' as path;
import 'package:share_extend/share_extend.dart';
import 'package:video_editor_mobile_app/src/constant/dimension.dart';
import 'package:video_editor_mobile_app/src/widgets/custom_toast.dart';
import 'package:video_player/video_player.dart';

Future<void> _getImageDimension(File file,
    {required Function(Size) onResult}) async {
  var decodedImage = await decodeImageFromList(file.readAsBytesSync());
  onResult(Size(decodedImage.width.toDouble(), decodedImage.height.toDouble()));
}

String _fileMBSize(File file) =>
    ' ${(file.lengthSync() / (1024 * 1024)).toStringAsFixed(1)} MB';

class VideoResultPopup extends StatefulWidget {
  const VideoResultPopup(
      {super.key,
      required this.aspectRatio,
      this.isExport = false,
      required this.video});
  final double aspectRatio;
  final File video;
  final bool isExport;

  @override
  State<VideoResultPopup> createState() => _VideoResultPopupState();
}

class _VideoResultPopupState extends State<VideoResultPopup> {
  VideoPlayerController? _controller;
  FileImage? _fileImage;
  Size _fileDimension = Size.zero;
  late final bool _isGif =
      path.extension(widget.video.path).toLowerCase() == ".gif";
  late String _fileMbSize;

  @override
  void initState() {
    super.initState();
    if (_isGif) {
      _getImageDimension(
        widget.video,
        onResult: (d) => setState(() => _fileDimension = d),
      );
    } else {
      _controller = VideoPlayerController.file(widget.video);
      _controller?.initialize().then((_) {
        _fileDimension = _controller?.value.size ?? Size.zero;
        setState(() {});
        _controller?.play();
        _controller?.setLooping(true);
      });
    }
    _fileMbSize = _fileMBSize(widget.video);
  }

  void saveVideo() async {
    String path = widget.video.path;
    bool? data = await GallerySaver.saveVideo(path);
    if (data == true) {
      successToast(msg: "Saved successfully");
    } else {
      errorToast(msg: "Couldn't save");
    }
  }

  @override
  void dispose() {
    if (_isGif) {
      _fileImage?.evict();
    } else {
      _controller?.pause();
      _controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: _controller != null && _controller!.value.isInitialized
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.bottomLeft,
                    children: [
                      AspectRatio(
                        aspectRatio: _fileDimension.aspectRatio == 0
                            ? 1
                            : _fileDimension.aspectRatio,
                        child: _isGif
                            ? Image.file(widget.video)
                            : VideoPlayer(_controller!),
                      ),
                      Positioned(
                        bottom: 0,
                        child: FileDescription(
                          description: {
                            'Video path': widget.video.path,
                            if (!_isGif)
                              'Video duration':
                                  '${((_controller?.value.duration.inMilliseconds ?? 0) / 1000).toStringAsFixed(2)}s',
                            'Video ratio':
                                Fraction.fromDouble(_fileDimension.aspectRatio)
                                    .reduce()
                                    .toString(),
                            'Video dimension': _fileDimension.toString(),
                            'Video size': _fileMbSize,
                          },
                        ),
                      ),
                    ],
                  ),
                  vSizedBox1,
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            ShareExtend.share(widget.video.path, "video");
                          },
                          icon: const Icon(Icons.share),
                          label: const Text("Share"),
                        ),
                      ),
                      hSizedBox1,
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.download_for_offline_outlined),
                          onPressed: saveVideo,
                          label: const Text("Download"),
                        ),
                      )
                    ],
                  ),
                ],
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}

class CoverResultPopup extends StatefulWidget {
  const CoverResultPopup({super.key, required this.cover});

  final File cover;

  @override
  State<CoverResultPopup> createState() => _CoverResultPopupState();
}

class _CoverResultPopupState extends State<CoverResultPopup> {
  late final Uint8List _imagebytes = widget.cover.readAsBytesSync();
  Size? _fileDimension;
  late String _fileMbSize;

  @override
  void initState() {
    super.initState();
    _getImageDimension(
      widget.cover,
      onResult: (d) => setState(() => _fileDimension = d),
    );
    _fileMbSize = _fileMBSize(widget.cover);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Center(
        child: Stack(
          children: [
            Image.memory(_imagebytes),
            Positioned(
              bottom: 0,
              child: FileDescription(
                description: {
                  'Cover path': widget.cover.path,
                  'Cover ratio':
                      Fraction.fromDouble(_fileDimension?.aspectRatio ?? 0)
                          .reduce()
                          .toString(),
                  'Cover dimension': _fileDimension.toString(),
                  'Cover size': _fileMbSize,
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FileDescription extends StatelessWidget {
  const FileDescription({super.key, required this.description});

  final Map<String, String> description;

  @override
  Widget build(BuildContext context) {
    return DefaultTextStyle(
      style: const TextStyle(fontSize: 11),
      child: Container(
        width: MediaQuery.of(context).size.width - 60,
        padding: const EdgeInsets.all(10),
        color: Colors.black.withOpacity(0.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: description.entries
              .map(
                (entry) => Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${entry.key}: ',
                        style: const TextStyle(fontSize: 11),
                      ),
                      TextSpan(
                        text: entry.value,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
