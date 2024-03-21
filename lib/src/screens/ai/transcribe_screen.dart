import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:video_editor_mobile_app/src/constant/dimension.dart';
import 'package:video_editor_mobile_app/src/controllers/ai_video_controller.dart';
import 'package:video_editor_mobile_app/src/widgets/custom_text.dart';
import 'package:video_player/video_player.dart';

class TranscribeScreen extends StatefulWidget {
  const TranscribeScreen({this.path, super.key});
  final String? path;
  @override
  State<TranscribeScreen> createState() => _TranscribeScreenState();
}

class _TranscribeScreenState extends State<TranscribeScreen> {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        AiVideoController.instance.videoPlayerController?.pause();
        AiVideoController.instance.transcribedOperationName = null;
        AiVideoController.instance.update();
        return true;
      },
      child: GetBuilder<AiVideoController>(
        initState: (__) {
          print(widget.path);
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
              title: const Text('Transcribe'),
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
                  if (_.transcribedOperationName == null)
                    SizedBox(
                      width: appWidth(context),
                      child: ElevatedButton(
                        onPressed: () {
                          _.transcribeOperation(basename(widget.path!));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow,
                        ),
                        child: const Text(
                          "Transcribe",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else if (_.transcribeText == null)
                    SizedBox(
                      width: appWidth(context),
                      child: ElevatedButton(
                        onPressed: () {
                          _.callTranscribeNextOperation();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow,
                        ),
                        child: const Text(
                          "Next Analysis",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else
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
                    "Transcribed Words",
                    fontWeight: FontWeight.bold,
                  ),
                  if (_.transcribeText != null)
                    SelectableText(_.transcribeText.toString()),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
