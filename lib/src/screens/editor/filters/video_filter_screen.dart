// import 'dart:io' show File;

// import 'package:flutter/material.dart' hide Rect;
// import 'package:flutter_gpu_filters_interface/flutter_gpu_filters_interface.dart';
// import 'package:flutter_gpu_video_filters/flutter_gpu_video_filters.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:video_editor_mobile_app/src/controllers/editor_controller.dart';

// import 'approved_filters.dart';
// import 'filters.dart';

// class FilterPageScreen extends StatelessWidget {
//   const FilterPageScreen({required this.path, super.key});
//   final String path;
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: CustomScrollView(
//           slivers: [
//             SliverFixedExtentList(
//               delegate: SliverChildBuilderDelegate(
//                 (context, index) {
//                   final item = kFailedFilters[index];
//                   return Card(
//                     child: ListTile(
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) {
//                               return FilterPage(
//                                 configuration: item.configuration,
//                                 file: path,
//                               );
//                             },
//                           ),
//                         );
//                       },
//                       title: Text(item.name),
//                       trailing: Icon(
//                         Icons.arrow_forward,
//                         color: Theme.of(context).colorScheme.error,
//                       ),
//                     ),
//                   );
//                 },
//                 childCount: kFailedFilters.length,
//               ),
//               itemExtent: 64,
//             ),
//             SliverFixedExtentList(
//               delegate: SliverChildBuilderDelegate(
//                 (context, index) {
//                   final item = kFilters[index];
//                   return Card(
//                     child: ListTile(
//                       onTap: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) {
//                               return FilterPage(
//                                 configuration: item.configuration,
//                                 file: path,
//                               );
//                             },
//                           ),
//                         );
//                       },
//                       title: Text(item.name),
//                       trailing: Icon(
//                         Icons.arrow_forward,
//                         color: Theme.of(context).primaryColor,
//                       ),
//                     ),
//                   );
//                 },
//                 childCount: kFilters.length,
//               ),
//               itemExtent: 64,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class FilterPage extends StatefulWidget {
//   final GPUFilterConfiguration configuration;

//   const FilterPage(
//       {super.key, required this.file, required this.configuration});
//   final String file;
//   @override
//   State<FilterPage> createState() => _FilterPageState();
// }

// class _FilterPageState extends State<FilterPage> {
//   late final VideoPreviewController controller;
//   late final GPUVideoPreviewParams previewParams;
//   bool previewParamsReady = false;

//   @override
//   void initState() {
//     super.initState();
//     _prepare().whenComplete(() => setState(() {}));
//   }

//   @override
//   void dispose() {
//     controller.dispose();
//     widget.configuration.dispose();
//     super.dispose();
//   }

//   Future<void> _prepare() async {
//     await widget.configuration.prepare();
//     previewParams = await GPUVideoPreviewParams.create(widget.configuration);
//     previewParamsReady = true;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Preview'),
//       ),
//       // floatingActionButton: FloatingActionButton(
//       //   heroTag: null,
//       //   onPressed: () {
//       //     _exportVideo().catchError((e) => ScaffoldMessenger.of(context)
//       //         .showSnackBar(SnackBar(content: Text(e.toString()))));
//       //   },
//       //   tooltip: 'Export video',
//       //   child: const Icon(Icons.save),
//       // ),
//       body: Stack(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Container(
//               child: previewParamsReady
//                   ? GPUVideoNativePreview(
//                       params: previewParams,
//                       configuration: widget.configuration,
//                       onViewCreated: (controller, outputSizeStream) async {
//                         this.controller = controller;
//                         await controller
//                             .setVideoSource(FileInputSource(File(widget.file)));
//                         await widget.configuration.update();
//                         await for (final _ in outputSizeStream) {
//                           setState(() {});
//                         }
//                       },
//                     )
//                   : const Center(
//                       child: CircularProgressIndicator(),
//                     ),
//             ),
//           ),
//           Row(
//             children: [
//               TextButton(
//                   onPressed: () {
//                     controller.pause();
//                   },
//                   child: const Text('Pause')),
//               TextButton(
//                   onPressed: () {
//                     controller.play();
//                   },
//                   child: const Text('Play')),
//             ],
//           )
//         ],
//       ), // This trailing comma makes auto-formatting nicer for build methods.
//     );
//   }

//   File? latestFile;
//   Future<void> _exportVideo() async {
//     final asset = widget.file;
//     final root = await getTemporaryDirectory();
//     final output = File(
//       '${root.path}/${DateTime.now().millisecondsSinceEpoch}.${asset.split('.').last}',
//     );
//     final watch = Stopwatch();
//     watch.start();
//     final processStream = widget.configuration.exportVideoFile(
//       VideoExportConfig(
//         FileInputSource(File(widget.file)),
//         output,
//       ),
//     );
//     await for (final progress in processStream) {
//       debugPrint('_exportVideo: Exporting file ${(progress * 100).toInt()}%');
//     }
//     debugPrint(
//         '_exportVideo: Exporting file took ${watch.elapsedMilliseconds} milliseconds');
//     // await GallerySaver.saveVideo(output.absolute.path);
//     EditorController.instance.changeFilterOutput(output.absolute.path);
//     latestFile = output;
//     debugPrint('_exportVideo: Exported: ${output.absolute}');
//   }
// }
