import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_editor_mobile_app/src/controllers/login_controller.dart';

import '../../../constant/dimension.dart';
import '../../../widgets/custom_textfield.dart';

class LoginFormWidget extends StatelessWidget {
  const LoginFormWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CustomTextFormField(
          hintText: "Enter email",
          labelText: "Email",
          prefixIcon: Icons.email,
          controller: LoginController.instance.emailController,
          validator: (val) {
            if (val.toString().isEmpty) {
              return "Email can't be empty";
            }
            if (!val.toString().isEmail) {
              return "Enter valid email";
            }
            return null;
          },
        ),
        vSizedBox2,
        CustomTextFormField(
          hintText: "Enter password",
          labelText: "Password",
          prefixIcon: Icons.lock,
          controller: LoginController.instance.passwordController,
          validator: (val) {
            if (val.toString().isEmpty) {
              return "Password can't be empty";
            }

            return null;
          },
        ),
      ],
    );
  }
}
