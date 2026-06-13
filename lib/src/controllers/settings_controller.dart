import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

/// App-wide user settings: accessibility (high contrast, text scale),
/// language, and premium status. Persisted locally as JSON so they survive
/// restarts on both Android and iOS.
class SettingsController extends GetxController {
  static SettingsController get instance => Get.find();

  bool highContrast = false;
  double textScale = 1.0;
  String localeCode = 'en';
  bool isPremium = false;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  Future<File> _storageFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/settings.json');
  }

  Future<void> loadSettings() async {
    try {
      final file = await _storageFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final data = jsonDecode(content) as Map<String, dynamic>;
          highContrast = data['highContrast'] as bool? ?? false;
          textScale = (data['textScale'] as num?)?.toDouble() ?? 1.0;
          localeCode = data['localeCode'] as String? ?? 'en';
          isPremium = data['isPremium'] as bool? ?? false;
        }
      }
    } catch (e) {
      log("Failed to load settings: $e");
    } finally {
      update();
      // Apply persisted locale on startup.
      Get.updateLocale(Locale(localeCode));
    }
  }

  Future<void> _persist() async {
    try {
      final file = await _storageFile();
      await file.writeAsString(jsonEncode({
        'highContrast': highContrast,
        'textScale': textScale,
        'localeCode': localeCode,
        'isPremium': isPremium,
      }));
    } catch (e) {
      log("Failed to persist settings: $e");
    }
  }

  void setHighContrast(bool value) {
    highContrast = value;
    update();
    _persist();
  }

  void setTextScale(double value) {
    textScale = value;
    update();
    _persist();
  }

  void setLocale(String code) {
    localeCode = code;
    Get.updateLocale(Locale(code));
    update();
    _persist();
  }

  void setPremium(bool value) {
    isPremium = value;
    update();
    _persist();
  }
}
