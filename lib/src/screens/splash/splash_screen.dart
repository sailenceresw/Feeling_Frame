import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_editor_mobile_app/src/constant/dimension.dart';
import 'package:video_editor_mobile_app/src/constant/medias.dart';

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
      // backgroundColor: AppColor.kPrimaryMain,
      body: Center(
        child: Column(
          children: [
            Expanded(
              child: Image.asset(
                kMainLogo,
                width: appWidth(context) * 0.6,
              ),
            ),
            vSizedBox1,
            const CircularProgressIndicator(
              strokeWidth: 1.9,
            ),
            vSizedBox1,
          ],
        ),
      ),
    );
  }
}
