import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';

import '../models/project_model.dart';

/// Persists the list of edited/exported projects to a JSON file in the app's
/// documents directory so they survive app restarts on both Android and iOS.
class ProjectController extends GetxController {
  static ProjectController get instance => Get.find();

  List<ProjectModel> projects = [];
  bool isLoading = true;

  @override
  void onInit() {
    super.onInit();
    loadProjects();
  }

  Future<File> _storageFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/projects.json');
  }

  Future<void> loadProjects() async {
    try {
      final file = await _storageFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        if (content.trim().isNotEmpty) {
          final List<dynamic> data = jsonDecode(content) as List<dynamic>;
          projects = data
              .map((e) => ProjectModel.fromJson(e as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      log("Failed to load projects: $e");
      projects = [];
    } finally {
      isLoading = false;
      update();
    }
  }

  Future<void> _persist() async {
    try {
      final file = await _storageFile();
      final data = projects.map((e) => e.toJson()).toList();
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      log("Failed to persist projects: $e");
    }
  }

  Future<void> addProject({
    required String path,
    String? title,
    int durationSeconds = 0,
  }) async {
    final file = File(path);
    if (!await file.exists()) return;

    // Avoid duplicate entries for the same output file.
    projects.removeWhere((p) => p.path == path);

    projects.insert(
      0,
      ProjectModel(
        path: path,
        title: title ?? _defaultTitle(),
        createdAt: DateTime.now(),
        sizeBytes: await file.length(),
        durationSeconds: durationSeconds,
      ),
    );
    await _persist();
    update();
  }

  String _defaultTitle() => 'Project ${projects.length + 1}';

  Future<void> deleteProject(
    ProjectModel project, {
    bool deleteFile = false,
  }) async {
    projects.removeWhere((p) => p.path == project.path);
    if (deleteFile) {
      try {
        final file = File(project.path);
        if (await file.exists()) await file.delete();
      } catch (e) {
        log("Failed to delete project file: $e");
      }
    }
    await _persist();
    update();
  }
}
