// import 'dart:developer';
// import 'dart:io';

// import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
// import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit_config.dart';
// import 'package:ffmpeg_kit_flutter_full_gpl/ffprobe_kit.dart';
// import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:lindi_sticker_widget/lindi_sticker_widget.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:video_editor/video_editor.dart';
// import 'package:video_editor_mobile_app/src/constant/dimension.dart';
// import 'package:video_editor_mobile_app/src/controllers/editor_controller.dart';
// import 'package:video_editor_mobile_app/src/screens/ai/ai_screen.dart';
// import 'package:video_editor_mobile_app/src/screens/editor/crop_screen.dart';
// import 'package:video_editor_mobile_app/src/widgets/custom_text.dart';

// import '../../services/export_services.dart';
// import 'video_result_popup.dart';

// class CustomVideoEditor extends StatefulWidget {
//   const CustomVideoEditor({super.key, required this.file});

//   final File? file;

//   @override
//   State<CustomVideoEditor> createState() => _CustomVideoEditorState();
// }

// class _CustomVideoEditorState extends State<CustomVideoEditor> {
//   final _exportingProgress = ValueNotifier<double>(0.0);
//   final _isExporting = ValueNotifier<bool>(false);
//   final double height = 60;

//   late VideoEditorController _controller = VideoEditorController.file(
//     File(widget.file!.path),
//     minDuration: const Duration(seconds: 1),
//     maxDuration: const Duration(seconds: 10),
//   );

//   @override
//   void initState() {
//     super.initState();
//     _controller.initialize().then((_) => setState(() {})).catchError((error) {
//       // handle minumum duration bigger than video duration error
//       Navigator.pop(context);
//     }, test: (e) => e is VideoMinDurationError);
//     EditorController.instance.initLindi();
//   }

//   reRenderPlay(String? path) async {
//     if (path == null) return;
//     _controller.video.pause();
//     if (_controller.initialized) {
//       await _controller.dispose();
//     }
//     _controller = VideoEditorController.file(
//       File(path),
//       minDuration: const Duration(seconds: 1),
//       maxDuration: const Duration(seconds: 10),
//     );
//     return _controller.initialize().then((_) => setState(() {})).catchError(
//         (error) {
//       // handle minumum duration bigger than video duration error
//       Navigator.pop(context);
//     }, test: (e) => e is VideoMinDurationError);
//   }

//   @override
//   void dispose() async {
//     _exportingProgress.dispose();
//     _isExporting.dispose();
//     _controller.dispose();
//     ExportService.dispose();
//     super.dispose();
//   }

//   void _showErrorSnackBar(String message) =>
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(message),
//           duration: const Duration(seconds: 1),
//         ),
//       );

//   void _exportVideo() async {
//     _exportingProgress.value = 0;
//     _isExporting.value = true;

//     final config = VideoFFmpegVideoEditorConfig(
//       _controller,
//       // format: VideoExportFormat.gif,
//       commandBuilder: (config, videoPath, outputPath) {
//         final List<String> filters = config.getExportFilters();
//         filters.add('hflip'); // add horizontal flip

//         return '-i $videoPath ${config.filtersCmd(filters)} -preset ultrafast $outputPath';
//       },
//     );

//     await ExportService.runFFmpegCommand(
//       await config.getExecuteConfig(),
//       onProgress: (stats) {
//         _exportingProgress.value =
//             config.getFFmpegProgress(stats.getTime() as int);
//       },
//       onError: (e, s) {
//         log("Export Error $e");
//         log("Export Stack $s");
//         _showErrorSnackBar("Error on export video :(");
//       },
//       onCompleted: (file) {
//         _isExporting.value = false;
//         if (!mounted) return;

//         showDialog(
//           context: context,
//           builder: (_) => VideoResultPopup(video: file),
//         );
//       },
//     );
//   }

//   void _exportCover() async {
//     final config = CoverFFmpegVideoEditorConfig(_controller);
//     final execute = await config.getExecuteConfig();
//     if (execute == null) {
//       _showErrorSnackBar("Error on cover exportation initialization.");
//       return;
//     }

//     await ExportService.runFFmpegCommand(
//       execute,
//       onError: (e, s) => _showErrorSnackBar("Error on cover exportation :("),
//       onCompleted: (cover) {
//         if (!mounted) return;

