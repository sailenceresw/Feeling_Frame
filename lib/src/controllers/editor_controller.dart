import 'dart:developer';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lindi_sticker_widget/lindi_controller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_editor_mobile_app/src/widgets/custom_dialogs.dart';

import '../screens/editor/custom_video_editor.dart';
import '../utils/storage_path.dart';

class EditorController extends GetxController {
  static final EditorController instance = Get.find();
  List<String> selectedVideoPaths = [];
  File? editingVideoFile;

  //multiple video combination
  dynamic combinationMultipleProgress = 0.0;
  bool? isCombining = false;
  void pickVideo() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.video,
      allowMultiple: true,
    );

    if (result != null) {
      CustomDialogs.fullLoadingDialog(
          data: "Combining videos $combinationMultipleProgress...");

      selectedVideoPaths
        ..clear()
        ..addAll(result.paths.map((path) => path!).toList());
      log('Picked paths: $selectedVideoPaths');
      if (selectedVideoPaths.isNotEmpty) {
        if (selectedVideoPaths.length == 1) {
          Get.back();
          editingVideoFile = File(selectedVideoPaths[0]);
          currentPlayablePath = editingVideoFile!.path;
          update();
          Get.to(() => CustomVideoEditor(file: editingVideoFile));
        } else {
          mergeVideos();
        }
      }

      log("Picked video files paths: $selectedVideoPaths");
    } else {
      log("User canceled the picker");
    }
  }

  /// Records a new video with the device camera and opens it in the editor
  /// ("capture them live inside the app" — report feature 2).
  void recordVideo() async {
    final XFile? captured = await ImagePicker().pickVideo(
      source: ImageSource.camera,
      maxDuration: const Duration(minutes: 10),
    );
    if (captured != null) {
      editingVideoFile = File(captured.path);
      currentPlayablePath = editingVideoFile!.path;
      update();
      Get.to(() => CustomVideoEditor(file: editingVideoFile));
    } else {
      log("User cancelled camera capture");
    }
  }

  Future<bool> requestPermission() async {
    // On iOS file access goes through the document/photo picker, which does
    // not require the Android-only manageExternalStorage permission.
    if (!Platform.isAndroid) {
      return true;
    }

    final request = await Permission.manageExternalStorage.request();
    log("Permission status :$request");
    if (request == PermissionStatus.granted) {
      return true;
    }
    return false;
  }

  void mergeVideos() async {
    isCombining = true;
    update();
    String basePath = await getOutputDirectoryPath();
    String outputPath = "concat.mp4";
    List<String> tempFiles = [];
    for (int i = 0; i < selectedVideoPaths.length; i++) {
      String tempFilePath = "$basePath${i}_temp.ts";
      tempFiles.add(tempFilePath);
      await FFmpegKit.execute(
        "-y -i ${selectedVideoPaths[i]} -c copy -bsf:v h264_mp4toannexb -f mpegts $tempFilePath",
      ).then((session) async {
        final returnCode = await session.getReturnCode();
        final state =
            FFmpegKitConfig.sessionStateToString(await session.getState());
        final output = await session.getOutput();
        if (ReturnCode.isSuccess(returnCode)) {
          log("Successfully converted to ts file");
        } else if (ReturnCode.isCancel(returnCode)) {
          log("Cancel converted to ts file");
        } else {
          log("Error converted to ts file");
        }
        log(state);
        log(output.toString());
        log(returnCode.toString());
      });
    }

    String concatCommand = "concat:${tempFiles.join('|')}";
    log(concatCommand);
    String command =
        '-y -i "$concatCommand" -c copy -bsf:a aac_adtstoasc ${basePath + outputPath}';
    log(command);

    FFmpegKit.execute(command).then((session) async {
      final returnCode = await session.getReturnCode();
      final state =
          FFmpegKitConfig.sessionStateToString(await session.getState());
      final output = await session.getOutput();
      if (ReturnCode.isSuccess(returnCode)) {
        log("Successfully merged");
        Get.back();
        isCombining = false;
        editingVideoFile = File(basePath + outputPath);
        currentPlayablePath = editingVideoFile!.path;
        update();
        Get.to(() => CustomVideoEditor(file: editingVideoFile));
      } else if (ReturnCode.isCancel(returnCode)) {
        log("Cancelled merged");
        Get.back();
        isCombining = false;
        update();
        log(state.toString());
        log(output.toString());
        Get.snackbar("Error", "Something messed up:$returnCode ");
      } else {
        log("Error merged : $returnCode");
        Get.back();
        isCombining = false;
        update();
        log(state.toString());
        log(output.toString());
        Get.snackbar("Error", "Something messed up:$returnCode");
      }
    });
  }

  String? filterOutput;

  void changeFilterOutput(String path) {
    filterOutput = path;
    update();
    Get.back();
  }

  Color selectedColor = Colors.black;

  void changeColor(Color color) {
    selectedColor = color;
    update();
  }

  late LindiController lindiController;

  initLindi() {
    lindiController =
        LindiController(borderColor: Colors.white, iconColor: Colors.black);
    update();
  }

  void positionLindiText() {}

  String? currentPlayablePath;

  changeVideoPlayablePath(String path) async {
    currentPlayablePath = path;
    editingVideoFile = File(path);
    update();
  }

  double brightness = 0.0;
  double contrast = 0.0;
  double saturation = 0.0;

  resetAdjustment() {
    brightness = 0.0;
    contrast = 0.0;
    saturation = 0.0;
    update();
  }

  changeBrigtness(val) {
    brightness = val;
    update();
  }

  changeContrast(val) {
    contrast = val;
    update();
  }

  changeSaturation(val) {
    saturation = val;
    update();
  }
}
