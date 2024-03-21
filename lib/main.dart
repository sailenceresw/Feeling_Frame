import 'dart:developer';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/route_manager.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_editor_mobile_app/di_init.dart';
import 'package:video_editor_mobile_app/src/screens/splash/splash_screen.dart';

import 'src/constant/color.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  diInit();
  runApp(const VideoEditorApp());
}

class VideoEditorApp extends StatefulWidget {
  const VideoEditorApp({super.key});

  @override
  State<VideoEditorApp> createState() => _VideoEditorAppState();
}

class _VideoEditorAppState extends State<VideoEditorApp> {
  // This widget is the root of your application.
  @override
  void initState() {
    // TODO: implement initState
    FFmpegKitConfig.init().then((value) {
      // FFmpegKitConfig.setLogLevel(0);
      FFmpegKitConfig.enableLogs();
      prepareAssets();
      registerApplicationFonts();
    });

    super.initState();
  }

  static Future<File> assetToFile(String assetName) async {
    final ByteData assetByteData =
        await rootBundle.load('assets/fonts/$assetName');

    final List<int> byteList = assetByteData.buffer
        .asUint8List(assetByteData.offsetInBytes, assetByteData.lengthInBytes);

    final String fullTemporaryPath =
        join((await getTemporaryDirectory()).path, assetName);

    Future<File> fileFuture = File(fullTemporaryPath)
        .writeAsBytes(byteList, mode: FileMode.writeOnly, flush: true);

    log('assets/fonts/$assetName saved to file at $fullTemporaryPath.');

    return fileFuture;
  }

  void registerApplicationFonts() {
    var fontNameMapping = <String, String>{};
    fontNameMapping["MyFontName"] = "Quicksand";
    getTemporaryDirectory().then((tempDirectory) {
      FFmpegKitConfig.setFontDirectoryList(
          [tempDirectory.path, "/system/fonts", "/System/Library/Fonts"],
          fontNameMapping);
    });
  }

  void prepareAssets() async {
    await assetToFile('Quicksand-Regular.ttf');
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Video Editor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Quicksand',
        primaryColor: AppColor.kPrimaryMain,
        brightness: Brightness.dark,
      ),
      home: const SplashScreen(),
    );
  }
}
