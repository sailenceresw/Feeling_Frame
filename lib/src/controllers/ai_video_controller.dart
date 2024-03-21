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
import 'package:video_player/video_player.dart';

import '../screens/ai/object_detect_screen.dart';
import '../screens/ai/transcribe_screen.dart';

class AiVideoController extends GetxController {
  static final AiVideoController instance = Get.find();
  // Future<void> analyzeVideo() async {
  //   // Load the service account key JSON file.
  //   var credentials = auth.ServiceAccountCredentials.fromJson({
  //     "type": "service_account",
  //     "project_id": "video-editor-417510",
  //     "private_key_id": "20d1f38cb1480df5974118dddfdec6568a429fe3",
  //     "private_key":
  //         "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCvyuKXMT4NaKN8\n0RXd4O5jsYTUyRTom6LbI6an/V7KITDtuX5oLxWdM5l3vKB4DzrpM4MAXz5lT0Wf\nov+MrBZSCkJWmm/DENzKTi5ok4u/1XmgoaWFarJ6iL+DbZGkgi/WREkKXwT2bDhE\ndGmBiZ1O9ubrNfw4mEDpTZy51k2wXeEq67Iky8eAeACcr4pnFJBeaeqHASdqWmjp\njVabRPKVGNFR8p76JZvTfhdPV0h6JYDhCvJAESoNHCIxILEMtl/bOCpzmZSp6om1\nSvcQl0359yyey+2N27wrTyroGNykuOqKk0fmu4OoQVoBYs7AAGks16EJyiiw3xMg\nPM+gja59AgMBAAECggEABX44eYVD9meV7oJjxYgiOJAgxk32PJTIa9TbNrqcPBT5\nttrOkDxHRVYcbkJlpmh5I37pkb2MukuxaEG9fsyEqOPmmw3i7G7HvkaWRhVr6lo4\nVE2h7AQNW/aPX7nVeoLtMlBjpQl2NTx3CH/+u2w12E/4MdLKK9aOGvwwlWMnEFC4\nMRy2gDV882FYYmn4Kx14HhNlOUGCYC2vgKnwSTrqZd/0PBi4Y6oU1GkGpsx9Qjb6\nPMk4/sAeDJHH7AeFe8KXQ8k+ys2s2DVCyTTu6L4jzIMCzL2qCZpicz4V9WipxQqb\nnvB986NpI+SqW7DiqZnauGi1cO+UewP9Fb0Pe5F34QKBgQDsKHT8ndWpju2IwpOk\nXi7LDu4JXOW8aq5B9I5zjH9H6liqN8RtU8PwrpRWuHgg4/u4F+PgKzJfyAjo3/5M\n9iRFGPL5Ys99pmxKV1cMoAs6IrmfzRDi7uyePgspTQ+7tDAnMaxyaBjvolRpAjWw\nnr0uuwLMs5aAfWniAf3TB22ceQKBgQC+kAVtmnbR/YpazwKpzkKa9CVDwCs3EeFf\n0/lSRslbNJvsF4HfBk+/lYvPOCs99uP0fzcHFYjqlD6ly20+KFALEVraX/f59Gzj\n0eyvvnB435824Ufmg3NnuoQ8UNPn/YqgeQzwhBcUDDNFov8bI+4qEkDR6qx9CMVq\nw2+R0NBZJQKBgQDIG/wNdvzu4aLbqO0McZY7EFqZ6nLtNoSUdNMkjF/qI2SgUAMN\nFNbKolQmK8f3LthEhVHdyRy1Vr5d/jfxJP1U47A3rAfgE95dHCcyFoeM6pHaHBz7\n/rLX4AD7LUZwql3HSGs0woqmvCnElU/Daq8p4uOba23TUPIgxck8QWYbGQKBgCVZ\newbhaHp99BkaS85WU+2k/ozJ5G51vbOXi11Z7GtI42qhrN22kfjd6boiqy8I7eLk\n8DcePGilx6WdOnsdUZrpuuHkP2kpRBJe+cH0VH0Mb1tFSl9e0ka5YuOjf/UPV5Ve\nRG/7o75VKdNzQAbkwvBSBYxfL5GOH4tuZLays7NVAoGBAM7VArzFIppQW6aFNoT7\nhn841GDh8EVzbtxMBhKd2zyl16K3xkq7OhI8psai1bOySOamof8YHjXeYGzr2H4a\nuTFDJfs6ObIF41BgdKWb4XdO3XW85deiX95O+s2YuAwT5MLcx7YBGrBiHVA1SLQ+\nNOOUPamHsI6HlI+WB+2ePcrY\n-----END PRIVATE KEY-----\n",
  //     "client_email":
  //         "video-editor-service@video-editor-417510.iam.gserviceaccount.com",
  //     "client_id": "117364698981048412120",
  //     "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  //     "token_uri": "https://oauth2.googleapis.com/token",
  //     "auth_provider_x509_cert_url":
  //         "https://www.googleapis.com/oauth2/v1/certs",
  //     "client_x509_cert_url":
  //         "https://www.googleapis.com/robot/v1/metadata/x509/video-editor-service%40video-editor-417510.iam.gserviceaccount.com",
  //     "universe_domain": "googleapis.com"
  //   });

  //   final scopes = [vi.CloudVideoIntelligenceApi.cloudPlatformScope];
  //   final client = await clientViaServiceAccount(credentials, scopes);

  //   final videoIntelligence = vi.CloudVideoIntelligenceApi(client);

  //   final features = [
  //     'LABEL_DETECTION',
  //     'SHOT_CHANGE_DETECTION'
  //   ]; // Add other features as needed

