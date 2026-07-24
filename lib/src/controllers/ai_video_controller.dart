import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:googleapis/storage/v1.dart' as storage;
import 'package:googleapis/videointelligence/v1.dart' as vi;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart';
import 'package:video_editor_mobile_app/src/widgets/custom_dialogs.dart';
import 'package:video_editor_mobile_app/src/widgets/custom_toast.dart';
import 'package:video_player/video_player.dart';

import '../screens/ai/object_detect_screen.dart';
import '../screens/ai/transcribe_screen.dart';
import '../screens/editor/video_result_popup.dart';
import '../services/ai_video_service.dart';
import '../services/on_device_ai_service.dart';
import '../utils/srt_builder.dart';
import '../utils/storage_path.dart';

class AiVideoController extends GetxController {
  static final AiVideoController instance = Get.find();

  String? operationName;
  AutoRefreshingAuthClient? client;

  // The Google Cloud service account JSON must NOT be hardcoded in source.
  // Provide it at build/run time, e.g.:
  //   flutter run --dart-define=GCP_SERVICE_ACCOUNT_JSON='{ ... }'
  static const String _serviceAccountJson =
      String.fromEnvironment('GCP_SERVICE_ACCOUNT_JSON');

  Future<void> init() async {
    // Reuse the existing authenticated client if it was already created.
    if (client != null) return;

    if (_serviceAccountJson.isEmpty) {
      log('GCP_SERVICE_ACCOUNT_JSON is not configured. Pass the service '
          'account credentials with --dart-define=GCP_SERVICE_ACCOUNT_JSON=...');
      return;
    }

    final credentials = auth.ServiceAccountCredentials.fromJson(
      jsonDecode(_serviceAccountJson) as Map<String, dynamic>,
    );

    final scopes = [
      vi.CloudVideoIntelligenceApi.cloudPlatformScope,
      storage.StorageApi.devstorageReadWriteScope
    ];
    client = await clientViaServiceAccount(credentials, scopes);
  }

