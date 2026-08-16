import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_editor_mobile_app/src/screens/login/login_screen.dart';
import 'package:video_editor_mobile_app/src/screens/project/project_screen.dart';
import 'package:video_editor_mobile_app/src/widgets/custom_dialogs.dart';
import 'package:video_editor_mobile_app/src/widgets/custom_toast.dart';

class LoginController extends GetxController {
  static final LoginController instance = Get.find();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final formKey = GlobalKey<FormState>();

  /// Demo / offline entry. No real authentication is performed.
  /// Always proceeds to ProjectScreen after a short delay so the UX stays the same.
  void login() async {
    CustomDialogs.fullLoadingDialog(data: "Entering demo mode...");

    await Future.delayed(const Duration(seconds: 1));

    CustomDialogs.cancelDialog();
    Get.offAll(() => const ProjectScreen());
    successToast(msg: "Demo mode — no account required");
  }

  void logout() {
    emailController.clear();
    passwordController.clear();
    Get.offAll(() => const LoginScreen());
    successToast(msg: "Returned to start screen");
  }
}
