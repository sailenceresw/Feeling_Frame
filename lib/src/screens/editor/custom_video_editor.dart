import 'dart:developer';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lindi_sticker_widget/lindi_sticker_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_editor/video_editor.dart';
import 'package:video_editor_mobile_app/src/constant/dimension.dart';
import 'package:video_editor_mobile_app/src/controllers/editor_controller.dart';
import 'package:video_editor_mobile_app/src/controllers/settings_controller.dart';
import 'package:video_editor_mobile_app/src/screens/ai/ai_screen.dart';
import 'package:video_editor_mobile_app/src/screens/editor/crop_screen.dart';
import 'package:video_editor_mobile_app/src/widgets/custom_text.dart';

import '../../services/advanced_edit_service.dart';
import '../../services/ai_video_service.dart';
import '../../services/audio_service.dart';
import '../../services/auto_analysis_service.dart';
import '../../services/auto_frame_service.dart';
import '../../services/export_services.dart';
import '../../services/filter_service.dart';
import '../../utils/storage_path.dart';
import 'ai_polish_screen.dart';
import 'audio_cleanup_screen.dart';
import 'blur_region_screen.dart';
import 'border_screen.dart';
import 'caption_studio_screen.dart';
import 'color_adjust_screen.dart';
import 'compress_screen.dart';
import 'crop_region_screen.dart';
import 'export_preset_screen.dart';
import 'fade_screen.dart';
import 'gif_studio_screen.dart';
import 'loop_screen.dart';
import 'meme_screen.dart';
import 'merge_screen.dart';
import 'rotate_screen.dart';
import 'slideshow_screen.dart';
import 'split_screen_screen.dart';
import 'thumbnail_designer_screen.dart';
import 'vfx_screen.dart';
import 'volume_screen.dart';
import 'watermark_screen.dart';
import 'keyframe_screen.dart';
import 'pip_screen.dart';
import 'speed_screen.dart';
import 'text_screen.dart';
import 'transition_screen.dart';
import 'video_result_popup.dart';

class CustomVideoEditor extends StatefulWidget {
  const CustomVideoEditor({super.key, required this.file});

  final File? file;

  @override
  State<CustomVideoEditor> createState() => _CustomVideoEditorState();
}

class _CustomVideoEditorState extends State<CustomVideoEditor> {
  final _exportingProgress = ValueNotifier<double>(0.0);
  final _isExporting = ValueNotifier<bool>(false);
  final double height = 60;

  late VideoEditorController _controller;

  @override
  void initState() {
    super.initState();
    EditorController.instance.initLindi();
  }

