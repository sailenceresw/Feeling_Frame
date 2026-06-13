import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_editor_mobile_app/src/constant/color.dart';
import 'package:video_editor_mobile_app/src/constant/dimension.dart';
import 'package:video_editor_mobile_app/src/constant/medias.dart';

import '../splash/splash_screen.dart';

/// Branded publisher-style intro animation (like a game showing its studio
/// before launch). Shows the "feeling frame" company logo with a gentle
/// scale-in and a heartbeat pulse — echoing the "edit with emotion" tagline —
/// then cross-fades from white into the dark app and hands off to the splash.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleIn;
  late final Animation<double> _exit;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    );

    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.28, curve: Curves.easeIn),
    );
    _scaleIn = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );
    // Drives the closing cross-fade from white to the dark app background.
    _exit = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.84, 1.0, curve: Curves.easeIn),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Get.off(() => const SplashScreen());
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;

        // Two subtle heartbeats while the logo is held on screen.
        double pulse = 1.0;
        if (t > 0.45 && t < 0.84) {
          final p = (t - 0.45) / (0.84 - 0.45);
          pulse = 1.0 + 0.03 * sin(p * pi * 4).abs();
        }

        final exit = _exit.value;
        final opacity = (_fadeIn.value * (1.0 - exit)).clamp(0.0, 1.0);
        final background =
            Color.lerp(Colors.white, AppColor.kPrimaryMain, exit)!;

        return Scaffold(
          backgroundColor: background,
          body: Center(
            child: Opacity(
              opacity: opacity,
              child: Transform.scale(
                scale: _scaleIn.value * pulse,
                child: Image.asset(
                  kCompanyLogo,
                  width: appWidth(context) * 0.72,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
