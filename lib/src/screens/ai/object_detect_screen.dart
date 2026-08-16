import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_editor_mobile_app/src/constant/dimension.dart';
import 'package:video_editor_mobile_app/src/controllers/ai_video_controller.dart';
import 'package:video_editor_mobile_app/src/widgets/custom_text.dart';
import 'package:video_player/video_player.dart';

class ObjectDetectScreen extends StatefulWidget {
  const ObjectDetectScreen({this.path, super.key});
  final String? path;
  @override
  State<ObjectDetectScreen> createState() => _ObjectDetectScreenState();
}

class _ObjectDetectScreenState extends State<ObjectDetectScreen> {
  @override
  void dispose() {
    // Release the video player created for this screen to avoid a leak.
    AiVideoController.instance.videoPlayerController?.dispose();
    AiVideoController.instance.videoPlayerController = null;
    super.dispose();
  }

  void _onPop() {
    AiVideoController.instance.videoPlayerController?.pause();
    AiVideoController.instance.detectOperationName = null;
    AiVideoController.instance.update();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _onPop();
        }
      },
      child: GetBuilder<AiVideoController>(
        initState: (__) {
          AiVideoController.instance.videoPlayerController =
              VideoPlayerController.file(File("${widget.path}"))
                ..initialize().then((value) {
                  setState(() {});
                })
                ..play();
        },
        builder: (_) {
          var controller = _.videoPlayerController;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Object Detection'),
            ),
            body: Padding(
              padding: screenLeftRightPadding,
              child: ListView(
                children: [
                  Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: VideoPlayer(controller!),
                      ),
                      Center(
                        child: Row(
                          children: [
                            IconButton.filledTonal(
                                onPressed: () {
                                  controller.play();
                                },
                                icon: const Icon(Icons.play_arrow)),
                            IconButton.filledTonal(
                                onPressed: () {
                                  controller.pause();
                                },
                                icon: const Icon(Icons.pause)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (_.detectOperationName == null)
                    SizedBox(
                      width: appWidth(context),
                      child: ElevatedButton(
                        onPressed: () {
                          final seconds = _.videoPlayerController
                                  ?.value.duration.inMilliseconds ??
                              0;
                          _.detectObjectsOnDevice(
                              widget.path!, seconds / 1000.0);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow,
                        ),
                        child: const Text(
                          "Detect Objects",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else if (_.detectedObjects.isNotEmpty)
                    SizedBox(
                      width: appWidth(context),
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back();
                          Get.back();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow,
                        ),
                        child: const Text(
                          "Done",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  vSizedBox2,
                  CustomText.ourText(
                    "Detected Labels",
                    fontWeight: FontWeight.bold,
                  ),
                  if (_.detectedObjects.isNotEmpty)
                    Wrap(
                      runSpacing: 5,
                      spacing: 5,
                      children: List.generate(
                        _.detectedObjects.length,
                        (index) => RawChip(
                          label: Text('${_.detectedObjects[index]}'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
