import 'package:flutter/material.dart';
import 'package:video_editor_mobile_app/src/constant/dimension.dart';
import 'package:video_editor_mobile_app/src/controllers/ai_video_controller.dart';
import 'package:video_editor_mobile_app/src/widgets/custom_text.dart';
import 'package:video_editor_mobile_app/src/widgets/custom_toast.dart';

import '../../constant/medias.dart';

class AiScreen extends StatelessWidget {
  const AiScreen({this.file, super.key});
  final String? file;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Mode"),
      ),
      body: Padding(
        padding: screenLeftRightPadding,
        child: Column(
          children: [
            Container(
              padding: screenPadding,
              width: appWidth(context),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.yellow, width: 1),
                color: const Color.fromARGB(255, 28, 44, 67),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText.ourText(
                        "Object Detection",
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      vSizedBox1,
                      CustomText.ourText(
                        "Detect any objects in the video\nto help with your\nvideo knowledge/study",
                        color: Colors.grey,
                        fontSize: 15,
                        maxLines: 3,
                      ),
                      vSizedBox1,
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellowAccent,
                        ),
                        onPressed: () {
                          AiVideoController.instance
                              .uploadVideoToGCS(file!)
                              .then((value) {
                            if (value) {
                              AiVideoController.instance.tryObjectDetect(file!);
                            } else {
                              errorToast(msg: "Something went wrong");
                            }
                          });
                        },
                        icon: const Icon(
                          Icons.arrow_forward,
                          color: Colors.black,
                        ),
                        label: const Text(
                          "Try it now",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Image.asset(
                      kObjectDetection,
                      width: 100,
                    ),
                  ),
                ],
              ),
            ),
            vSizedBox2,
            Container(
              padding: screenPadding,
              width: appWidth(context),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.yellow, width: 1),
                color: const Color.fromARGB(255, 28, 44, 67),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText.ourText(
                        "Transcribe Video",
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      vSizedBox1,
                      CustomText.ourText(
                        "Transcribe any video with your\nprior language instantly\n on your screen",
                        color: Colors.grey,
                        fontSize: 15,
                        maxLines: 3,
                      ),
                      vSizedBox1,
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellowAccent,
                        ),
                        onPressed: () {
                          AiVideoController.instance
                              .uploadVideoToGCS(file!)
                              .then((value) {
                            if (value) {
                              AiVideoController.instance.tryTranscribe(file!);
                            } else {
                              errorToast(msg: "Something went wrong");
                            }
                          });
                        },
                        icon: const Icon(
                          Icons.arrow_forward,
                          color: Colors.black,
                        ),
                        label: const Text(
                          "Try it now",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Image.asset(
                      kVoice,
                      width: 100,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