  @override
  void dispose() {
    _exportingProgress.dispose();
    _isExporting.dispose();
    // Fire-and-forget: dispose() must remain synchronous and call
    // super.dispose() without awaiting, otherwise the framework throws
    // "dispose() did not call super.dispose()".
    _controller.dispose();
    ExportService.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 1),
        ),
      );
  String? selectedAudioPath;

  // ---- Background-music options (Audio tab) ----
  double musicVolume = 0.6;
  bool keepOriginalAudio = true;
  bool musicFade = true;
  bool loopMusic = true;
  bool duckMusic = false;

  /// Target output height in pixels; 0 keeps the source resolution.
  /// Lets users shrink HD/2K/4K/8K sources to a smaller file size.
  int exportHeight = 0;

  /// x264 CRF: lower = better quality and larger file (18 high, 23 balanced,
  /// 28 small).
  int exportCrf = 23;

  Future<bool> _showExportOptionsDialog() async {
    const resolutions = <String, int>{
      'Original': 0,
      '2K (1440p)': 1440,
      'FHD (1080p)': 1080,
      'HD (720p)': 720,
      'SD (480p)': 480,
    };
    const qualities = <String, int>{
      'High quality': 18,
      'Balanced': 23,
      'Small size': 28,
    };

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Export Settings'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Resolution'),
                vSizedBox0,
                Wrap(
                  spacing: 6,
                  children: resolutions.entries
                      .map(
                        (entry) => ChoiceChip(
                          label: Text(entry.key),
                          selected: exportHeight == entry.value,
                          onSelected: (_) {
                            setDialogState(() {
                              exportHeight = entry.value;
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
                vSizedBox1,
                const Text('Quality / file size'),
                vSizedBox0,
                Wrap(
                  spacing: 6,
                  children: qualities.entries
                      .map(
                        (entry) => ChoiceChip(
                          label: Text(entry.key),
                          selected: exportCrf == entry.value,
                          onSelected: (_) {
                            setDialogState(() {
                              exportCrf = entry.value;
                            });
                          },
                        ),
                      )
                      .toList(),
                ),
                vSizedBox1,
                const Text(
                  'Tip: lowering the resolution of HD/2K/4K/8K videos '
                  'greatly reduces the exported file size.',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Export'),
            ),
          ],
        ),
      ),
    );
    return confirmed ?? false;
  }

  /// Post-processing is only needed when the user wants to downscale, change
  /// compression, or burn text/sticker overlays into the video. Free
  /// (non-premium) exports also need a pass to stamp the watermark.
  bool get _needsPostProcess =>
      exportHeight > 0 ||
      exportCrf != 23 ||
      !SettingsController.instance.isPremium ||
      EditorController.instance.lindiController.widgets.isNotEmpty;

  /// Watermark drawtext filter for free users (empty for premium). FFmpeg
  /// failures here fall back gracefully to an un-watermarked export.
  String _watermarkFilter() {
    if (SettingsController.instance.isPremium) return '';
    return "drawtext=text='feelm':fontcolor=white@0.75:"
        "fontsize=h/22:x=w-tw-20:y=h-th-20:box=1:boxcolor=black@0.35:"
        "boxborderw=8";
  }

  void _exportVideo() async {
    // Let the user choose resolution and compression before exporting.
    final proceed = await _showExportOptionsDialog();
    if (!proceed || !mounted) return;

    _exportingProgress.value = 0;
    _isExporting.value = true;

    FFmpegKit.cancel();

    // Give the user visible export feedback with a live progress bar.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _exportProgressDialog(),
    );

    final needsPost = _needsPostProcess;

    // Pass 1: let the package build a correctly trimmed/cropped/rotated file
    // (this keeps trim + audio handling exactly as the library intends).
    final config = VideoFFmpegVideoEditorConfig(_controller);
    await ExportService.runFFmpegCommand(
      await config.getExecuteConfig(),
      onProgress: (stats) {
        final progress = config.getFFmpegProgress(stats.getTime().toInt());
        // Leave headroom on the bar for the post-processing pass.
        _exportingProgress.value = needsPost ? progress * 0.85 : progress;
      },
      onError: (e, s) {
        log("Export Error $e");
        log("Export Stack $s");
        _failExport();
      },
      onCompleted: (file) async {
        if (needsPost) {
          await _postProcessExport(file);
        } else {
          _finishExport(file);
        }
      },
    );
  }

  void _failExport() {
    _isExporting.value = false;
    _closeExportDialog();
    _showErrorSnackBar("Error on export video :(");
  }

  void _finishExport(File file) {
    _exportingProgress.value = 1.0;
    _isExporting.value = false;
    _closeExportDialog();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => VideoResultPopup(
        video: file,
        aspectRatio: aspectRatio,
      ),
    );
  }

  int _evenWidthForHeight(int height) {
    int w = (height * aspectRatio).round();
    if (w.isOdd) w += 1;
    return w;
  }

  String _scaleAndCompressCommand(String input, String output) {
    final filters = <String>[];
    if (exportHeight > 0) filters.add('scale=-2:$exportHeight');
    final watermark = _watermarkFilter();
    if (watermark.isNotEmpty) filters.add(watermark);
    final vf = filters.isEmpty ? '' : '-vf "${filters.join(',')}" ';
    return '-y -i $input $vf-c:v libx264 -crf $exportCrf '
        '-preset fast -c:a aac $output';
  }

  // Pass 2: optionally downscale/compress and burn in text + sticker overlays.
  Future<void> _postProcessExport(File editedFile) async {
    _exportingProgress.value = 0.9;
    final basePath = await getOutputDirectoryPath();
    final outputPath = "${basePath}export_final.mp4";
    final overlays = EditorController.instance.lindiController.widgets;

    String command;
    if (overlays.isNotEmpty) {
      // Capture the (transparent) sticker/text layer as a PNG and overlay it.
      final bytes =
          await EditorController.instance.lindiController.saveAsUint8List();
      if (bytes != null) {
        final overlayPath = "${basePath}overlay.png";
        await File(overlayPath).writeAsBytes(bytes);

        final h = exportHeight > 0 ? exportHeight : 720;
        final w = _evenWidthForHeight(h);
        final watermark = _watermarkFilter();
        final overlayNode = watermark.isEmpty
            ? '[base][ovr]overlay=0:0[outv]'
            : '[base][ovr]overlay=0:0,$watermark[outv]';
        command = '-y -i ${editedFile.path} -i $overlayPath -filter_complex '
            '"[0:v]scale=$w:$h:force_original_aspect_ratio=increase,'
            'crop=$w:$h[base];[1:v]scale=$w:$h[ovr];'
            '$overlayNode" -map "[outv]" -map 0:a? '
            '-c:v libx264 -crf $exportCrf -preset fast -c:a aac -shortest '
            '$outputPath';
      } else {
        command = _scaleAndCompressCommand(editedFile.path, outputPath);
      }
    } else {
      command = _scaleAndCompressCommand(editedFile.path, outputPath);
    }

    log("Post-process command: $command");
    await FFmpegKit.execute(command).then((session) async {
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        _finishExport(File(outputPath));
      } else {
        log("Post-process error: ${(await session.getOutput()).toString()}");
        // Fall back to the un-processed (but correctly edited) file so the
        // user still gets a usable export.
        _finishExport(editedFile);
      }
    });
  }

  void _closeExportDialog() {
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Widget _exportProgressDialog() {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        content: ValueListenableBuilder<double>(
          valueListenable: _exportingProgress,
          builder: (_, value, __) {
            final clamped = value.clamp(0.0, 1.0);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Exporting video..."),
                vSizedBox2,
                LinearProgressIndicator(
                  value: clamped == 0 ? null : clamped,
                ),
                vSizedBox1,
                Text("${(clamped * 100).toStringAsFixed(0)}%"),
              ],
            );
          },
        ),
      ),
    );
  }

  void _exportCover() async {
    final config = CoverFFmpegVideoEditorConfig(_controller);
    final execute = await config.getExecuteConfig();
    if (execute == null) {
      _showErrorSnackBar("Error on cover exportation initialization.");
      return;
    }

    await ExportService.runFFmpegCommand(
      execute,
      onError: (e, s) => _showErrorSnackBar("Error on cover exportation :("),
      onCompleted: (cover) {
        if (!mounted) return;

        showDialog(
          context: context,
          builder: (_) => CoverResultPopup(cover: cover),
        );
      },
    );
  }

  void _showBusyDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      ),
    );
  }

  /// Runs an advanced FFmpeg operation with a busy dialog, then shows the
  /// result (a playable/GIF popup) or an info snackbar for non-video outputs.
  Future<void> _runAdvancedOp(
    Future<String?> Function() op, {
    required String working,
    bool showResultPopup = true,
    String infoOnSuccess = '',
  }) async {
    _showBusyDialog(working);
    String? out;
    try {
      out = await op();
    } catch (e) {
      log("Advanced op error: $e");
    }
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    if (!mounted) return;
    if (out == null) {
      _showErrorSnackBar("Couldn't complete this operation");
      return;
    }
    if (showResultPopup) {
      showDialog(
        context: context,
        builder: (_) => VideoResultPopup(
          video: File(out!),
          aspectRatio: aspectRatio,
        ),
      );
    } else {
      _showErrorSnackBar(infoOnSuccess.isEmpty ? "Saved: $out" : infoOnSuccess);
    }
  }

  void _exportGif() => _runAdvancedOp(
        () => AdvancedEditService.toGif(_controller.file.path),
        working: "Creating GIF...",
      );

  void _extractAudio() => _runAdvancedOp(
        () => AdvancedEditService.extractAudio(_controller.file.path),
        working: "Extracting audio...",
        showResultPopup: false,
        infoOnSuccess: "Audio (MP3) saved to your device",
      );

  /// Saves the currently displayed frame as a JPEG photo.
  void _grabFrame() async {
    final seconds = _controller.video.value.position.inMilliseconds / 1000.0;
    _showBusyDialog("Saving frame...");
    String? path;
    try {
      path = await AdvancedEditService.grabFrame(_controller.file.path, seconds);
    } catch (e) {
      log("Grab frame error: $e");
    }
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    if (!mounted) return;
    if (path == null) {
      _showErrorSnackBar("Couldn't save the frame");
      return;
    }
    showDialog(
      context: context,
      builder: (_) => CoverResultPopup(cover: File(path!)),
    );
  }

  void _autoEnhance() => _runAdvancedOp(
        () => AutoAnalysisService.adaptiveEnhance(_controller.file.path),
        working: "Analyzing & enhancing colours...",
      );

  /// AI shake-cut: analyzes per-frame motion and removes shaky sections.
  void _autoCutShaky() async {
    final total = _controller.video.value.duration.inMilliseconds / 1000.0;
    _showBusyDialog("Scanning for shaky sections...");
    String? out;
    try {
      out = await AutoAnalysisService.removeShakyParts(
          _controller.file.path, total);
    } catch (e) {
      log("Shake cut error: $e");
    }
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    if (!mounted) return;
    if (out == null) {
      _showErrorSnackBar("No shaky sections found to trim");
      return;
    }
    showDialog(
      context: context,
      builder: (_) => VideoResultPopup(
        video: File(out!),
        aspectRatio: aspectRatio,
      ),
    );
  }

  /// AI Auto Frame: on-device subject detection -> reframe to the selected
  /// aspect ratio centered on the subject.
  void _autoFrame() async {
    final size = _controller.video.value.size;
    final total = _controller.video.value.duration.inMilliseconds / 1000.0;
    _showBusyDialog("Finding the subject and reframing...");
    String? out;
    try {
      out = await AutoFrameService.autoFrame(
        _controller.file.path,
        total,
        size.width.round(),
        size.height.round(),
        targetAspect: aspectRatio,
      );
    } catch (e) {
      log("Auto frame error: $e");
    }
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    if (!mounted) return;
    if (out == null) {
      _showErrorSnackBar("No clear subject found to reframe around");
      return;
    }
    showDialog(
      context: context,
      builder: (_) => VideoResultPopup(
        video: File(out!),
        aspectRatio: aspectRatio,
      ),
    );
  }

  /// AI auto-cut: removes silent gaps. Distinguishes "nothing to cut" from a
  /// real failure.
  void _autoCut() async {
    final total = _controller.video.value.duration.inMilliseconds / 1000.0;
    _showBusyDialog("Scanning and trimming silent parts...");
    String? out;
    try {
      out = await AdvancedEditService.autoCutSilence(
          _controller.file.path, total);
    } catch (e) {
      log("Auto cut error: $e");
    }
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    if (!mounted) return;
    if (out == null) {
      _showErrorSnackBar("No silent gaps found to trim");
      return;
    }
    showDialog(
      context: context,
      builder: (_) => VideoResultPopup(
        video: File(out!),
        aspectRatio: aspectRatio,
      ),
    );
  }

  int selectedOption = 0;
  double aspectRatio = 9 / 16;
  updateAspectRatio(double ar) async {
    setState(() {
      aspectRatio = ar;
    });
  }

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Close Editor?'),
        content: const Text('Do you want to close the editor?'),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EditorController>(
      didChangeDependencies: (state) {
        // In GetBuilder's lifecycle callbacks the argument is the
        // GetBuilderState; the controller is reached via `.controller`.
        _controller = VideoEditorController.file(
          File(state.controller?.currentPlayablePath ?? widget.file!.path),
          minDuration: const Duration(seconds: 1),
          maxDuration: const Duration(minutes: 10),
        )..initialize().then((_) => setState(() {})).catchError((error) {
            // handle minumum duration bigger than video duration error
            if (context.mounted) Navigator.pop(context);
          }, test: (e) => e is VideoMinDurationError);
      },
      builder: (_) {
        return WillPopScope(
          onWillPop: () async {
            // Show confirmation dialog
            bool confirm = await _showExitConfirmationDialog(context);
            // Return true if the user confirmed, false otherwise
            return confirm;
          },
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            backgroundColor: Colors.black,
            body: _controller.initialized
                ? SafeArea(
                    child: Column(
                      children: [
                        _topNavBar(),
                        // Expanded(
                        //   child: AspectRatio(
                        //     aspectRatio: 9 / 16,
                        //     child: VideoPlayer(_controller.video),
                        //   ),
                        // ),

                        Expanded(
                          child: DefaultTabController(
                            length: 2,
                            child: Column(
                              children: [
                                Expanded(
                                  child: TabBarView(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    children: [
                                      // Stack(
                                      //   alignment: Alignment.center,
                                      //   children: [

                                      // AnimatedBuilder(
                                      //   animation: _controller.video,
                                      //   builder: (_, __) => AnimatedOpacity(
                                      //     opacity:
                                      //         _controller.isPlaying ? 0 : 1,
                                      //     duration: kThemeAnimationDuration,
                                      //     child: GestureDetector(
                                      //       onTap: _controller.video.play,
                                      //       child: Container(
                                      //         width: 40,
                                      //         height: 40,
                                      //         decoration:
                                      //             const BoxDecoration(
                                      //           color: Colors.white,
                                      //           shape: BoxShape.circle,
                                      //         ),
                                      //         child: const Icon(
                                      //           Icons.play_arrow,
                                      //           color: Colors.black,
                                      //         ),
                                      //       ),
                                      //     ),
                                      //   ),
                                      //     // ),
                                      //   ],
                                      // ),
                                      AspectRatio(
                                        aspectRatio: aspectRatio,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            // Video preview sits behind the
                                            // sticker layer so the Lindi canvas
                                            // can be captured with a transparent
                                            // background for export burn-in.
                                            CropGridViewer.preview(
                                              controller: _controller,
                                            ),
                                            LindiStickerWidget(
                                              controller: _.lindiController,
                                              child: const SizedBox.expand(),
                                            ),
                                          ],
                                        ),
                                      ),
                                      CoverViewer(controller: _controller),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () {
                                disavleAudio();
                              },
                              icon: isAudioMute == true
                                  ? const Icon(Icons.volume_off_rounded)
                                  : const Icon(Icons.volume_up_rounded),
                            ),
                            IconButton(
                              onPressed: () {
                                if (_controller.video.value.isPlaying) {
                                  _controller.video.pause();
                                } else {
                                  _controller.video.play();
                                }
                                setState(() {});
                              },
                              icon: _controller.video.value.isPlaying
                                  ? const Icon(Icons.pause_circle)
                                  : const Icon(Icons.play_circle_fill_rounded),
                            ),
                          ],
                        ),
                        const Divider(),
                        vSizedBox1,
                        SizedBox(
                          height: 150,
                          child: LayoutBuilder(
                            builder: (BuildContext context,
                                BoxConstraints constraints) {
                              if (selectedOption == 0) {
                                return Column(children: _trimSlider());
                              }
                              if (selectedOption == 1) {
                                return _coverSelection();
                              }
                              if (selectedOption == 2) {
                                return _colorAdjustment();
                              }
                              if (selectedOption == 3) {
                                return _speedAdjustment();
                              }
                              if (selectedOption == 4) {
                                return _filterWidget();
                                // return FilterPageScreen(
                                //   path: widget.file!.path,
                                // );
                              }
                              if (selectedOption == 5) {
                                return _textWidget();
                              }
                              if (selectedOption == 6) {
                                return _aspectRatioWidget();
                              }
                              if (selectedOption == 7) {
                                return _audioWidget();
                              }
                              if (selectedOption == 8) {
                                return _transformWidget();
                              }
                              if (selectedOption == 9) {
                                return _stickerWidget();
                              }
                              if (selectedOption == 10) {
                                return _greenScreenWidget();
                              }
                              return Container();
                            },
                          ),
                        ),
                        SizedBox(
                          height: 70,
                          child: ListView(
                            padding: screenLeftRightPadding,
                            scrollDirection: Axis.horizontal,
                            children: [
                              _optionWidget(
                                Icons.content_cut_rounded,
                                "Trim",
                                0,
                              ),
                              _optionWidget(
                                Icons.video_label,
                                "Cover",
                                1,
                              ),
                              _optionWidget(
                                Icons.adjust_rounded,
                                "Adjust",
                                2,
                              ),
                              _optionWidget(
                                Icons.speed_rounded,
                                "Speed",
                                3,
                              ),
                              _optionWidget(
                                Icons.filter_hdr_rounded,
                                "Filters",
                                4,
                              ),
                              _optionWidget(
                                Icons.text_fields_rounded,
                                "Text",
                                5,
                              ),
                              _optionWidget(
                                Icons.aspect_ratio_rounded,
                                "Aspect Ratio",
                                6,
                              ),
                              _optionWidget(
                                Icons.music_note_rounded,
                                "Audio",
                                7,
                              ),
                              _optionWidget(
                                Icons.flip_rounded,
                                "Transform",
                                8,
                              ),
                              _optionWidget(
                                Icons.emoji_emotions_rounded,
                                "Stickers",
                                9,
                              ),
                              _optionWidget(
                                Icons.movie_filter_rounded,
                                "Green Screen",
                                10,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
        );
      },
    );
  }

  int filterOption = 0;
  Widget _filterWidget() {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText.ourText(
                "Cinematic filters — tap a look to apply it",
              ),
              vSizedBox1,
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int i = 0;
                      i < FilterService.cinematicFilters.length;
                      i++)
                    ChoiceChip(
                      label: Text(FilterService.cinematicFilters[i].name),
                      selected: filterOption == i,
                      onSelected: isApplyingFilter
                          ? null
                          : (_) => applyFilter(
                              FilterService.cinematicFilters[i].vf, i),
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.auto_fix_high_rounded, size: 18),
                    label: const Text("Auto Enhance"),
                    onPressed: isApplyingFilter ? null : () => _autoEnhance(),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (isApplyingFilter)
          const Positioned.fill(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
      ],
    );
  }

  bool isTransforming = false;
  void applyTransform(String videoFilter, {String audioFilter = ''}) async {
    setState(() {
      isTransforming = true;
    });
    String basePath = await getOutputDirectoryPath();
    String outputPath = "${basePath}transform.mp4";
    String command =
        '-y -i ${_controller.file.path} $videoFilter $audioFilter $outputPath';
    log(command);
    await FFmpegKit.execute(command).then((session) async {
      final returnCode = await session.getReturnCode();
      final output = await session.getOutput();
      if (ReturnCode.isSuccess(returnCode)) {
        log("Successfully transformed");
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => VideoResultPopup(
              video: File(outputPath),
              aspectRatio: aspectRatio,
            ),
          );
        }
      } else {
        log("Transform error: ${output.toString()}");
        _showErrorSnackBar("Couldn't apply transform");
      }
    });
    if (mounted) {
      setState(() {
        isTransforming = false;
      });
    }
  }

  Widget _transformWidget() {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                ),
                onPressed: isTransforming
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AiPolishScreen(
                              video: _controller.file,
                              aspectRatio: aspectRatio,
                            ),
                          ),
                        ),
                icon: const Icon(Icons.auto_awesome),
                label: const Text("AI Polish"),
              ),
              ElevatedButton.icon(
                onPressed: isTransforming
                    ? null
                    : () => applyTransform('-vf hflip'),
                icon: const Icon(Icons.flip),
                label: const Text("Flip Horizontal"),
              ),
              ElevatedButton.icon(
                onPressed: isTransforming
                    ? null
                    : () => applyTransform('-vf vflip'),
                icon: const Icon(Icons.flip),
                label: const Text("Flip Vertical"),
              ),
              ElevatedButton.icon(
                onPressed: isTransforming
                    ? null
                    : () => applyTransform('-vf reverse',
                        audioFilter: '-af areverse'),
                icon: const Icon(Icons.fast_rewind_rounded),
                label: const Text("Reverse"),
              ),
              ElevatedButton.icon(
                onPressed: isTransforming
                    ? null
                    // Fits any clip into a 9:16 frame with a blurred,
                    // zoomed copy of itself as the background padding.
                    : () => applyTransform(
                        '-filter_complex "[0:v]scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,boxblur=20:5[bg];[0:v]scale=1080:-2[fg];[bg][fg]overlay=(W-w)/2:(H-h)/2" -c:a copy'),
                icon: const Icon(Icons.blur_on_rounded),
                label: const Text("Blur Pad 9:16"),
              ),
              ElevatedButton.icon(
                onPressed: isTransforming
                    ? null
                    : () => _runAdvancedOp(
                          () => AdvancedEditService.boomerang(
                              _controller.file.path),
                          working: "Creating boomerang...",
                        ),
                icon: const Icon(Icons.all_inclusive_rounded),
                label: const Text("Boomerang"),
              ),
              ElevatedButton.icon(
                onPressed: isTransforming
                    ? null
                    : () => _runAdvancedOp(
                          () => AdvancedEditService.fadeInOut(
                            _controller.file.path,
                            _controller.video.value.duration.inMilliseconds /
                                1000.0,
                          ),
                          working: "Applying fade in/out...",
                        ),
                icon: const Icon(Icons.gradient_rounded),
                label: const Text("Fade In/Out"),
              ),
              ElevatedButton.icon(
                onPressed: isTransforming
                    ? null
                    // 3D perspective tilt: pinches the top edge inward to
                    // simulate the video rotating back in 3D space.
                    : () => applyTransform(
                        '-vf "perspective=x0=W*0.08:y0=0:x1=W*0.92:y1=0:x2=0:y2=H:x3=W:y3=H:interpolation=linear" -c:a copy'),
                icon: const Icon(Icons.threed_rotation_rounded),
                label: const Text("3D Tilt"),
              ),
              ElevatedButton.icon(
                onPressed: isTransforming
                    ? null
                    // Ken Burns: a slow, animated push-in (keyframe-style
                    // zoom) across the whole clip. Comma-free expressions so
                    // no nested quoting is needed inside the -vf value.
                    : () => applyTransform(
                        '-vf "scale=1280:-2,zoompan=z=zoom+0.0008:d=1:x=iw/2-(iw/zoom/2):y=ih/2-(ih/zoom/2):s=1280x720:fps=30" -c:a copy'),
                icon: const Icon(Icons.zoom_in_map_rounded),
                label: const Text("Ken Burns Zoom"),
              ),
              ElevatedButton.icon(
                onPressed: isTransforming ? null : () => _autoCut(),
                icon: const Icon(Icons.content_cut_rounded),
                label: const Text("AI Auto Cut"),
              ),
              ElevatedButton.icon(
                onPressed: isTransforming ? null : () => _autoCutShaky(),
                icon: const Icon(Icons.vibration_rounded),
                label: const Text("AI Remove Shaky"),
              ),
              ElevatedButton.icon(
                onPressed: isTransforming ? null : () => _autoFrame(),
                icon: const Icon(Icons.center_focus_strong_rounded),
                label: const Text("AI Auto Frame"),
              ),
              ElevatedButton.icon(
                onPressed: isTransforming
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                KeyframeScreen(video: _controller.file),
                          ),
                        ),
                icon: const Icon(Icons.animation_rounded),
                label: const Text("Keyframe Animation"),
              ),
              ElevatedButton.icon(
                onPressed: isTransforming
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SpeedScreen(video: _controller.file),
                          ),
                        ),
                icon: const Icon(Icons.speed_rounded),
                label: const Text("Speed"),
              ),
              ElevatedButton.icon(
                onPressed: isTransforming
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PipScreen(video: _controller.file),
                          ),
                        ),
                icon: const Icon(Icons.picture_in_picture_alt_rounded),
                label: const Text("Picture in Picture"),
              ),
              ElevatedButton.icon(
                onPressed: isTransforming
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                TransitionScreen(video: _controller.file),
                          ),
                        ),
                icon: const Icon(Icons.movie_filter_rounded),
                label: const Text("Transition"),
              ),
              ElevatedButton.icon(
                onPressed: isTransforming
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TextScreen(video: _controller.file),
                          ),
                        ),
                icon: const Icon(Icons.text_fields_rounded),
                label: const Text("Text"),
              ),
              ElevatedButton.icon(
                onPressed: isTransforming
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                CaptionStudioScreen(video: _controller.file),
                          ),
                        ),
                icon: const Icon(Icons.closed_caption_rounded),
                label: const Text("Captions"),
              ),
              ElevatedButton.icon(
                onPressed: isTransforming
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ExportPresetScreen(video: _controller.file),
                          ),
                        ),
                icon: const Icon(Icons.ios_share_rounded),
                label: const Text("Social Export"),
              ),
              ElevatedButton.icon(
                onPressed: isTransforming
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CompressScreen(
                              video: _controller.file,
                              aspectRatio: aspectRatio,
                            ),
                          ),
                        ),
                icon: const Icon(Icons.compress_rounded),
                label: const Text("Compress"),
              ),
              ElevatedButton.icon(
                onPressed: isTransforming
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                WatermarkScreen(video: _controller.file),
                          ),
                        ),
                icon: const Icon(Icons.branding_watermark_rounded),
                label: const Text("Watermark"),
              ),
              ElevatedButton.icon(
                onPressed: isTransforming
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                RotateScreen(video: _controller.file),
                          ),
                        ),
                icon: const Icon(Icons.rotate_90_degrees_ccw_rounded),
                label: const Text("Rotate & Straighten"),
              ),
              ElevatedButton.icon(
                onPressed: isTransforming
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ColorAdjustScreen(video: _controller.file),
                          ),
                        ),
                icon: const Icon(Icons.tune_rounded),
                label: const Text("Color Adjust"),
              ),
              ElevatedButton.icon(
                onPressed: isTransforming
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => VfxScreen(video: _controller.file),
                          ),
                        ),
                icon: const Icon(Icons.movie_creation_outlined),
                label: const Text("Vignette & Grain"),
              ),
              ElevatedButton.icon(
                onPressed: isTransforming
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                BlurRegionScreen(video: _controller.file),
                          ),
                        ),
                icon: const Icon(Icons.blur_on_rounded),
                label: const Text("Blur Region"),
              ),
              ElevatedButton.icon(
                onPressed: isTransforming
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                MergeScreen(video: _controller.file),
                          ),
                        ),
                icon: const Icon(Icons.merge_type_rounded),
                label: const Text("Merge Clips"),
              ),
              ElevatedButton.icon(
                onPressed: isTransforming
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                SplitScreenScreen(video: _controller.file),
                          ),
                        ),
                icon: const Icon(Icons.splitscreen_rounded),
                label: const Text("Split Screen"),
              ),
              ElevatedButton.icon(
                onPressed: isTransforming
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SlideshowScreen(),
                          ),
                        ),
                icon: const Icon(Icons.slideshow_rounded),
                label: const Text("Photo Slideshow"),
              ),
              ElevatedButton.icon(
                onPressed: isTransforming
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                BorderScreen(video: _controller.file),
                          ),
                        ),
                icon: const Icon(Icons.crop_din_rounded),
                label: const Text("Frame / Border"),
              ),
              ElevatedButton.icon(
                onPressed: isTransforming
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                GifStudioScreen(video: _controller.file),
                          ),
                        ),
                icon: const Icon(Icons.gif_box_rounded),
                label: const Text("GIF Studio"),
              ),
              ElevatedButton.icon(
                onPressed: isTransforming
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ThumbnailDesignerScreen(
                                video: _controller.file),
                          ),
                        ),
                icon: const Icon(Icons.image_rounded),
                label: const Text("Thumbnail"),
              ),
              ElevatedButton.icon(
                onPressed: isTransforming
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => LoopScreen(
                              video: _controller.file,
                              aspectRatio: aspectRatio,
                            ),
                          ),
                        ),
                icon: const Icon(Icons.loop_rounded),
                label: const Text("Loop / Ping-pong"),
              ),
              ElevatedButton.icon(
                onPressed: isTransforming
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => MemeScreen(video: _controller.file),
                          ),
                        ),
                icon: const Icon(Icons.sentiment_very_satisfied),
                label: const Text("Meme"),
              ),
              ElevatedButton.icon(
                onPressed: isTransforming
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                CropRegionScreen(video: _controller.file),
                          ),
                        ),
                icon: const Icon(Icons.crop_rounded),
                label: const Text("Crop"),
              ),
              ElevatedButton.icon(
                onPressed: isTransforming
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => FadeScreen(
                              video: _controller.file,
                              aspectRatio: aspectRatio,
                            ),
                          ),
                        ),
                icon: const Icon(Icons.gradient_rounded),
                label: const Text("Intro/Outro Fade"),
              ),
              ElevatedButton.icon(
                onPressed: isTransforming
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => VolumeScreen(
                              video: _controller.file,
                              aspectRatio: aspectRatio,
                            ),
                          ),
                        ),
                icon: const Icon(Icons.volume_up_rounded),
                label: const Text("Volume"),
              ),
            ],
          ),
        ),
        if (isTransforming)
          const Positioned.fill(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
      ],
    );
  }

  /// Picks an image from the device and adds it as a draggable/resizable
  /// sticker on top of the video preview (powered by the Lindi sticker
  /// engine already used for text overlays).
  Future<void> pickSticker() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    final path = result?.files.single.path;
    if (path != null) {
      EditorController.instance.lindiController.addWidget(
        Image.file(
          File(path),
          width: 120,
        ),
      );
    }
  }

  Widget _stickerWidget() {
    return Column(
      children: [
        CustomText.ourText(
          "Add image stickers on top of your video",
        ),
        vSizedBox2,
        ElevatedButton.icon(
          onPressed: pickSticker,
          icon: const Icon(Icons.add_photo_alternate_rounded),
          label: const Text('Add Sticker'),
        ),
      ],
    );
  }

  bool isChromaKeying = false;

  /// Replaces the green background of the video with a user-picked image
  /// using FFmpeg's chromakey filter (Phase Two: green screen editing).
  Future<void> applyGreenScreen() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    final bgPath = result?.files.single.path;
    if (bgPath == null) return;

    setState(() {
      isChromaKeying = true;
    });
    final basePath = await getOutputDirectoryPath();
    final outputPath = "${basePath}greenscreen.mp4";

    // chromakey removes the green pixels, scale2ref sizes the background to
    // the video, and overlay composites the keyed footage on top.
    final command = '-y -i ${_controller.file.path} -i $bgPath '
        '-filter_complex "[0:v]chromakey=green:0.3:0.1[ckout];'
        '[1:v][ckout]scale2ref[bg][ck];[bg][ck]overlay=shortest=1[outv]" '
        '-map "[outv]" -map 0:a? -c:v libx264 -crf 23 -preset fast '
        '-c:a copy $outputPath';
    log(command);
    await FFmpegKit.execute(command).then((session) async {
      final returnCode = await session.getReturnCode();
      if (ReturnCode.isSuccess(returnCode)) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => VideoResultPopup(
              video: File(outputPath),
              aspectRatio: aspectRatio,
            ),
          );
        }
      } else {
        log("Green screen error: ${(await session.getOutput()).toString()}");
        _showErrorSnackBar(
            "Couldn't apply green screen (is the background green?)");
      }
    });
    if (mounted) {
      setState(() {
        isChromaKeying = false;
      });
    }
  }

  Widget _greenScreenWidget() {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            children: [
              CustomText.ourText(
                "Replace a green background with any image",
              ),
              vSizedBox1,
              CustomText.ourText(
                "Works best on footage shot in front of a green screen",
                fontSize: 12,
                color: Colors.grey,
              ),
              vSizedBox1,
              ElevatedButton.icon(
                onPressed: isChromaKeying ? null : applyGreenScreen,
                icon: const Icon(Icons.image_rounded),
                label: const Text('Pick Background & Apply'),
              ),
            ],
          ),
        ),
        if (isChromaKeying)
          const Positioned.fill(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
      ],
    );
  }

  Widget _audioWidget() {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            children: [
              CustomText.ourText(
                "Add background music to your video",
              ),
              vSizedBox1,
              ElevatedButton.icon(
                onPressed: isAudioSynchronizing ? null : pickAudio,
                icon: const Icon(Icons.library_music_outlined),
                label: Text(
                    selectedAudioPath == null ? 'Select Music' : 'Change Music'),
              ),
              if (selectedAudioPath != null) ...[
                vSizedBox1,
                CustomText.ourText(
                  "♪ ${selectedAudioPath!.split(Platform.pathSeparator).last}",
                ),
              ],
              vSizedBox1,
              CustomText.ourText(
                  "Music volume: ${(musicVolume * 100).round()}%"),
              Slider(
                value: musicVolume,
                min: 0.0,
                max: 1.0,
                divisions: 20,
                label: "${(musicVolume * 100).round()}%",
                onChanged: (val) => setState(() => musicVolume = val),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('Keep original audio (mix)'),
                value: keepOriginalAudio,
                onChanged: (v) => setState(() => keepOriginalAudio = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('Fade music in / out'),
                value: musicFade,
                onChanged: (v) => setState(() => musicFade = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('Loop music to fit'),
                value: loopMusic,
                onChanged: (v) => setState(() => loopMusic = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: const Text('Duck music under voice'),
                subtitle: const Text(
                  'Auto-lowers music while someone is speaking',
                  style: TextStyle(fontSize: 11),
                ),
                value: duckMusic,
                onChanged: keepOriginalAudio
                    ? (v) => setState(() => duckMusic = v)
                    : null,
              ),
              vSizedBox1,
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      (selectedAudioPath == null || isAudioSynchronizing)
                          ? null
                          : _applyBackgroundMusic,
                  icon: const Icon(Icons.music_note_rounded),
                  label: const Text('Add Music to Video'),
                ),
              ),
              vSizedBox1,
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isAudioSynchronizing
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AudioCleanupScreen(
                                video: _controller.file,
                                aspectRatio: aspectRatio,
                              ),
                            ),
                          ),
                  icon: const Icon(Icons.graphic_eq_rounded),
                  label: const Text('Audio Cleanup (noise / loudness)'),
                ),
              ),
              vSizedBox1,
              CustomText.ourText(
                  "Original audio volume: ${(videoVolume * 100).round()}%"),
              Slider(
                value: videoVolume,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: "${(videoVolume * 100).round()}%",
                onChanged: (val) {
                  setState(() {
                    videoVolume = val;
                    isAudioMute = val == 0;
                  });
                  _controller.video.setVolume(val);
                },
              ),
              vSizedBox1,
              if (waveformPath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    File(waveformPath!),
                    height: 56,
                    width: appWidth(context),
                    fit: BoxFit.fill,
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed:
                      isGeneratingWaveform ? null : _generateWaveform,
                  icon: const Icon(Icons.graphic_eq_rounded),
                  label: Text(isGeneratingWaveform
                      ? 'Generating waveform...'
                      : 'Visualize Audio Waveform'),
                ),
            ],
          ),
        ),
        if (isAudioSynchronizing)
          const Positioned.fill(
            child: Center(
              child: CircularProgressIndicator(),
            ),
          )
      ],
    );
  }

  Widget _aspectRatioWidget() {
    return Wrap(
      children: [
        OutlinedButton.icon(
          onPressed: aspectRatio == 16 / 9
              ? null
              : () {
                  updateAspectRatio(16 / 9);
                },
          icon: const Icon(Icons.aspect_ratio_rounded),
          label: const Text("16 : 9"),
        ),
        OutlinedButton.icon(
          onPressed: aspectRatio == 9 / 16
              ? null
              : () {
                  updateAspectRatio(9 / 16);
                },
          icon: const Icon(Icons.aspect_ratio_rounded),
          label: const Text("9 : 16"),
        ),
        OutlinedButton.icon(
          onPressed: aspectRatio == 4 / 3
              ? null
              : () {
                  updateAspectRatio(4 / 3);
                },
          icon: const Icon(Icons.aspect_ratio_rounded),
          label: const Text("4 : 3"),
        ),
        OutlinedButton.icon(
          onPressed: aspectRatio == 3 / 4
              ? null
              : () {
                  updateAspectRatio(3 / 4);
                },
          icon: const Icon(Icons.aspect_ratio_rounded),
          label: const Text("3 : 4"),
        ),
      ],
    );
  }

  Widget _buildColorButton(Color color) {
    return GetBuilder<EditorController>(builder: (_) {
      return GestureDetector(
        onTap: () {
          _.changeColor(color);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(
              color:
                  _.selectedColor == color ? Colors.white : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
    });
  }

  final TextEditingController? textController = TextEditingController();
  double textFontSize = 24;
  Widget _textWidget() {
    return GetBuilder<EditorController>(builder: (_) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Get.dialog(
                  AlertDialog(
                    title: const Text('Text Options'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: textController,
                          decoration: const InputDecoration(
                            labelText: 'Enter Text',
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text('Select Color:'),
                        const SizedBox(height: 5),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildColorButton(Colors.black),
                              _buildColorButton(Colors.white),
                              _buildColorButton(Colors.red),
                              _buildColorButton(Colors.blue),
                              _buildColorButton(Colors.green),
                              _buildColorButton(Colors.yellow),
                              _buildColorButton(Colors.orange),
                              _buildColorButton(Colors.purple),
                              _buildColorButton(Colors.grey),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        StatefulBuilder(
                          builder: (context, setDialogState) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Font size: ${textFontSize.round()}'),
                                Slider(
                                  value: textFontSize,
                                  min: 12,
                                  max: 80,
                                  divisions: 34,
                                  label: textFontSize.round().toString(),
                                  onChanged: (val) {
                                    setDialogState(() {
                                      textFontSize = val;
                                    });
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                    actions: [
                      MaterialButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Cancel'),
                      ),
                      MaterialButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _.lindiController.addWidget(
                            Text(
                              "${textController?.text.trim()}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: textFontSize,
                                color: _.selectedColor,
                              ),
                            ),
                          );
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                  barrierDismissible: false,
                );
              },
              child: const Text("Add Custom Text"),
            )
          ],
        ),
      );
    });
  }

  bool isAudioMute = false;
  double videoVolume = 1.0;
  String? waveformPath;
  bool isGeneratingWaveform = false;

  /// Renders the audio waveform of the current clip and shows it in the
  /// Audio tab.
  Future<void> _generateWaveform() async {
    setState(() {
      isGeneratingWaveform = true;
    });
    final path = await AiVideoService.generateWaveform(_controller.file.path);
    if (mounted) {
      setState(() {
        waveformPath = path;
        isGeneratingWaveform = false;
      });
    }
    if (path == null) {
      _showErrorSnackBar("Couldn't generate the audio waveform");
    }
  }
  void disavleAudio() async {
    if (isAudioMute) {
      // Restore to full volume when unmuting.
      videoVolume = 1.0;
    } else {
      videoVolume = 0.0;
    }
    _controller.video.setVolume(videoVolume);
    setState(() {
      isAudioMute = !isAudioMute;
    });
  }

  Widget _topNavBar() {
    return SafeArea(
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Leave editor',
              ),
            ),
            const VerticalDivider(endIndent: 22, indent: 22),
            Expanded(
              child: IconButton(
                onPressed: () =>
                    _controller.rotate90Degrees(RotateDirection.left),
                icon: const Icon(Icons.rotate_left),
                tooltip: 'Rotate unclockwise',
              ),
            ),
            Expanded(
              child: IconButton(
                onPressed: () =>
                    _controller.rotate90Degrees(RotateDirection.right),
                icon: const Icon(Icons.rotate_right),
                tooltip: 'Rotate clockwise',
              ),
            ),
            Expanded(
              child: IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => CropScreen(controller: _controller),
                  ),
                ),
                icon: const Icon(Icons.crop),
                tooltip: 'Open crop screen',
              ),
            ),
            const VerticalDivider(endIndent: 22, indent: 22),
            TextButton.icon(
              onPressed: () {
                _controller.video.pause();
                Get.to(() => AiScreen(file: widget.file!.path));
              },
              icon: const Icon(Icons.local_fire_department_rounded),
              label: const Text("Try AI"),
            ),
            Expanded(
              child: PopupMenuButton(
                tooltip: 'Open export menu',
                icon: const Icon(Icons.save),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    onTap: _exportVideo,
                    child: const Text('Export video'),
                  ),
                  PopupMenuItem(
                    onTap: _exportGif,
                    child: const Text('Export as GIF'),
                  ),
                  PopupMenuItem(
                    onTap: _extractAudio,
                    child: const Text('Extract audio (MP3)'),
                  ),
                  PopupMenuItem(
                    onTap: _grabFrame,
                    child: const Text('Save current frame'),
                  ),
                  PopupMenuItem(
                    onTap: _exportCover,
                    child: const Text('Export cover'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatter(Duration duration) => [
        duration.inMinutes.remainder(60).toString().padLeft(2, '0'),
        duration.inSeconds.remainder(60).toString().padLeft(2, '0')
      ].join(":");

  List<Widget> _trimSlider() {
    return [
      AnimatedBuilder(
        animation: Listenable.merge([
          _controller,
          _controller.video,
        ]),
        builder: (_, __) {
          final int duration = _controller.videoDuration.inSeconds;
          final double pos = _controller.trimPosition * duration;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: height / 4),
            child: Row(children: [
              Text(formatter(Duration(seconds: pos.toInt()))),
              const Expanded(child: SizedBox()),
              AnimatedOpacity(
                opacity: _controller.isTrimming ? 1 : 0,
                duration: kThemeAnimationDuration,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(formatter(_controller.startTrim)),
                  const SizedBox(width: 10),
                  Text(formatter(_controller.endTrim)),
                ]),
              ),
            ]),
          );
        },
      ),
      Container(
        width: MediaQuery.of(context).size.width,
        margin: EdgeInsets.symmetric(vertical: height / 4),
        child: TrimSlider(
          controller: _controller,
          height: height,
          horizontalMargin: height / 4,
          child: TrimTimeline(
            controller: _controller,
            padding: const EdgeInsets.only(top: 10),
          ),
        ),
      )
    ];
  }

  Widget _coverSelection() {
    return SingleChildScrollView(
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(15),
          child: CoverSelection(
            controller: _controller,
            size: height + 10,
            quantity: 8,
            selectedCoverBuilder: (cover, size) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  cover,
                  Icon(
                    Icons.check_circle,
                    color: const CoverSelectionStyle().selectedBorderColor,
                  )
                ],
              );
            },
          ),
        ),
      ),
    );
  }