//         showDialog(
//           context: context,
//           builder: (_) => CoverResultPopup(cover: cover),
//         );
//       },
//     );
//   }

//   int selectedOption = 0;
//   double aspectRatio = 9 / 16;
//   updateAspectRatio(double ar) async {
//     setState(() {
//       aspectRatio = ar;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return GetBuilder<EditorController>(
//       builder: (_) {
//         if (_.filterOutput != null) {
//           _controller = VideoEditorController.file(
//             File(_.filterOutput!),
//             minDuration: const Duration(seconds: 1),
//             maxDuration: const Duration(seconds: 10),
//           );
//           _controller.initialize();
//         }
//         return WillPopScope(
//           onWillPop: () async => false,
//           child: Scaffold(
//             resizeToAvoidBottomInset: false,
//             backgroundColor: Colors.black,
//             body: _controller.initialized
//                 ? SafeArea(
//                     child: Column(
//                       children: [
//                         _topNavBar(),
//                         // Expanded(
//                         //   child: AspectRatio(
//                         //     aspectRatio: 9 / 16,
//                         //     child: VideoPlayer(_controller.video),
//                         //   ),
//                         // ),

//                         Expanded(
//                           child: DefaultTabController(
//                             length: 2,
//                             child: Column(
//                               children: [
//                                 Expanded(
//                                   child: TabBarView(
//                                     physics:
//                                         const NeverScrollableScrollPhysics(),
//                                     children: [
//                                       // Stack(
//                                       //   alignment: Alignment.center,
//                                       //   children: [

//                                       // AnimatedBuilder(
//                                       //   animation: _controller.video,
//                                       //   builder: (_, __) => AnimatedOpacity(
//                                       //     opacity:
//                                       //         _controller.isPlaying ? 0 : 1,
//                                       //     duration: kThemeAnimationDuration,
//                                       //     child: GestureDetector(
//                                       //       onTap: _controller.video.play,
//                                       //       child: Container(
//                                       //         width: 40,
//                                       //         height: 40,
//                                       //         decoration:
//                                       //             const BoxDecoration(
//                                       //           color: Colors.white,
//                                       //           shape: BoxShape.circle,
//                                       //         ),
//                                       //         child: const Icon(
//                                       //           Icons.play_arrow,
//                                       //           color: Colors.black,
//                                       //         ),
//                                       //       ),
//                                       //     ),
//                                       //   ),
//                                       //     // ),
//                                       //   ],
//                                       // ),
//                                       LindiStickerWidget(
//                                         controller: _.lindiController,
//                                         child: AspectRatio(
//                                           aspectRatio: aspectRatio,
//                                           child: CropGridViewer.preview(
//                                             controller: _controller,
//                                           ),
//                                         ),
//                                       ),
//                                       CoverViewer(controller: _controller),
//                                     ],
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             IconButton(
//                               onPressed: () {
//                                 disavleAudio();
//                               },
//                               icon: isAudioMute == true
//                                   ? const Icon(Icons.volume_off_rounded)
//                                   : const Icon(Icons.volume_up_rounded),
//                             ),
//                             IconButton(
//                               onPressed: () {
//                                 if (_controller.video.value.isPlaying) {
//                                   _controller.video.pause();
//                                 } else {
//                                   _controller.video.play();
//                                 }
//                                 setState(() {});
//                               },
//                               icon: _controller.video.value.isPlaying
//                                   ? const Icon(Icons.pause_circle)
//                                   : const Icon(Icons.play_circle_fill_rounded),
//                             ),
//                           ],
//                         ),
//                         const Divider(),
//                         vSizedBox1,
//                         SizedBox(
//                           height: 150,
//                           child: LayoutBuilder(
//                             builder: (BuildContext context,
//                                 BoxConstraints constraints) {
//                               if (selectedOption == 0) {
//                                 return Column(children: _trimSlider());
//                               }
//                               if (selectedOption == 1) {
//                                 return _coverSelection();
//                               }
//                               if (selectedOption == 2) {
//                                 return _colorAdjustment();
//                               }
//                               if (selectedOption == 3) {
//                                 return _speedAdjustment();
//                               }
//                               if (selectedOption == 4) {
//                                 return _filterWidget();
//                                 // return FilterPageScreen(
//                                 //   path: widget.file!.path,
//                                 // );
//                               }
//                               if (selectedOption == 5) {
//                                 return _textWidget();
//                               }
//                               if (selectedOption == 6) {
//                                 return _aspectRatioWidget();
//                               }
//                               return Container();
//                             },
//                           ),
//                         ),
//                         SizedBox(
//                           height: 70,
//                           child: ListView(
//                             padding: screenLeftRightPadding,
//                             scrollDirection: Axis.horizontal,
//                             children: [
//                               _optionWidget(
//                                 Icons.content_cut_rounded,
//                                 "Trim",
//                                 0,
//                               ),
//                               _optionWidget(
//                                 Icons.video_label,
//                                 "Cover",
//                                 1,
//                               ),
//                               _optionWidget(
//                                 Icons.adjust_rounded,
//                                 "Adjust",
//                                 2,
//                               ),
//                               _optionWidget(
//                                 Icons.speed_rounded,
//                                 "Speed",
//                                 3,
//                               ),
//                               _optionWidget(
//                                 Icons.filter_hdr_rounded,
//                                 "Filters",
//                                 4,
//                               ),
//                               _optionWidget(
//                                 Icons.text_fields_rounded,
//                                 "Text",
//                                 5,
//                               ),
//                               _optionWidget(
//                                 Icons.aspect_ratio_rounded,
//                                 "Aspect Ratio",
//                                 6,
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   )
//                 : const Center(child: CircularProgressIndicator()),
//           ),
//         );
//       },
//     );
//   }

