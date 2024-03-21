import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:video_editor_mobile_app/src/constant/dimension.dart';
import 'package:video_editor_mobile_app/src/constant/medias.dart';
import 'package:video_editor_mobile_app/src/controllers/editor_controller.dart';
import 'package:video_editor_mobile_app/src/widgets/custom_text.dart';

import '../../widgets/custom_toast.dart';

class ProjectScreen extends StatelessWidget {
  const ProjectScreen({super.key});

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
                child: ListView.separated(
                  separatorBuilder: (__, ___) => const Divider(),
                  itemCount: 5,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    return ListTile(
                      dense: true,
                      trailing: IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.delete_outline_outlined,
                          color: Colors.red,
                        ),
                      ),
                      leading: Container(
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
                          ),
                        ),
                      ),
                      title: CustomText.ourText("Project Title $index"),
                      isThreeLine: true,
                      subtitle: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "20 March 2023 at 11:00 PM",
                            style: TextStyle(
                              fontSize: 10,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(child: Text("30 MB")),
                              Expanded(child: Text("00:10s")),
                            ],
                          ),
                        ],
                      ),
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
