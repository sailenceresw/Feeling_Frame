import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
              Colors.black54,
              BlendMode.darken,
            ),
          ),
        ),
        child: ListView(
          children: [
            vSizedBox3,
            Center(
              child: SvgPicture.asset(
                kAppIconSvg,
                width: appWidth(context) * 0.28,
              ),
            ),
            vSizedBox2,
            CustomText.ourText(
              "Welcome",
              fontWeight: FontWeight.bold,
              fontSize: 26,
            ),
            vSizedBox0,
            CustomText.ourText(
              "Continue in demo mode to start editing videos",
              fontSize: 15,
              color: Colors.grey,
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
                  // Form fields are optional in demo mode; always allow continue.
                  LoginController.instance.login();
                },
                icon: const Icon(
                  Icons.play_arrow,
                  color: Colors.black,
                ),
                label: const Text(
                  "Continue (demo)",
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
                "Demo mode — no account required. By continuing you accept\nTerms & Conditions and Privacy Policies",
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
