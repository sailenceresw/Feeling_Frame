import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:video_editor_mobile_app/src/constant/dimension.dart';
import 'package:video_editor_mobile_app/src/constant/medias.dart';
import 'package:video_editor_mobile_app/src/widgets/custom_text.dart';

import '../login/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    // TODO: implement initState
    Future.delayed(const Duration(seconds: 2), () {
      Get.offAll(() => const LoginScreen());
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SvgPicture.asset(
                    kAppIconSvg,
                    width: appWidth(context) * 0.4,
                  ),
                  vSizedBox2,
                  CustomText.ourText(
                    "Feeling Frame",
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                  vSizedBox0,
                  CustomText.ourText(
                    "AI-powered video editing",
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
            const CircularProgressIndicator(
              strokeWidth: 2,
            ),
            vSizedBox3,
          ],
        ),
      ),
    );
  }
}