//   Widget _filterWidget() {
//     return Column(
//       children: [
//         ElevatedButton(
//           onPressed: () {
//             applyFilter();
//           },
//           child: const Text("Greyscale"),
//         ),
//       ],
//     );
//   }

//   Widget _aspectRatioWidget() {
//     return Wrap(
//       children: [
//         OutlinedButton.icon(
//           onPressed: aspectRatio == 16 / 9
//               ? null
//               : () {
//                   updateAspectRatio(16 / 9);
//                 },
//           icon: const Icon(Icons.aspect_ratio_rounded),
//           label: const Text("16 : 9"),
//         ),
//         OutlinedButton.icon(
//           onPressed: aspectRatio == 9 / 16
//               ? null
//               : () {
//                   updateAspectRatio(9 / 16);
//                 },
//           icon: const Icon(Icons.aspect_ratio_rounded),
//           label: const Text("9 : 16"),
//         ),
//         OutlinedButton.icon(
//           onPressed: aspectRatio == 4 / 3
//               ? null
//               : () {
//                   updateAspectRatio(4 / 3);
//                 },
//           icon: const Icon(Icons.aspect_ratio_rounded),
//           label: const Text("4 : 3"),
//         ),
//         OutlinedButton.icon(
//           onPressed: aspectRatio == 3 / 4
//               ? null
//               : () {
//                   updateAspectRatio(3 / 4);
//                 },
//           icon: const Icon(Icons.aspect_ratio_rounded),
//           label: const Text("3 : 4"),
//         ),
//       ],
//     );
//   }

//   Widget _buildColorButton(Color color) {
//     return GetBuilder<EditorController>(builder: (_) {
//       return GestureDetector(
//         onTap: () {
//           _.changeColor(color);
//         },
//         child: Container(
//           margin: const EdgeInsets.symmetric(horizontal: 5),
//           width: 40,
//           height: 40,
//           decoration: BoxDecoration(
//             color: color,
//             border: Border.all(
//               color:
//                   _.selectedColor == color ? Colors.white : Colors.transparent,
//               width: 2,
//             ),
//             borderRadius: BorderRadius.circular(20),
//           ),
//         ),
//       );
//     });
//   }

