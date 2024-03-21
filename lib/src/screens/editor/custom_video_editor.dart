import 'dart:developer';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lindi_sticker_widget/lindi_sticker_widget.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_editor/video_editor.dart';
import 'package:video_editor_mobile_app/src/constant/dimension.dart';
import 'package:video_editor_mobile_app/src/controllers/editor_controller.dart';
import 'package:video_editor_mobile_app/src/screens/ai/ai_screen.dart';
import 'package:video_editor_mobile_app/src/screens/editor/crop_screen.dart';
import 'package:video_editor_mobile_app/src/widgets/custom_text.dart';

import '../../services/export_services.dart';
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
  void dispose() async {
    _exportingProgress.dispose();
    _isExporting.dispose();
    await _controller.dispose();
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
  void _exportVideo() async {
    _exportingProgress.value = 0;
    _isExporting.value = true;

    FFmpegKit.cancel();
    final config = VideoFFmpegVideoEditorConfig(
      _controller,
      commandBuilder: (config, videoPath, outputPath) {
        return '-y -i $videoPath -vf "eq=brightness=0.3:contrast=1.5:saturation=1.5,hue=s=0" $outputPath';
      },
    );
    await ExportService.runFFmpegCommand(
      await config.getExecuteConfig(),
      onProgress: (stats) {
        _exportingProgress.value =
            config.getFFmpegProgress(stats.getTime() as int);
      },
      onError: (e, s) {
        log("Export Error $e");
        log("Export Stack $s");
        _showErrorSnackBar("Error on export video :(");
      },
      onCompleted: (file) {
        _isExporting.value = false;
        if (!mounted) return;

        showDialog(
          context: context,
          builder: (_) => VideoResultPopup(
            video: file,
            aspectRatio: aspectRatio,
          ),
        );
      },
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

  int selectedOption = 0;
  double aspectRatio = 9 / 16;
  updateAspectRatio(double ar) async {
    setState(() {
      aspectRatio = ar;
    });
  }

  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    return await showDialog(
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
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<EditorController>(
      didChangeDependencies: (_) {
        _controller = VideoEditorController.file(
          File(_.controller?.currentPlayablePath ?? widget.file!.path),
          minDuration: const Duration(seconds: 1),
          maxDuration: const Duration(seconds: 10),
        )..initialize().then((_) => setState(() {})).catchError((error) {
            // handle minumum duration bigger than video duration error
            Navigator.pop(context);
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
                                      LindiStickerWidget(
                                        controller: _.lindiController,
                                        child: AspectRatio(
                                          aspectRatio: aspectRatio,
                                          child: CropGridViewer.preview(
                                            controller: _controller,
                                          ),
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
        Wrap(
          spacing: 10,
          children: [
            ElevatedButton(
              onPressed: filterOption == 0
                  ? null
                  : () {
                      applyFilter('', 0);
                    },
              child: const Text("Original"),
            ),
            ElevatedButton(
              onPressed: filterOption == 1
                  ? null
                  : () {
                      applyFilter(
                          '-y -i ${_controller.file.path} -vf "eq=contrast=1.5:brightness=0.1:saturation=1.5:gamma=1.5:gamma_r=1.1:gamma_g=1.1:gamma_b=0.9"',
                          1);
                    },
              child: const Text("Sepia Tone Effect"),
            ),
            ElevatedButton(
              onPressed: filterOption == 2
                  ? null
                  : () {
                      applyFilter(
                          '-y -i ${_controller.file.path} -vf eq=saturation=30',
                          2);
                    },
              child: const Text("High Saturation"),
            ),
            ElevatedButton(
              onPressed: filterOption == 3
                  ? null
                  : () {
                      applyFilter(
                          '-y -i ${_controller.file.path} -vf hue=s=0', 3);
                    },
              child: const Text("Grayscale"),
            ),
          ],
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

  Widget _audioWidget() {
    return Stack(
      children: [
        Column(
          children: [
            CustomText.ourText(
              "Add your audio from your files system",
            ),
            vSizedBox2,
            ElevatedButton(
              onPressed: pickAudio,
              child: const Text('Select Audio'),
            ),
          ],
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
  void disavleAudio() async {
    if (isAudioMute) {
      _controller.video.setVolume(1);
    } else {
      _controller.video.setVolume(0);
    }
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
                    onTap: _exportCover,
                    child: const Text('Export cover'),
                  ),
                  PopupMenuItem(
                    onTap: _exportVideo,
                    child: const Text('Export video'),
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
  Future<void> pickAudio() async {
    final audioFilePath = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );
    if (audioFilePath != null) {
      setState(() {
        selectedAudioPath = audioFilePath.files.single.path;
      });
      addAudio("$selectedAudioPath");
    }
  }

  bool isAudioSynchronizing = false;
  void addAudio(String? audioFilePath) async {
    print("Applying audio");
    setState(() {
      isAudioSynchronizing = true;
    });
    String basePath = "/storage/emulated/0/Download/";
    String outputPath = "${basePath}audio.mp4";

    String command =
        '-y -i ${_controller.file.path} -i $audioFilePath -c:v copy -c:a aac -strict experimental -shortest $outputPath';

    print(command);
    await FFmpegKit.execute(command).then((session) async {
      final returnCode = await session.getReturnCode();
      final state =
          FFmpegKitConfig.sessionStateToString(await session.getState());
      final output = await session.getOutput();
      if (ReturnCode.isSuccess(returnCode)) {
        print("Successfully audio applied");
        // EditorController.instance.changeVideoPlayablePath(outputPath);

        showDialog(
          context: context,
          builder: (_) => VideoResultPopup(
            video: File(outputPath),
            aspectRatio: aspectRatio,
          ),
        );
      } else if (ReturnCode.isCancel(returnCode)) {
        print("Cancel audio");
      } else {
        print("Error audio");
      }
      log(state);
      log(output.toString());
      log(returnCode.toString());
      setState(() {
        isAudioSynchronizing = false;
      });
    });
  }

  bool isApplyingFilter = false;
  void applyFilter(String command, int index) async {
    print("Applying filter");
    setState(() {
      filterOption = index;
      isApplyingFilter = true;
    });
    String basePath = "/storage/emulated/0/Download/";
    String outputPath = "${basePath}filter.mp4";

    //high quality filter
    // String command =
    //     '-y -i ${_controller.file.path} -vf "drawtext=text=\'AMAZED\':x=100:y=100:fontsize=50:fontcolor=white,eq=saturation=10.0" -c:v libx264 -crf 18 -preset medium -c:a copy $outputPath';

    command += " $outputPath";
    print(command);
    if (command == "") {
      setState(() {
        isApplyingFilter = false;
      });
      return;
    }
    await FFmpegKit.execute(command).then((session) async {
      final returnCode = await session.getReturnCode();
      final state =
          FFmpegKitConfig.sessionStateToString(await session.getState());
      final output = await session.getOutput();
      if (ReturnCode.isSuccess(returnCode)) {
        print("Successfully filter applied");
        // EditorController.instance.changeVideoPlayablePath(outputPath);

        showDialog(
          context: context,
          builder: (_) => VideoResultPopup(
            video: File(outputPath),
            aspectRatio: aspectRatio,
          ),
        );
      } else if (ReturnCode.isCancel(returnCode)) {
        print("Cancel filter");
      } else {
        print("Error filter");
      }
      log(state);
      log(output.toString());
      log(returnCode.toString());
    });
    setState(() {
      isApplyingFilter = false;
    });
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

  double speed = 0.0;
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
          min: -1.0,
          max: 2.0,
          divisions: 7,
          label: speed.toStringAsFixed(2),
        ),
        ElevatedButton(
          onPressed: () {
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
    print("Applying adjustment");
    String basePath = "/storage/emulated/0/Download/";
    String outputPath = "${basePath}adjustment.mp4";

    //high quality filter
    // String command =
    //     '-y -i ${_controller.file.path} -vf "drawtext=text=\'AMAZED\':x=100:y=100:fontsize=50:fontcolor=white,eq=saturation=10.0" -c:v libx264 -crf 18 -preset medium -c:a copy $outputPath';
    String command =
        '-y -i ${_controller.file.path} -vf "eq=saturation=$saturation:brightness=$brightness:contrast=$contrast" -c:a copy $outputPath';

    print(command);
    await FFmpegKit.execute(command).then((session) async {
      final returnCode = await session.getReturnCode();
      final state =
          FFmpegKitConfig.sessionStateToString(await session.getState());
      final output = await session.getOutput();
      if (ReturnCode.isSuccess(returnCode)) {
        print("Successfully adjustment applied");
        // EditorController.instance.changeVideoPlayablePath(outputPath);

        showDialog(
          context: context,
          builder: (_) => VideoResultPopup(
            video: File(outputPath),
            aspectRatio: aspectRatio,
          ),
        );
      } else if (ReturnCode.isCancel(returnCode)) {
        print("Cancel filter");
      } else {
        print("Error filter");
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
    return InkWell(
      onTap: () {
        setState(() {
          selectedOption = index;
        });
      },
      child: Padding(
        padding: screenLeftRightPadding,
        child: Column(
          children: [
            vSizedBox0,
            Icon(
              icon,
              color: selectedOption == index ? Colors.yellow : Colors.white,
              size: 25,
            ),
            CustomText.ourText(title,
                fontSize: 13,
                color: selectedOption == index ? Colors.yellow : Colors.white),
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
