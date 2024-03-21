import 'package:flutter/material.dart';
import 'package:video_editor_mobile_app/src/constant/dimension.dart';
import 'package:video_editor_mobile_app/src/constant/medias.dart';
import 'package:video_editor_mobile_app/src/controllers/login_controller.dart';
import 'package:video_editor_mobile_app/src/screens/login/components/login_form_widget.dart';
import 'package:video_editor_mobile_app/src/widgets/custom_text.dart';
import 'package:video_editor_mobile_app/src/widgets/custom_toast.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: appHeight(context),
        padding: screenPadding,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              kBg,
            ),
            alignment: Alignment.centerRight,
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black,
              BlendMode.difference,
            ),
          ),
        ),
        child: ListView(
          children: [
            vSizedBox3,
            Center(
              child: Image.asset(
                kMainLogo,
                width: appWidth(context) * 0.2,
              ),
            ),
            vSizedBox2,
            CustomText.ourText(
              "Login",
              fontWeight: FontWeight.bold,
              fontSize: 25,
            ),
            CustomText.ourText(
              "Please authencate yourself with credentials",
              fontSize: 15,
            ),
            vSizedBox2,
            Form(
              key: LoginController.instance.formKey,
              child: const LoginFormWidget(),
            ),
            vSizedBox3,
            SizedBox(
              width: appWidth(context),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow,
                ),
                onPressed: () {
                  if (LoginController.instance.formKey.currentState!
                      .validate()) {
                    LoginController.instance.login();
                  } else {
                    warningToast(msg: "Please validate all fields");
                  }
                },
                icon: const Icon(
                  Icons.login,
                  color: Colors.black,
                ),
                label: const Text(
                  "Login",
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
              ),
            ),
            vSizedBox4,
            Align(
              alignment: Alignment.bottomCenter,
              child: CustomText.ourText(
                "Copyright @ 2024, By logging you accept \nTerms & Conditions and Privacy Policies",
                textAlign: TextAlign.center,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
