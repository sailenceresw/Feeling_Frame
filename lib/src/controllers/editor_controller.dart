import 'dart:developer';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lindi_sticker_widget/lindi_controller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_editor_mobile_app/src/widgets/custom_dialogs.dart';

import '../screens/editor/custom_video_editor.dart';

class EditorController extends GetxController {
  static final EditorController instance = Get.find();
  List<String> selectedVideoPaths = [];
  File? editingVideoFile;

  //multiple video combination
  dynamic combinationMultipleProgress = 0.0;
  bool? isCombining = false;
  void pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: true,
    );

    if (result != null) {
      CustomDialogs.fullLoadingDialog(
          data: "Combining videos $combinationMultipleProgress...");

      selectedVideoPaths
        ..clear()
        ..addAll(result.paths.map((path) => path!).toList());
      print(selectedVideoPaths);
      // Use the filePaths list to do something with the selected video files
      // Build the FFmpeg command to concatenate the videos
      if (selectedVideoPaths.isNotEmpty) {
        if (selectedVideoPaths.length == 1) {
          Get.back();
          editingVideoFile = File(selectedVideoPaths[0]);
          update();
          Get.to(() => CustomVideoEditor(file: editingVideoFile));
        } else {
          mergeVideos();
        }
      }

      log("Picked video files paths: $selectedVideoPaths");
    } else {
      // User canceled the picker
      log("User canceled the picker");
    }
  }

  Future<bool> requestPermission() async {
    final request = await Permission.manageExternalStorage.request();
    log("Permmission status :$request");
    if (request == PermissionStatus.granted) {
      return true;
    }
    return false;
  }

  void mergeVideos() async {
    String basePath = "/storage/emulated/0/Download/";
    String outputPath = "concat.mp4";
    // String command =
    //     '-y -i "concat:${selectedVideoPaths.join('|')}" -c copy $outputFilePath';
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
          print("Successfully converted to ts file");
        } else if (ReturnCode.isCancel(returnCode)) {
          print("Cancel converted to ts file");
        } else {
          print("Error converted to ts file");
        }
        log(state);
        log(output.toString());
        log(returnCode.toString());
        log("++++++++++++++++++++++++++++++++++++++++++++++++++++++++");
      });
    }

    String concatCommand = "concat:${tempFiles.join('|')}";
    // await FFmpegKit.execute(
    //     "-i \"$concatCommand\" -c copy -bsf:a aac_adtstoasc $outputFilePath");
    print(concatCommand);
    String command =
        '-y -i "$concatCommand" -c copy -bsf:a aac_adtstoasc ${basePath + outputPath}';
    print(command);

    FFmpegKit.execute(command).then((session) async {
      final returnCode = await session.getReturnCode();
      final state =
          FFmpegKitConfig.sessionStateToString(await session.getState());
      final output = await session.getOutput();
      if (ReturnCode.isSuccess(returnCode)) {
        print("Succesfully merged");
        Get.back();
        isCombining = false;
        update();
        // Get.dialog(
        //   Dialog(
        //     child: VideoPlayer(
        //       VideoPlayerController.file(
        //         File(basePath + outputPath),
        //       )
        //         ..initialize()
        //         ..play(),
        //     ),
        //   ),
        // );
        editingVideoFile = File(basePath + outputPath);
        update();
        Get.to(() => CustomVideoEditor(file: editingVideoFile));
      } else if (ReturnCode.isCancel(returnCode)) {
        log("Cancelled merged");

        Get.back();
        log(state.toString());
        log(output.toString());
        Get.snackbar("Error", "Something messed up:$returnCode ");
      } else {
        log("Error merged : $returnCode");

        Get.back();
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

  //filter option
  // late final VideoPreviewController controller;
  // late final GPUVideoPreviewParams previewParams;
  // bool previewParamsReady = false;
  // late final GPUFilterConfiguration configuration;

  // brightness(double brightness) {
  //   GPUBrightnessConfiguration().brightness = brightness;
  //   update();
  // }

  // filterPrepare() {
  //   _prepare().whenComplete(() {
  //     update();
  //   });
  // }

  // Future<void> _prepare() async {
  //   await widget.configuration.prepare();
  //   previewParams = await GPUVideoPreviewParams.create(widget.configuration);
  //   previewParamsReady = true;
  // }

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
