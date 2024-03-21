import 'package:get/get.dart';
import 'package:video_editor_mobile_app/src/controllers/editor_controller.dart';
import 'package:video_editor_mobile_app/src/controllers/login_controller.dart';

import 'src/controllers/ai_video_controller.dart';

void diInit() {
  Get.put(LoginController());
  Get.put(EditorController());
  Get.put(AiVideoController());
}