//   final TextEditingController? textController = TextEditingController();
//   Widget _textWidget() {
//     return GetBuilder<EditorController>(builder: (_) {
//       return Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Column(
//           children: [
//             ElevatedButton(
//               onPressed: () {
//                 Get.dialog(
//                   AlertDialog(
//                     title: const Text('Text Options'),
//                     content: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         TextField(
//                           controller: textController,
//                           decoration: const InputDecoration(
//                             labelText: 'Enter Text',
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                         const Text('Select Color:'),
//                         const SizedBox(height: 5),
//                         SingleChildScrollView(
//                           scrollDirection: Axis.horizontal,
//                           child: Row(
//                             children: [
//                               _buildColorButton(Colors.black),
//                               _buildColorButton(Colors.white),
//                               _buildColorButton(Colors.red),
//                               _buildColorButton(Colors.blue),
//                               _buildColorButton(Colors.green),
//                               _buildColorButton(Colors.yellow),
//                               _buildColorButton(Colors.orange),
//                               _buildColorButton(Colors.purple),
//                               _buildColorButton(Colors.grey),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                     actions: [
//                       MaterialButton(
//                         onPressed: () {
//                           Navigator.pop(context);
//                         },
//                         child: const Text('Cancel'),
//                       ),
//                       MaterialButton(
//                         onPressed: () {
//                           Navigator.pop(context);
//                           _.lindiController.addWidget(
//                             Text(
//                               "${textController?.text.trim()}",
//                               style: TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 color: _.selectedColor,
//                               ),
//                             ),
//                           );
//                         },
//                         child: const Text('Save'),
//                       ),
//                     ],
//                   ),
//                   barrierDismissible: false,
//                 );
//               },
//               child: const Text("Add Custom Text"),
//             )
//           ],
//         ),
//       );
//     });
//   }

//   bool isAudioMute = false;
//   void disavleAudio() async {
//     if (isAudioMute) {
//       _controller.video.setVolume(1);
//     } else {
//       _controller.video.setVolume(0);
//     }
//     setState(() {
//       isAudioMute = !isAudioMute;
//     });
//   }

//   Widget _topNavBar() {
//     return SafeArea(
//       child: SizedBox(
//         height: height,
//         child: Row(
//           children: [
//             Expanded(
//               child: IconButton(
//                 onPressed: () => Navigator.of(context).pop(),
//                 icon: const Icon(Icons.arrow_back),
//                 tooltip: 'Leave editor',
//               ),
//             ),
//             const VerticalDivider(endIndent: 22, indent: 22),
//             Expanded(
//               child: IconButton(
//                 onPressed: () =>
//                     _controller.rotate90Degrees(RotateDirection.left),
//                 icon: const Icon(Icons.rotate_left),
//                 tooltip: 'Rotate unclockwise',
//               ),
//             ),
//             Expanded(
//               child: IconButton(
//                 onPressed: () =>
//                     _controller.rotate90Degrees(RotateDirection.right),
//                 icon: const Icon(Icons.rotate_right),
//                 tooltip: 'Rotate clockwise',
//               ),
//             ),
//             Expanded(
//               child: IconButton(
//                 onPressed: () => Navigator.push(
//                   context,
//                   MaterialPageRoute<void>(
//                     builder: (context) => CropScreen(controller: _controller),
//                   ),
//                 ),
//                 icon: const Icon(Icons.crop),
//                 tooltip: 'Open crop screen',
//               ),
//             ),
//             const VerticalDivider(endIndent: 22, indent: 22),
//             TextButton.icon(
//               onPressed: () {
//                 _controller.video.pause();
//                 Get.to(() => AiScreen(file: widget.file!.path));
//               },
//               icon: const Icon(Icons.local_fire_department_rounded),
//               label: const Text("Try AI"),
//             ),
//             Expanded(
//               child: PopupMenuButton(
//                 tooltip: 'Open export menu',
//                 icon: const Icon(Icons.save),
//                 itemBuilder: (context) => [
//                   PopupMenuItem(
//                     onTap: _exportCover,
//                     child: const Text('Export cover'),
//                   ),
//                   PopupMenuItem(
//                     onTap: _exportVideo,
//                     child: const Text('Export video'),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String formatter(Duration duration) => [
//         duration.inMinutes.remainder(60).toString().padLeft(2, '0'),
//         duration.inSeconds.remainder(60).toString().padLeft(2, '0')
//       ].join(":");

//   List<Widget> _trimSlider() {
//     return [
//       AnimatedBuilder(
//         animation: Listenable.merge([
//           _controller,
//           _controller.video,
//         ]),
//         builder: (_, __) {
//           final int duration = _controller.videoDuration.inSeconds;
//           final double pos = _controller.trimPosition * duration;

