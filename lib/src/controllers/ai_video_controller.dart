import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_editor_mobile_app/src/widgets/custom_dialogs.dart';
import 'package:video_editor_mobile_app/src/widgets/custom_toast.dart';
import 'package:video_player/video_player.dart';

import '../screens/ai/object_detect_screen.dart';
import '../screens/editor/video_result_popup.dart';
import '../services/on_device_ai_service.dart';

/// Controller for the AI Mode screen. Everything here runs **on-device** — the
/// former Google Cloud paths (Video Intelligence transcription + GCS upload)
/// have been removed in favour of on-device ML Kit object detection and the
/// on-device Caption Studio, so nothing is uploaded and no credentials are
/// required.
class AiVideoController extends GetxController {
  static final AiVideoController instance = Get.find();

  VideoPlayerController? videoPlayerController;

  void tryObjectDetect(String path) {
    Get.to(() => ObjectDetectScreen(path: path));
  }

  /// Set once detection has run (`"on-device"`), so the screen can switch from
  /// the "Detect" button to the results view.
  String? detectOperationName;

  /// Distinct object labels detected in the current video.
  List detectedObjects = [];

  /// On-device object detection (no cloud, no credentials). Samples frames from
  /// the video and labels them with ML Kit's bundled model.
  Future<void> detectObjectsOnDevice(
      String videoPath, double durationSeconds) async {
    try {
      CustomDialogs.fullLoadingDialog(
        data: "Detecting objects on-device...",
      );
      final labels =
          await OnDeviceAiService.detectLabels(videoPath, durationSeconds);
      if (labels.isEmpty) {
        detectedObjects = [];
        detectOperationName = null;
        errorToast(msg: "No objects detected in this video");
      } else {
        detectedObjects = labels;
        detectOperationName = "on-device";
      }
      update();
    } catch (e) {
      log(e.toString());
      errorToast(msg: "On-device detection failed");
    } finally {
      if (Get.isDialogOpen == true) Get.back();
    }
  }

  /// Runs one of the local (offline) AI features with loading/result UX.
  Future<void> runLocalAiFeature({
    required String path,
    required Future<String?> Function(String input) feature,
    required String loadingMessage,
    required String failureMessage,
  }) async {
    String? output;
    try {
      CustomDialogs.fullLoadingDialog(data: loadingMessage);
      output = await feature(path);
    } catch (e) {
      log(e.toString());
    } finally {
      // Close the loading dialog before showing any result.
      if (Get.isDialogOpen == true) Get.back();
    }

    if (output != null) {
      Get.dialog(Material(
        color: Colors.transparent,
        child: VideoResultPopup(video: File(output), aspectRatio: 16 / 9),
      ));
    } else {
      errorToast(msg: failureMessage);
    }
  }
}