// Function to pick an audio file
  /// Lets the user choose a music file. Selecting only stores the path; the
  /// user then tunes the options and taps "Add Music to Video" to render.
  Future<void> pickAudio() async {
    final audioFilePath = await FilePicker.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );
    final path = audioFilePath?.files.single.path;
    if (path != null) {
      setState(() => selectedAudioPath = path);
    }
  }

  bool isAudioSynchronizing = false;

  /// Mixes the selected music over the video using the chosen options and
  /// shows the result. The video stream is copied (no re-encode) and the clip
  /// length is preserved regardless of the music length.
  Future<void> _applyBackgroundMusic() async {
    final music = selectedAudioPath;
    if (music == null) {
      _showErrorSnackBar("Pick a music file first");
      return;
    }
    setState(() => isAudioSynchronizing = true);
    final total = _controller.video.value.duration.inMilliseconds / 1000.0;
    String? out;
    try {
      out = await AudioService.addMusic(
        _controller.file.path,
        music,
        totalSeconds: total,
        musicVolume: musicVolume,
        originalVolume: videoVolume,
        keepOriginal: keepOriginalAudio,
        fade: musicFade,
        loopMusic: loopMusic,
        duckUnderVoice: duckMusic,
      );
    } catch (e) {
      log("Add music error: $e");
    }
    if (!mounted) return;
    setState(() => isAudioSynchronizing = false);
    if (out == null) {
      _showErrorSnackBar("Couldn't add the music");
      return;
    }
    showDialog(
      context: context,
      builder: (_) => VideoResultPopup(
        video: File(out!),
        aspectRatio: aspectRatio,
      ),
    );
  }

  bool isApplyingFilter = false;

  /// Applies cinematic filter chain [vf] (from [FilterService]) at catalogue
  /// [index]. An empty chain is the untouched "Original": just clear the
  /// selection without re-rendering.
  void applyFilter(String vf, int index) async {
    if (vf.trim().isEmpty) {
      setState(() {
        filterOption = index;
        isApplyingFilter = false;
      });
      return;
    }

    setState(() {
      filterOption = index;
      isApplyingFilter = true;
    });
    final outputPath = "${await getOutputDirectoryPath()}filter.mp4";
    final command =
        FilterService.filterCommand(_controller.file.path, outputPath, vf);
    log(command);

    bool ok = false;
    try {
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      ok = ReturnCode.isSuccess(returnCode);
      if (!ok) log("Filter failed: ${await session.getOutput()}");
    } catch (e) {
      log("Filter error: $e");
    }
    if (!mounted) return;
    setState(() => isApplyingFilter = false);
    if (!ok) {
      _showErrorSnackBar("Couldn't apply this filter");
      return;
    }
    showDialog(
      context: context,
      builder: (_) => VideoResultPopup(
        video: File(outputPath),
        aspectRatio: aspectRatio,
      ),
    );
  }

  double getFFmpegProgress(String ffmpegLogs, num videoDurationInSec) {
    final regex = RegExp("(?<=time=)[\\d:.]*");
    final match = regex.firstMatch(ffmpegLogs);
    if (match != null) {
      final matchSplit = match.group(0).toString().split(":");
      if (videoDurationInSec != 0) {
        final progress = (int.parse(matchSplit[0]) * 3600 +
                int.parse(matchSplit[1]) * 60 +
                double.parse(matchSplit[2])) /
            videoDurationInSec;
        double showProgress = (progress * 100);
        return showProgress;
      }
    }
    return 0;
  }

  double speed = 1.0;
  Widget _speedAdjustment() {
    return Column(
      children: [
        const Text("Speed"),
        Slider(
          value: speed,
          onChanged: (val) {
            setState(() {
              speed = val;
            });
          },
          onChangeEnd: (val) {
            _controller.video.setPlaybackSpeed(val);
          },
          min: 0.25,
          max: 2.0,
          divisions: 7,
          label: speed.toStringAsFixed(2),
        ),
        ElevatedButton(
          onPressed: () {
            setState(() {
              speed = 1.0;
            });
            _controller.video.setPlaybackSpeed(1);
          },
          child: const Text("Reset to Normal"),
        )
      ],
    );
  }

  Widget _colorAdjustment() {
    return GetBuilder<EditorController>(
      builder: (_) {
        return Stack(
          children: [
            ListView(
              children: [
                Row(children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        _.resetAdjustment();
                      },
                      icon: const Icon(Icons.restore),
                      label: const Text("Reset"),
                    ),
                  ),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        adjustmentsAndSave(
                          brightness: _.brightness,
                          contrast: _.contrast,
                          saturation: _.saturation,
                        );
                      },
                      icon: const Icon(Icons.done),
                      label: const Text("Apply"),
                    ),
                  ),
                ]),
                _buildSlider(
                    label: 'Brightness',
                    value: _.brightness,
                    onChanged: _.changeBrigtness),
                vSizedBox2,
                _buildSlider(
                    label: 'Contrast',
                    value: _.contrast,
                    onChanged: _.changeContrast),
                vSizedBox2,
                _buildSlider(
                  label: 'Saturation',
                  value: _.saturation,
                  onChanged: _.changeSaturation,
                ),
              ],
            ),
            if (isAdjusting)
              const Positioned.fill(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
          ],
        );
      },
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required Function(double) onChanged,
  }) {
    return GetBuilder<EditorController>(
      builder: (_) {
        return Column(
          children: [
            Text(label),
            Slider(
              value: value,
              onChanged: onChanged,
              min: -1.0,
              max: 1.0,
              divisions: 20,
              label: value.toStringAsFixed(2),
            ),
          ],
        );
      },
    );
  }

  Future<String> getOutputPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final outputPath = '${directory.path}/processed_video.mp4';
    return outputPath;
  }

  bool isAdjusting = false;
  void adjustmentsAndSave(
      {double? brightness, double? contrast, double? saturation}) async {
    setState(() {
      isAdjusting = true;
    });
    log("Applying adjustment");
    String basePath = await getOutputDirectoryPath();
    String outputPath = "${basePath}adjustment.mp4";

    //high quality filter
    // String command =
    //     '-y -i ${_controller.file.path} -vf "drawtext=text=\'AMAZED\':x=100:y=100:fontsize=50:fontcolor=white,eq=saturation=10.0" -c:v libx264 -crf 18 -preset medium -c:a copy $outputPath';
    String command =
        '-y -i ${_controller.file.path} -vf "eq=saturation=$saturation:brightness=$brightness:contrast=$contrast" -c:a copy $outputPath';

    log(command);
    await FFmpegKit.execute(command).then((session) async {
      final returnCode = await session.getReturnCode();
      final state =
          FFmpegKitConfig.sessionStateToString(await session.getState());
      final output = await session.getOutput();
      if (ReturnCode.isSuccess(returnCode)) {
        log("Successfully adjustment applied");
        // EditorController.instance.changeVideoPlayablePath(outputPath);
        if (!mounted) return;
        showDialog(
          context: context,
          builder: (_) => VideoResultPopup(
            video: File(outputPath),
            aspectRatio: aspectRatio,
          ),
        );
      } else if (ReturnCode.isCancel(returnCode)) {
        log("Cancel filter");
      } else {
        log("Error filter");
      }
      log(state);
      log(output.toString());
      log(returnCode.toString());
    });
    setState(() {
      isAdjusting = false;
    });
  }

  Widget _optionWidget(IconData icon, String title, int index) {
    final bool isSelected = selectedOption == index;
    return InkWell(
      onTap: () {
        setState(() {
          selectedOption = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.yellow.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.yellow : Colors.transparent,
            width: 0.8,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.yellow : Colors.white,
              size: 24,
            ),
            vSizedBox0,
            CustomText.ourText(title,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.yellow : Colors.white),
          ],
        ),
      ),
    );
  }
}

class FilterOption {
  final String name;
  final String image;

  FilterOption({required this.name, required this.image});
}

enum FilterEnum {
  grayscale,
  highSaturation,
  sepiaToneEffect,
  none,
}
