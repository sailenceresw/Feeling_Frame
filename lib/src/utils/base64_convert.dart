import 'dart:convert';
import 'dart:io';

Future<String> videoToBase64(String filePath) async {
  // Read the video file as bytes
  File file = File(filePath);
  List<int> videoBytes = await file.readAsBytes();

  // Encode video bytes to Base64
  String base64Video = base64Encode(videoBytes);

  return base64Video;
}
