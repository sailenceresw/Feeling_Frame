import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_editor_mobile_app/src/constant/dimension.dart';
import 'package:video_editor_mobile_app/src/constant/medias.dart';
import 'package:video_editor_mobile_app/src/controllers/editor_controller.dart';
import 'package:video_editor_mobile_app/src/controllers/login_controller.dart';
import 'package:video_editor_mobile_app/src/controllers/project_controller.dart';
import 'package:video_editor_mobile_app/src/models/project_model.dart';
import 'package:video_editor_mobile_app/src/screens/editor/video_result_popup.dart';
import 'package:video_editor_mobile_app/src/screens/help/help_screen.dart';
import 'package:video_editor_mobile_app/src/screens/settings/settings_screen.dart';
import 'package:video_editor_mobile_app/src/widgets/custom_text.dart';

import '../../widgets/custom_toast.dart';
import '../../widgets/feedback_dialog.dart';

class ProjectScreen extends StatelessWidget {
  const ProjectScreen({super.key});

  void _openProject(BuildContext context, ProjectModel project) {
    if (!File(project.path).existsSync()) {
      errorToast(msg: "File no longer exists, removing from list");
      ProjectController.instance.deleteProject(project);
      return;
    }
    showDialog(
      context: context,
      builder: (_) => VideoResultPopup(
        video: File(project.path),
        aspectRatio: 9 / 16,
      ),
    );
  }

  void _renameProject(ProjectModel project) {
    final controller = TextEditingController(text: project.title);
    Get.dialog(
      AlertDialog(
        title: const Text("Rename project"),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: "Project name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              ProjectController.instance
                  .renameProject(project, controller.text);
              Get.back();
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  /// Lets the user start a project from existing videos or capture a new
  /// one live with the camera.
  void _showNewProjectSourceSheet(BuildContext context) {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          padding: screenPadding,
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 28, 44, 67),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText.ourText(
                'new_project'.tr,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              vSizedBox1,
              ListTile(
                leading: const Icon(Icons.video_library_rounded,
                    color: Colors.yellow),
                title: CustomText.ourText('pick_from_device'.tr),
                subtitle: CustomText.ourText(
                  "Select one or more videos (multiple are merged)",
                  fontSize: 12,
                  color: Colors.grey,
                ),
                onTap: () async {
                  Get.back();
                  if (await EditorController.instance.requestPermission()) {
                    EditorController.instance.pickVideo();
                  } else {
                    warningToast(msg: "Give storage permision");
                    final status = await Permission.storage.request();
                    if (status == PermissionStatus.granted) {
                      EditorController.instance.pickVideo();
                    }
                  }
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.videocam_rounded, color: Colors.yellow),
                title: CustomText.ourText('record_with_camera'.tr),
                subtitle: CustomText.ourText(
                  "Capture a new video live inside the app",
                  fontSize: 12,
                  color: Colors.grey,
                ),
                onTap: () {
                  Get.back();
                  EditorController.instance.recordVideo();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ProjectModel project) {
    Get.dialog(
      AlertDialog(
        title: const Text("Delete Project"),
        content: const Text(
            "Remove this project? You can also delete the video file."),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              ProjectController.instance.deleteProject(project);
            },
            child: const Text("Remove"),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              ProjectController.instance
                  .deleteProject(project, deleteFile: true);
            },
            child: const Text(
              "Delete file",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    Get.dialog(
      Dialog(
        insetPadding: screenPadding,
        child: Padding(
          padding: screenPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText.ourText(
                "Information",
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
              vSizedBox1,
              const Text(
                """Empower your creativity with our user-friendly video editor app! Edit, enhance, and personalize your videos effortlessly. From trimming to adding effects, music, and more, bring your vision to life in just a few taps. Download now and make every moment unforgettable!""",
              ),
              vSizedBox2,
              SizedBox(
                width: appWidth(context),
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  child: const Text("Done"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    Get.dialog(
      AlertDialog(
        title: Text('logout'.tr),
        content: const Text("Are you sure you want to logout?"),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              LoginController.instance.logout();
            },
            child: Text('logout'.tr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.video_camera_front_outlined),
        title: Text('projects'.tr),
        actions: [
          IconButton(
            tooltip: 'settings'.tr,
            onPressed: () => Get.to(() => const SettingsScreen()),
            icon: const Icon(Icons.settings_outlined),
          ),
          PopupMenuButton<String>(
            tooltip: "More",
            onSelected: (value) {
              switch (value) {
                case 'how':
                  Get.to(() => const HelpScreen());
                  break;
                case 'feedback':
                  FeedbackDialog.show();
                  break;
                case 'info':
                  _showInfoDialog(context);
                  break;
                case 'logout':
                  _showLogoutDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'how', child: Text('how_to_use'.tr)),
              PopupMenuItem(value: 'feedback', child: Text('send_feedback'.tr)),
              const PopupMenuItem(value: 'info', child: Text('Information')),
              PopupMenuItem(value: 'logout', child: Text('logout'.tr)),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: screenLeftRightPadding,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              vSizedBox2,
              // ElevatedButton(
              //     onPressed: () async {
              //       // AiVideoController.instance.analyzeVideo();
              //       // AiVideoController.instance.callVideoIntelligence();
              //       // AiVideoController.instance.callOperation();
              //       final result = await FilePicker.platform.pickFiles();
              //       if (result != null) {
              //         AiVideoController.instance
              //             .uploadVideoToGCS(result.files.first.path!);
              //       }
              //     },
              //     child: const Text("Try ai")),
              InkWell(
                onTap: () => _showNewProjectSourceSheet(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: appWidth(context),
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB300), Color(0xFFFF7043)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_circle_outline_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                        vSizedBox1,
                        CustomText.ourText(
                          'new_project'.tr,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: Colors.white,
                        ),
                        vSizedBox0,
                        CustomText.ourText(
                          "Pick videos or record with the camera",
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              vSizedBox2,
              CustomText.ourText(
                'recent_projects'.tr,
                fontWeight: FontWeight.bold,
              ),
              vSizedBox2,
              Container(
                constraints: const BoxConstraints(
                  minHeight: 100,
                ),
                child: GetBuilder<ProjectController>(
                  builder: (controller) {
                    if (controller.isLoading) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (controller.projects.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CustomText.ourText(
                            'no_projects'.tr,
                            textAlign: TextAlign.center,
                            color: Colors.grey,
                            maxLines: 2,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      separatorBuilder: (__, ___) => const Divider(),
                      itemCount: controller.projects.length,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (BuildContext context, int index) {
                        final project = controller.projects[index];
                        return ListTile(
                          dense: true,
                          onTap: () => _openProject(context, project),
                          onLongPress: () => _renameProject(project),
                          trailing: IconButton(
                            onPressed: () =>
                                _confirmDelete(context, project),
                            icon: const Icon(
                              Icons.delete_outline_outlined,
                              color: Colors.red,
                            ),
                          ),
                          leading: Container(
                            width: 56,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                kBg,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          title: CustomText.ourText(project.title),
                          isThreeLine: true,
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('dd MMM yyyy, hh:mm a')
                                    .format(project.createdAt),
                                style: const TextStyle(
                                  fontSize: 10,
                                ),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                      child: Text(project.formattedSize)),
                                  Expanded(
                                      child: Text(project.formattedDuration)),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