  //   final request =
  //       vi.GoogleCloudVideointelligenceV1AnnotateVideoRequest.fromJson({
  //     'inputUri': "gs://videoeditor/video.mp4",
  //     'features': features,
  //   });
  //   print(request);
  //   try {
  //     final response = await videoIntelligence.videos.annotate(request);
  //     // await _waitForOperation(response.name.toString(), videoIntelligence);
  //     // Handle the response, extract labels, shot changes, etc.
  //     print(response.done);
  //   } catch (e) {
  //     print('Error analyzing video: $e');
  //   }
  // }

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

  final apiKey = 'AIzaSyB0_VO2Dhr43qv85_iGiU_X6uf5P84IeNM';
  String? operationName;
  AutoRefreshingAuthClient? client;
  Future<void> init() async {
    var credentials = auth.ServiceAccountCredentials.fromJson({
      "type": "service_account",
      "project_id": "video-editor-417510",
      "private_key_id": "20d1f38cb1480df5974118dddfdec6568a429fe3",
      "private_key":
          "-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCvyuKXMT4NaKN8\n0RXd4O5jsYTUyRTom6LbI6an/V7KITDtuX5oLxWdM5l3vKB4DzrpM4MAXz5lT0Wf\nov+MrBZSCkJWmm/DENzKTi5ok4u/1XmgoaWFarJ6iL+DbZGkgi/WREkKXwT2bDhE\ndGmBiZ1O9ubrNfw4mEDpTZy51k2wXeEq67Iky8eAeACcr4pnFJBeaeqHASdqWmjp\njVabRPKVGNFR8p76JZvTfhdPV0h6JYDhCvJAESoNHCIxILEMtl/bOCpzmZSp6om1\nSvcQl0359yyey+2N27wrTyroGNykuOqKk0fmu4OoQVoBYs7AAGks16EJyiiw3xMg\nPM+gja59AgMBAAECggEABX44eYVD9meV7oJjxYgiOJAgxk32PJTIa9TbNrqcPBT5\nttrOkDxHRVYcbkJlpmh5I37pkb2MukuxaEG9fsyEqOPmmw3i7G7HvkaWRhVr6lo4\nVE2h7AQNW/aPX7nVeoLtMlBjpQl2NTx3CH/+u2w12E/4MdLKK9aOGvwwlWMnEFC4\nMRy2gDV882FYYmn4Kx14HhNlOUGCYC2vgKnwSTrqZd/0PBi4Y6oU1GkGpsx9Qjb6\nPMk4/sAeDJHH7AeFe8KXQ8k+ys2s2DVCyTTu6L4jzIMCzL2qCZpicz4V9WipxQqb\nnvB986NpI+SqW7DiqZnauGi1cO+UewP9Fb0Pe5F34QKBgQDsKHT8ndWpju2IwpOk\nXi7LDu4JXOW8aq5B9I5zjH9H6liqN8RtU8PwrpRWuHgg4/u4F+PgKzJfyAjo3/5M\n9iRFGPL5Ys99pmxKV1cMoAs6IrmfzRDi7uyePgspTQ+7tDAnMaxyaBjvolRpAjWw\nnr0uuwLMs5aAfWniAf3TB22ceQKBgQC+kAVtmnbR/YpazwKpzkKa9CVDwCs3EeFf\n0/lSRslbNJvsF4HfBk+/lYvPOCs99uP0fzcHFYjqlD6ly20+KFALEVraX/f59Gzj\n0eyvvnB435824Ufmg3NnuoQ8UNPn/YqgeQzwhBcUDDNFov8bI+4qEkDR6qx9CMVq\nw2+R0NBZJQKBgQDIG/wNdvzu4aLbqO0McZY7EFqZ6nLtNoSUdNMkjF/qI2SgUAMN\nFNbKolQmK8f3LthEhVHdyRy1Vr5d/jfxJP1U47A3rAfgE95dHCcyFoeM6pHaHBz7\n/rLX4AD7LUZwql3HSGs0woqmvCnElU/Daq8p4uOba23TUPIgxck8QWYbGQKBgCVZ\newbhaHp99BkaS85WU+2k/ozJ5G51vbOXi11Z7GtI42qhrN22kfjd6boiqy8I7eLk\n8DcePGilx6WdOnsdUZrpuuHkP2kpRBJe+cH0VH0Mb1tFSl9e0ka5YuOjf/UPV5Ve\nRG/7o75VKdNzQAbkwvBSBYxfL5GOH4tuZLays7NVAoGBAM7VArzFIppQW6aFNoT7\nhn841GDh8EVzbtxMBhKd2zyl16K3xkq7OhI8psai1bOySOamof8YHjXeYGzr2H4a\nuTFDJfs6ObIF41BgdKWb4XdO3XW85deiX95O+s2YuAwT5MLcx7YBGrBiHVA1SLQ+\nNOOUPamHsI6HlI+WB+2ePcrY\n-----END PRIVATE KEY-----\n",
      "client_email":
          "video-editor-service@video-editor-417510.iam.gserviceaccount.com",
      "client_id": "117364698981048412120",
      "auth_uri": "https://accounts.google.com/o/oauth2/auth",
      "token_uri": "https://oauth2.googleapis.com/token",
      "auth_provider_x509_cert_url":
          "https://www.googleapis.com/oauth2/v1/certs",
      "client_x509_cert_url":
          "https://www.googleapis.com/robot/v1/metadata/x509/video-editor-service%40video-editor-417510.iam.gserviceaccount.com",
      "universe_domain": "googleapis.com"
    });

    final scopes = [
      vi.CloudVideoIntelligenceApi.cloudPlatformScope,
      storage.StorageApi.devstorageReadWriteScope
    ];
    client = await clientViaServiceAccount(credentials, scopes);
  }

  void callVideoIntelligence() async {
    try {
      init();
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

  Future<bool> uploadVideoToGCS(String filePath) async {
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
