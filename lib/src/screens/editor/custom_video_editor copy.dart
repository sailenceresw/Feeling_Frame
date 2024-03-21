// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:video_editor/video_editor.dart';
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

//   late final VideoEditorController _controller = VideoEditorController.file(
//     File(widget.file!.path),
//     minDuration: const Duration(seconds: 1),
//     maxDuration: const Duration(seconds: 10),
//   );

//   @override
//   void initState() {
//     super.initState();
//     _controller
//         .initialize(aspectRatio: 9 / 16)
//         .then((_) => setState(() {}))
//         .catchError((error) {
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
//       // commandBuilder: (config, videoPath, outputPath) {
//       //   final List<String> filters = config.getExportFilters();
//       //   filters.add('hflip'); // add horizontal flip

//       //   return '-i $videoPath ${config.filtersCmd(filters)} -preset ultrafast $outputPath';
//       // },
//     );

//     await ExportService.runFFmpegCommand(
//       await config.getExecuteConfig(),
//       onProgress: (stats) {
//         _exportingProgress.value =
//             config.getFFmpegProgress(stats.getTime() as int);
//       },
//       onError: (e, s) => _showErrorSnackBar("Error on export video :("),
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

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: () async => false,
//       child: Scaffold(
//         backgroundColor: Colors.black,
//         body: _controller.initialized
//             ? SafeArea(
//                 child: Stack(
//                   children: [
//                     Column(
//                       children: [
//                         _topNavBar(),
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
//                                       Stack(
//                                         alignment: Alignment.center,
//                                         children: [
//                                           CropGridViewer.preview(
//                                               controller: _controller),
//                                           AnimatedBuilder(
//                                             animation: _controller.video,
//                                             builder: (_, __) => AnimatedOpacity(
//                                               opacity:
//                                                   _controller.isPlaying ? 0 : 1,
//                                               duration: kThemeAnimationDuration,
//                                               child: GestureDetector(
//                                                 onTap: _controller.video.play,
//                                                 child: Container(
//                                                   width: 40,
//                                                   height: 40,
//                                                   decoration:
//                                                       const BoxDecoration(
//                                                     color: Colors.white,
//                                                     shape: BoxShape.circle,
//                                                   ),
//                                                   child: const Icon(
//                                                     Icons.play_arrow,
//                                                     color: Colors.black,
//                                                   ),
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                       CoverViewer(controller: _controller)
//                                     ],
//                                   ),
//                                 ),
//                                 Container(
//                                   height: 200,
//                                   margin: const EdgeInsets.only(top: 10),
//                                   child: Column(
//                                     children: [
//                                       const TabBar(
//                                         isScrollable: true,
//                                         tabs: [
//                                           Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.center,
//                                             children: [
//                                               Padding(
//                                                   padding: EdgeInsets.all(5),
//                                                   child:
//                                                       Icon(Icons.content_cut)),
//                                               Text('Trim')
//                                             ],
//                                           ),
//                                           Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.center,
//                                             children: [
//                                               Padding(
//                                                   padding: EdgeInsets.all(5),
//                                                   child:
//                                                       Icon(Icons.video_label)),
//                                               Text('Cover')
//                                             ],
//                                           ),
//                                           Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.center,
//                                             children: [
//                                               Padding(
//                                                   padding: EdgeInsets.all(5),
//                                                   child: Icon(
//                                                       Icons.adjust_outlined)),
//                                               Text('Adjust')
//                                             ],
//                                           ),
//                                           Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.center,
//                                             children: [
//                                               Padding(
//                                                 padding: EdgeInsets.all(5),
//                                                 child:
//                                                     Icon(Icons.speed_rounded),
//                                               ),
//                                               Text('Speed')
//                                             ],
//                                           ),
//                                           Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.center,
//                                             children: [
//                                               Padding(
//                                                   padding: EdgeInsets.all(5),
//                                                   child: Icon(Icons
//                                                       .filter_hdr_outlined)),
//                                               Text('Filters')
//                                             ],
//                                           ),
//                                           Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.center,
//                                             children: [
//                                               Padding(
//                                                   padding: EdgeInsets.all(5),
//                                                   child: Icon(Icons
//                                                       .text_fields_rounded)),
//                                               Text('Text')
//                                             ],
//                                           ),
//                                           Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.center,
//                                             children: [
//                                               Padding(
//                                                   padding: EdgeInsets.all(5),
//                                                   child: Icon(Icons
//                                                       .emoji_emotions_rounded)),
//                                               Text('Emoji')
//                                             ],
//                                           ),
//                                         ],
//                                       ),
//                                       Expanded(
//                                         child: TabBarView(
//                                           physics:
//                                               const NeverScrollableScrollPhysics(),
//                                           children: [
//                                             Column(
//                                               mainAxisAlignment:
//                                                   MainAxisAlignment.center,
//                                               children: _trimSlider(),
//                                             ),
//                                             _coverSelection(),
//                                             Container(),
//                                             _coverSelection(),
//                                             _coverSelection(),
//                                             _coverSelection(),
//                                             _coverSelection(),
//                                           ],
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                                 ValueListenableBuilder(
//                                   valueListenable: _isExporting,
//                                   builder: (_, bool export, Widget? child) =>
//                                       AnimatedSize(
//                                     duration: kThemeAnimationDuration,
//                                     child: export ? child : null,
//                                   ),
//                                   child: AlertDialog(
//                                     title: ValueListenableBuilder(
//                                       valueListenable: _exportingProgress,
//                                       builder: (_, double value, __) => Text(
//                                         "Exporting video ${(value * 100).ceil()}%",
//                                         style: const TextStyle(fontSize: 12),
//                                       ),
//                                     ),
//                                   ),
//                                 )
//                               ],
//                             ),
//                           ),
//                         )
//                       ],
//                     )
//                   ],
//                 ),
//               )
//             : const Center(child: CircularProgressIndicator()),
//       ),
//     );
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
//                 icon: const Icon(Icons.exit_to_app),
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

//   RangeValues brightnessValue = const RangeValues(0, 20);
//   double contrastValue = 1.0;
//   double saturationValue = 1.0;
//   double hueValue = 0.0;
//   Widget _colorAdjustment() {
//     return SingleChildScrollView(
//       child: Column(
//         children: [
//           RangeSlider(
//             values: brightnessValue,
//             onChanged: (val) {
//               setState(() {
//                 brightnessValue = val;
//               });
//             },
//           )
//         ],
//       ),
//     );
//   }
// }

// class optionWidet extends StatelessWidget {
//   const optionWidet({
//     super.key,
//     this.icon,
//     this.title,
//   });
//   final IconData? icon;
//   final String? title;
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         Icon(
//           icon,
//           color: Colors.white,
//           size: 18,
//         ),
//         CustomText.ourText(
//           "$title",
//           fontSize: 10,
//         ),
//       ],
//     );
//   }
// }
