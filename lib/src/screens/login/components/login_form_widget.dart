import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_editor_mobile_app/src/controllers/login_controller.dart';

import '../../../constant/dimension.dart';
import '../../../widgets/custom_textfield.dart';

class LoginFormWidget extends StatelessWidget {
  const LoginFormWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Demo mode: fields are optional. User can leave them blank and still continue.
    return Column(
      children: [
        CustomTextFormField(
          hintText: "Email (optional)",
          labelText: "Email",
          prefixIcon: Icons.email,
          controller: LoginController.instance.emailController,
        ),
        vSizedBox2,
        CustomTextFormField(
          hintText: "Password (optional)",
          labelText: "Password",
          prefixIcon: Icons.lock,
          controller: LoginController.instance.passwordController,
          obscureText: true,
        ),
      ],
    );
  }
}
