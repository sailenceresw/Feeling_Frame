import 'dart:io';

import 'package:flutter/cupertino.dart';
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
import 'package:video_editor_mobile_app/src/widgets/custom_text.dart';

import '../../widgets/custom_toast.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.video_camera_front_outlined),
        title: const Text("Projects"),
        actions: [
          IconButton(
            onPressed: () {
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow,
                            ),
                            onPressed: () {
                              Get.back();
                            },
                            child: const Text(
                              "Done",
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            icon: const Icon(CupertinoIcons.info_circle),
          ),
          IconButton(
            tooltip: "How to use",
            onPressed: () {
              Get.to(() => const HelpScreen());
            },
            icon: const Icon(Icons.help_outline_rounded),
          ),
          IconButton(
            tooltip: "Logout",
            onPressed: () {
              Get.dialog(
                AlertDialog(
                  title: const Text("Logout"),
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
                      child: const Text("Logout"),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.logout),
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
                onTap: () async {
                  if (await EditorController.instance.requestPermission()) {
                    EditorController.instance.pickVideo();
                  } else {
                    Get.back();
                    warningToast(msg: "Give storage permision");
                    final status = await Permission.storage.request();
                    if (status == PermissionStatus.granted) {
                      EditorController.instance.pickVideo();
                    }
                  }
                },
                child: Container(
                  width: appWidth(context),
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.yellow,
                      width: 0.5,
                    ),
                    gradient: const LinearGradient(
                      colors: [Colors.orange, Colors.orangeAccent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.add_box_outlined,
                          color: Colors.white,
                        ),
                        hSizedBox1,
                        CustomText.ourText(
                          "New Project",
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              vSizedBox2,
              CustomText.ourText(
                "Recent Projects",
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
                            "No projects yet.\nCreate a new project to get started.",
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
