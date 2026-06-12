import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

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

class AiVideoController extends GetxController {
  static final AiVideoController instance = Get.find();

  Future<void> _waitForOperation(
      String operationName, vi.CloudVideoIntelligenceApi videoI) async {
    vi.GoogleLongrunningOperation? operation;
    do {
      await Future.delayed(const Duration(seconds: 5)); // Poll every 5 seconds
      operation = await videoI.operations.projects.locations.operations
          .get(operationName);
      print(operation);
    } while (operation.done != true);

    final response = await videoI.operations.projects.locations.operations
        .get(operationName);
    // Handle the response, extract labels, shot changes, etc.
    print(response);
  }

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
                "languageCode": "en",
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
}