  void callVideoIntelligence() async {
    try {
      await init();
      var response = await client?.post(
          Uri.parse(
              "https://videointelligence.googleapis.com/v1/videos:annotate"),
          body: jsonEncode({
            "inputUri": "gs://videoeditor/logo.mp4",
            "features": ["LOGO_RECOGNITION"],
          }));

      print(response?.body);
      final decodeJson = jsonDecode("${response?.body}");
      print(decodeJson);
      print(decodeJson['name']);
      operationName = decodeJson['name'];
      update();
      await callOperation();
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> callOperation() async {
    try {
      var response = await client?.get(
        Uri.parse("https://videointelligence.googleapis.com/v1/$operationName"),
      );
      final decodeJson = jsonDecode("${response?.body}");
      log("Data $decodeJson");
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> uploadFile(File file) async {
    final url =
        'https://storage.googleapis.com/upload/storage/v1/b/videoeditor/o?uploadType=media&name=${basename(file.path)}';

    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.files.add(await http.MultipartFile.fromPath(
      'file',
      file.path,
      filename: basename(file.path),
      contentType: MediaType.parse('video/mp4'),
    ));
    print(request);
    var data = await client?.send(request);
    print(data);
    var response = await http.Response.fromStream(data!);
    print(response.body);
    if (response.statusCode == 200) {
      print('File uploaded successfully');
    } else {
      print('Error uploading file: ${response.reasonPhrase}');
    }
  }

  VideoPlayerController? videoPlayerController;
  void tryObjectDetect(String path) {
    Get.to(() => ObjectDetectScreen(
          path: path,
        ));
  }

  String? detectOperationName;

  /// On-device object detection (no cloud, no credentials). Samples frames
  /// from the video and labels them with ML Kit's bundled model.
  Future<void> detectObjectsOnDevice(
      String videoPath, double durationSeconds) async {
    try {
      CustomDialogs.fullLoadingDialog(
        data: "Detecting objects on-device...",
      );
      final labels =
          await OnDeviceAiService.detectLabels(videoPath, durationSeconds);
      if (labels.isEmpty) {
        detectedObjects = [];
        detectOperationName = null;
        errorToast(msg: "No objects detected in this video");
      } else {
        detectedObjects = labels;
        // Mark as done so the screen shows results instead of the button.
        detectOperationName = "on-device";
      }
      update();
    } catch (e) {
      log(e.toString());
      errorToast(msg: "On-device detection failed");
    } finally {
      if (Get.isDialogOpen == true) Get.back();
    }
  }

  void detectObjects(String fileName) async {
    try {
      CustomDialogs.fullLoadingDialog(
        data: "Converting video content, please wait...",
        showCancel: true,
      );
      await init();
      // final base64Data = await videoToBase64(selectedVideoPath!);
      // print(base64Data);
      var response = await client?.post(
          Uri.parse(
              "https://videointelligence.googleapis.com/v1/videos:annotate"),
          body: jsonEncode({
            "inputUri": "gs://videoeditor/$fileName",
            "features": ["OBJECT_TRACKING"],
          }));
      if (response?.statusCode == 200) {
        print(response?.body);
        final decodeJson = jsonDecode("${response?.body}");
        print(decodeJson);
        print(decodeJson['name']);
        detectOperationName = decodeJson['name'];
        update();
      } else {
        print("Error ${response?.body}");
      }
    } catch (e) {
      print(e.toString());
    } finally {
      if (Get.isDialogOpen == true) {
        Get.back();
      }
    }
  }

  List detectedObjects = [];
  final int MAX_RETRY_COUNT = 3;
  Future<void> callDetectObjectNextOperation() async {
    try {
      CustomDialogs.fullLoadingDialog(
        data: "Analyzing next step, please wait for output...",
        showCancel: true,
      );

      // Initialize variables
      bool responseReceived = false;
      int retryCount = 0;

      // Continue making requests until a valid response is received or a maximum retry count is reached
      while (!responseReceived && retryCount < MAX_RETRY_COUNT) {
        var response = await client?.get(
          Uri.parse(
              "https://videointelligence.googleapis.com/v1/$detectOperationName"),
        );

        final decodeJson = jsonDecode(response!.body);

        if (decodeJson['response'] != null) {
          log("Data $decodeJson");
          detectedObjects = decodeJson['response']['annotationResults'][0]
                  ['objectAnnotations']
              .map((e) => e['entity']['description'])
              .toList();
          responseReceived = true; // Set flag to true to exit the loop
          update();
        } else {
          retryCount++; // Increment retry count
          await Future.delayed(
            const Duration(seconds: 2),
          ); // Delay before next retry
        }
      }
    } catch (e) {
      print(e.toString());
    } finally {
      if (Get.isDialogOpen == true) {
        Get.back();
      }
    }
  }

  /// Whether the Google Cloud credentials have been provided at build time.
  bool get isConfigured => _serviceAccountJson.isNotEmpty;

  Future<bool> uploadVideoToGCS(String filePath) async {
    if (!isConfigured) {
      errorToast(
          msg: "AI features are not configured. Provide GCP credentials.");
      return false;
    }
    try {
      CustomDialogs.fullLoadingDialog(
        data: "Uploading video, please wait...",
      );
      await init();

      final url =
          'https://storage.googleapis.com/upload/storage/v1/b/videoeditor/o?uploadType=media&name=${basename(filePath)}';

      // Read the video file
      final File videoFile = File(filePath);
      final List<int> videoBytes = await videoFile.readAsBytes();

      // Create the HTTP request
      final http.Request request = http.Request('POST', Uri.parse(url))
        ..headers.addAll({
          'Content-Type': 'video/mp4',
        })
        ..bodyBytes = videoBytes;

      // Send the request
      final http.StreamedResponse? response = await client?.send(request);

      if (response?.statusCode == 200) {
        print('Video uploaded successfully');
        return true;
      } else {
        print('Failed to upload video: ${response?.reasonPhrase}');
        return false;
      }
    } catch (e) {
      print(e.toString());
      return false;
    } finally {
      if (Get.isDialogOpen == true) {
        Get.back();
      }
    }
  }

  void tryTranscribe(String path) {
    Get.to(() => TranscribeScreen(
          path: path,
        ));
  }

  String? transcribedOperationName;
  /// BCP-47 language code used for speech transcription (AI refinement:
  /// supports videos in different languages).
  String transcribeLanguageCode = 'en-US';

  /// Languages offered in the transcription language picker.
  static const Map<String, String> transcribeLanguages = {
    'en-US': 'English (US)',
    'en-GB': 'English (UK)',
    'es-ES': 'Spanish',
    'fr-FR': 'French',
    'hi-IN': 'Hindi',
    'ne-NP': 'Nepali',
    'de-DE': 'German',
    'ja-JP': 'Japanese',
  };

  void setTranscribeLanguage(String code) {
    transcribeLanguageCode = code;
    update();
  }

  void transcribeOperation(String fileName) async {
    try {
      CustomDialogs.fullLoadingDialog(
        data: "Converting video content, please wait...",
        showCancel: true,
      );
      await init();

      var response = await client?.post(
          Uri.parse(
              "https://videointelligence.googleapis.com/v1/videos:annotate"),
          body: jsonEncode({
            "inputUri": "gs://videoeditor/$fileName",
            "features": ["SPEECH_TRANSCRIPTION"],
            "videoContext": {
              "speechTranscriptionConfig": {
                "languageCode": transcribeLanguageCode,
                "enableAutomaticPunctuation": true,
                "filterProfanity": true
              }
            }
          }));
      if (response?.statusCode == 200) {
        print(response?.body);
        final decodeJson = jsonDecode("${response?.body}");
        print(decodeJson);
        print(decodeJson['name']);
        transcribedOperationName = decodeJson['name'];
        update();
      } else {
        print("Error ${response?.body}");
      }
    } catch (e) {
      print(e.toString());
    } finally {
      if (Get.isDialogOpen == true) {
        Get.back();
      }
    }
  }

  String? transcribeText;
  Future<void> callTranscribeNextOperation() async {
    try {
      CustomDialogs.fullLoadingDialog(
        data: "Analyzing next step, please wait for output...",
        showCancel: true,
      );
      var response = await client?.get(
        Uri.parse(
            "https://videointelligence.googleapis.com/v1/$transcribedOperationName"),
      );

      var decodedJson = jsonDecode(response!.body);
      if (decodedJson['response'] != null) {
        log("Data $decodedJson");
        transcribeText = decodedJson['response']['annotationResults'][0]
            ['speechTranscriptions'][0]['alternatives'][0]['transcript'];
        _collectTranscribedWords(decodedJson);
        update();
      } else {
        print("Not till yet");
      }
    } catch (e) {
      print(e.toString());
    } finally {
      if (Get.isDialogOpen == true) {
        Get.back();
      }
    }
  }

  /// Word-level transcript with timings, used to generate captions.
  /// Each entry: {'word': String, 'start': double, 'end': double} (seconds).
  List<Map<String, dynamic>> transcribedWords = [];

  // GCP encodes durations as strings like "1.400s".
  double _parseGcpDuration(dynamic value) {
    if (value is String && value.endsWith('s')) {
      return double.tryParse(value.substring(0, value.length - 1)) ?? 0;
    }
    return 0;
  }

  void _collectTranscribedWords(dynamic decodedJson) {
    transcribedWords = [];
    try {
      final transcriptions = decodedJson['response']['annotationResults'][0]
              ['speechTranscriptions'] ??
          [];
      for (final st in transcriptions) {
        final alts = st['alternatives'];
        if (alts is List && alts.isNotEmpty) {
          for (final w in (alts[0]['words'] ?? [])) {
            transcribedWords.add({
              'word': "${w['word'] ?? ''}",
              'start': _parseGcpDuration(w['startTime']),
              'end': _parseGcpDuration(w['endTime']),
            });
          }
        }
      }
    } catch (e) {
      log("Failed to collect word timings: $e");
    }
  }

  /// Groups the word timings into short caption chunks and writes an SRT file.
  Future<String?> _writeSrtFile() async {
    final content = buildSrt(transcribedWords);
    if (content.isEmpty) return null;
    final path = "${await getOutputDirectoryPath()}captions.srt";
    await File(path).writeAsString(content);
    return path;
  }

  /// Generates captions from the transcription and burns them into the video.
  Future<void> burnCaptionsIntoVideo(String videoPath) async {
    String? output;
    try {
      CustomDialogs.fullLoadingDialog(
        data: "Generating captions, please wait...",
      );
      final srtPath = await _writeSrtFile();
      if (srtPath != null) {
        output = await AiVideoService.burnCaptions(videoPath, srtPath);
      }
    } catch (e) {
      log(e.toString());
    } finally {
      // Close the loading dialog before showing any result.
      if (Get.isDialogOpen == true) Get.back();
    }

    if (output != null) {
      Get.dialog(Material(
        color: Colors.transparent,
        child: VideoResultPopup(video: File(output), aspectRatio: 16 / 9),
      ));
    } else if (transcribedWords.isEmpty) {
      errorToast(msg: "No word timings available to build captions");
    } else {
      errorToast(msg: "Couldn't burn captions into the video");
    }
  }

  /// Runs one of the local (offline) AI features with loading/result UX.
  Future<void> runLocalAiFeature({
    required String path,
    required Future<String?> Function(String input) feature,
    required String loadingMessage,
    required String failureMessage,
  }) async {
    String? output;
    try {
      CustomDialogs.fullLoadingDialog(data: loadingMessage);
      output = await feature(path);
    } catch (e) {
      log(e.toString());
    } finally {
      // Close the loading dialog before showing any result.
      if (Get.isDialogOpen == true) Get.back();
    }

    if (output != null) {
      Get.dialog(Material(
        color: Colors.transparent,
        child: VideoResultPopup(video: File(output), aspectRatio: 16 / 9),
      ));
    } else {
      errorToast(msg: failureMessage);
    }
  }
}
