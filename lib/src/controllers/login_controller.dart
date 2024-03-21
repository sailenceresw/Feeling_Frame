import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_editor_mobile_app/src/screens/project/project_screen.dart';
import 'package:video_editor_mobile_app/src/widgets/custom_dialogs.dart';
import 'package:video_editor_mobile_app/src/widgets/custom_toast.dart';

class LoginController extends GetxController {
  static final LoginController instance = Get.find();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  void login() async {
    CustomDialogs.fullLoadingDialog(data: "Logging, please wait...");

    await Future.delayed(const Duration(seconds: 2));

    if (emailController.text.trim() == "test@gmail.com" &&
        passwordController.text.trim() == "123456") {
      CustomDialogs.cancelDialog();
      Get.offAll(() => const ProjectScreen());
      successToast(msg: "Successfully logged in");
    } else {
      CustomDialogs.cancelDialog();
      errorToast(msg: "Credentials not matched");
    }
  }
}