//           return Padding(
//             padding: EdgeInsets.symmetric(horizontal: height / 4),
//             child: Row(children: [
//               Text(formatter(Duration(seconds: pos.toInt()))),
//               const Expanded(child: SizedBox()),
//               AnimatedOpacity(
//                 opacity: _controller.isTrimming ? 1 : 0,
//                 duration: kThemeAnimationDuration,
//                 child: Row(mainAxisSize: MainAxisSize.min, children: [
//                   Text(formatter(_controller.startTrim)),
//                   const SizedBox(width: 10),
//                   Text(formatter(_controller.endTrim)),
//                 ]),
//               ),
//             ]),
//           );
//         },
//       ),
//       Container(
//         width: MediaQuery.of(context).size.width,
//         margin: EdgeInsets.symmetric(vertical: height / 4),
//         child: TrimSlider(
//           controller: _controller,
//           height: height,
//           horizontalMargin: height / 4,
//           child: TrimTimeline(
//             controller: _controller,
//             padding: const EdgeInsets.only(top: 10),
//           ),
//         ),
//       )
//     ];
//   }

//   Widget _coverSelection() {
//     return SingleChildScrollView(
//       child: Center(
//         child: Container(
//           margin: const EdgeInsets.all(15),
//           child: CoverSelection(
//             controller: _controller,
//             size: height + 10,
//             quantity: 8,
//             selectedCoverBuilder: (cover, size) {
//               return Stack(
//                 alignment: Alignment.center,
//                 children: [
//                   cover,
//                   Icon(
//                     Icons.check_circle,
//                     color: const CoverSelectionStyle().selectedBorderColor,
//                   )
//                 ],
//               );
//             },
//           ),
//         ),
//       ),
//     );
//   }

//   void applyFilter() async {
//     print("Applying filter");
//     String inputPath = _controller.file.path;
//     String outputPath = await getOutputPath();

//     List<String> command = [
//       '-y',
//       '-i',
//       inputPath,
//       '-vf',
//       'format=gray',
//       outputPath,
//     ];
//     print(command);
//     final videoDuration = await getVideoDurationInSec(_controller.file.path);

//     FFmpegKit.executeWithArgumentsAsync(command, (session) async {
//       final returnCode = await session.getReturnCode();

//       if (ReturnCode.isSuccess(returnCode)) {
//         log("video create success...");
//       } else if (ReturnCode.isCancel(returnCode)) {
//         // CANCEL
//       } else {
//         // ERROR
//         log("Command failed with state ${await session.getState()} and rc ${await session.getReturnCode()}.${await session.getFailStackTrace()}  ${await session.getAllLogsAsString()}");
//       }
//     }, (logs) {
//       final progress = getFFmpegProgress(logs.getMessage(), videoDuration);
//       if (progress != 0) {
//         ///Perform your logic here to show the progress
//         log(progress.toString());
//       }
//     });
//   }

//   Future<num> getVideoDurationInSec(String fileUrlOrPath) async {
//     num videoDuration = 60.19;
//     await FFprobeKit.getMediaInformationAsync(
//       fileUrlOrPath,
//       (session) async {
//         final information = (session).getMediaInformation();

//         try {
//           for (int x = 0; x < information!.getStreams().length; x++) {
//             final stream = information.getStreams()[x];

//             if (stream.getAllProperties() != null && videoDuration == 60.19) {
//               videoDuration =
//                   num.parse(stream.getAllProperties()!["duration"].toString());

//               ///Change the above duration paramter to desired one according to
//               /// your needs.
//               break;
//             }
//           }
//         } catch (e) {
//           log(e.toString());
//         }
//       },
//     );

//     ///Wait for result
//     await Future.delayed(const Duration(milliseconds: 800));

//     return videoDuration;
//   }

//   double getFFmpegProgress(String ffmpegLogs, num videoDurationInSec) {
//     final regex = RegExp("(?<=time=)[\\d:.]*");
//     final match = regex.firstMatch(ffmpegLogs);
//     if (match != null) {
//       final matchSplit = match.group(0).toString().split(":");
//       if (videoDurationInSec != 0) {
//         final progress = (int.parse(matchSplit[0]) * 3600 +
//                 int.parse(matchSplit[1]) * 60 +
//                 double.parse(matchSplit[2])) /
//             videoDurationInSec;
//         double showProgress = (progress * 100);
//         return showProgress;
//       }
//     }
//     return 0;
//   }

