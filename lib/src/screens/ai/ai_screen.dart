import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_editor_mobile_app/src/constant/dimension.dart';
import 'package:video_editor_mobile_app/src/controllers/ai_video_controller.dart';
import 'package:video_editor_mobile_app/src/services/ai_video_service.dart';
import 'package:video_editor_mobile_app/src/widgets/custom_text.dart';

import '../../constant/medias.dart';
import '../editor/caption_studio_screen.dart';

class AiScreen extends StatelessWidget {
  const AiScreen({this.file, super.key});
  final String? file;

  Widget _aiCard(
    BuildContext context, {
    required String title,
    required String description,
    required VoidCallback onTap,
    String? image,
    IconData? icon,
  }) {
    return Container(
      padding: screenPadding,
      margin: const EdgeInsets.only(bottom: vBox2),
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
                title,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              vSizedBox1,
              CustomText.ourText(
                description,
                color: Colors.grey,
                fontSize: 15,
                maxLines: 3,
              ),
              vSizedBox1,
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellowAccent,
                ),
                onPressed: onTap,
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
            child: image != null
                ? Image.asset(image, width: 100)
                : Icon(icon, size: 72, color: Colors.yellowAccent),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AiVideoController.instance;
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Mode"),
      ),
      body: Padding(
        padding: screenLeftRightPadding,
        child: ListView(
          children: [
            vSizedBox1,
            CustomText.ourText(
              "On-device AI (works offline)",
              fontWeight: FontWeight.bold,
            ),
            vSizedBox1,
            _aiCard(
              context,
              title: "Noise Reduction",
              description:
                  "Clean background noise and\nrumble from your video's\naudio track automatically",
              icon: Icons.graphic_eq_rounded,
              onTap: () => controller.runLocalAiFeature(
                path: file!,
                feature: AiVideoService.reduceNoise,
                loadingMessage: "Reducing noise, please wait...",
                failureMessage: "Couldn't reduce noise on this video",
              ),
            ),
            _aiCard(
              context,
              title: "Video Stabilization",
              description:
                  "Smooth out shaky camera\nfootage with two-pass\nmotion analysis",
              icon: Icons.video_stable_rounded,
              onTap: () => controller.runLocalAiFeature(
                path: file!,
                feature: AiVideoService.stabilizeVideo,
                loadingMessage: "Stabilizing video, please wait...",
                failureMessage: "Couldn't stabilize this video",
              ),
            ),
            _aiCard(
              context,
              title: "Auto Highlights",
              description:
                  "Detect scene changes and keep\nonly the most crucial sections\nof your video",
              icon: Icons.auto_awesome_rounded,
              onTap: () => controller.runLocalAiFeature(
                path: file!,
                feature: AiVideoService.autoHighlights,
                loadingMessage: "Building highlights, please wait...",
                failureMessage:
                    "No distinct scenes were found in this video",
              ),
            ),
            _aiCard(
              context,
              title: "Object Detection",
              description:
                  "Detect objects in your video\non-device — no account or\ninternet required",
              image: kObjectDetection,
              onTap: () => controller.tryObjectDetect(file!),
            ),
            _aiCard(
              context,
              title: "Captions",
              description:
                  "Add subtitles on-device — type,\npaste a script, or auto-generate,\nthen burn them in",
              image: kVoice,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CaptionStudioScreen(video: File(file!)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
