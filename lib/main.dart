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
    FFmpegKitConfig.init().then((value) async {
      // FFmpegKitConfig.setLogLevel(0);
      FFmpegKitConfig.enableLogs();
      await prepareAssets();
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

  Future<void> prepareAssets() async {
    await assetToFile('Quicksand-Regular.ttf');
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Video Editor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Quicksand',
        brightness: Brightness.dark,
        primaryColor: AppColor.kPrimaryMain,
        scaffoldBackgroundColor: AppColor.kPrimaryMain,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.yellow,
          brightness: Brightness.dark,
        ).copyWith(
          primary: Colors.yellow,
          secondary: Colors.orangeAccent,
          surface: const Color(0xFF101A2E),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColor.kPrimaryMain,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Quicksand',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.yellow,
            foregroundColor: Colors.black,
            disabledBackgroundColor: Colors.yellow.withOpacity(0.35),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            textStyle: const TextStyle(
              fontFamily: 'Quicksand',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.yellow,
            side: const BorderSide(color: Colors.yellow, width: 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.yellow),
        ),
        dialogTheme: DialogTheme(
          backgroundColor: const Color(0xFF1C2C43),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titleTextStyle: const TextStyle(
            fontFamily: 'Quicksand',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: Colors.transparent,
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: Colors.yellow,
          thumbColor: Colors.yellow,
          inactiveTrackColor: Colors.white24,
          valueIndicatorColor: Colors.yellow,
          valueIndicatorTextStyle: const TextStyle(
            color: Colors.black,
            fontFamily: 'Quicksand',
            fontWeight: FontWeight.bold,
          ),
        ),
        progressIndicatorTheme:
            const ProgressIndicatorThemeData(color: Colors.yellow),
        chipTheme: ChipThemeData(
          // Let Material 3 derive selected/unselected colors from the seed so
          // label contrast stays correct in both states.
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        listTileTheme: const ListTileThemeData(iconColor: Colors.yellow),
        dividerTheme: DividerThemeData(color: Colors.white.withOpacity(0.12)),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: Color(0xFF1C2C43),
          contentTextStyle: TextStyle(
            fontFamily: 'Quicksand',
            color: Colors.white,
          ),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