//   double speed = 0.0;
//   double brightness = 0.0;
//   double contrast = 0.0;
//   double saturation = 0.0;
//   double hue = 0.0;
//   Widget _speedAdjustment() {
//     return _buildSlider(
//       label: 'Speed',
//       value: speed,
//       onChanged: (value) {
//         setState(() {
//           speed = value;
//         });
//       },
//     );
//   }

//   Widget _colorAdjustment() {
//     return ListView(
//       children: [
//         ElevatedButton(
//             onPressed: () async {
//               final Directory extDir = await getApplicationDocumentsDirectory();
//               final String dirPath = '${extDir.path}/Oyindori/Filtered';
//               await Directory(dirPath).create(recursive: true);
//               final String filePath =
//                   '$dirPath/${DateTime.now().millisecondsSinceEpoch.toString()}';
//               await FFmpegKit.execute(
//                   '${'-i ${_controller.file.path}'} -vf hue=s=0 $filePath-output.mp4');
//               _controller =
//                   VideoEditorController.file(File('$filePath-output.mp4'))
//                     ..initialize().then((_) {
//                       setState(() {
//                         _controller.video.play();
//                         _controller.video.setLooping(true);
//                       });
//                     });
//             },
//             child: const Text("Filter")),
//         _buildSlider(
//             label: 'Brightness',
//             value: brightness,
//             onChanged: (value) {
//               setState(() {
//                 brightness = value;
//               });
//             },
//             onChangedEnd: (val) {
//               adjustBrightnessAndSave(val);
//             }),
//         _buildSlider(
//           label: 'Contrast',
//           value: contrast,
//           onChanged: (value) {
//             setState(() {
//               contrast = value;
//             });
//           },
//         ),
//         _buildSlider(
//           label: 'Saturation',
//           value: saturation,
//           onChanged: (value) {
//             setState(() {
//               saturation = value;
//             });
//           },
//         ),
//         _buildSlider(
//           label: 'Hue',
//           value: hue,
//           onChanged: (value) {
//             setState(() {
//               hue = value;
//             });
//           },
//         ),
//       ],
//     );
//   }

//   Widget _buildSlider({
//     required String label,
//     required double value,
//     required Function(double) onChanged,
//     Function(double)? onChangedEnd,
//   }) {
//     return Column(
//       children: [
//         Text(label),
//         Slider(
//           value: value,
//           onChanged: onChanged,
//           onChangeEnd: onChangedEnd,
//           min: -1.0,
//           max: 1.0,
//           divisions: 100,
//           label: value.toStringAsFixed(2),
//         ),
//       ],
//     );
//   }

//   void changeSpeed() async {
//     _controller.video.setPlaybackSpeed(speed);
//   }

//   Future<String> getOutputPath() async {
//     final directory = await getApplicationDocumentsDirectory();
//     final outputPath = '${directory.path}/processed_video.mp4';
//     return outputPath;
//   }

//   void adjustBrightnessAndSave(double brightness) async {
//     final outputPath = await getOutputPath();

//     final String command =
//         '-y -i ${_controller.file.path} -vf eq=brightness=$brightness $outputPath';
//     await FFmpegKit.execute(
//       command,
//     ).then((session) async {
//       final returnCode = await session.getReturnCode();
//       final state =
//           FFmpegKitConfig.sessionStateToString(await session.getState());
//       final output = await session.getOutput();
//       if (ReturnCode.isSuccess(returnCode)) {
//         print("Successfully adjust");
//         reRenderPlay(outputPath);
//       } else if (ReturnCode.isCancel(returnCode)) {
//         print("Cancel adjust");
//       } else {
//         print("Error adjust");
//       }
//       log(state);
//       log(output.toString());
//       log(returnCode.toString());
//       log("++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
//     });
//   }

//   Widget _optionWidget(IconData icon, String title, int index) {
//     return InkWell(
//       onTap: () {
//         setState(() {
//           selectedOption = index;
//         });
//       },
//       child: Padding(
//         padding: screenLeftRightPadding,
//         child: Column(
//           children: [
//             vSizedBox0,
//             Icon(
//               icon,
//               color: selectedOption == index ? Colors.yellow : Colors.white,
//               size: 25,
//             ),
//             CustomText.ourText(title,
//                 fontSize: 13,
//                 color: selectedOption == index ? Colors.yellow : Colors.white),
//           ],
//         ),
//       ),
//     );
//   }
// }
