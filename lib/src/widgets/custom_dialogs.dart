import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../constant/dimension.dart';

class CustomDialogs {
  static void cancelDialog() {
    Get.back();
  }

  static fullLoadingDialog({
    String? data,
    Color? color,
    bool? showCancel = false,
  }) {
    Get.dialog(
      Material(
        color: Colors.black.withOpacity(0.2),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(
                    color ?? Colors.white,
                  ),
                ),
              ),
              vSizedBox0,
              Text(
                data.toString(),
                style: TextStyle(
                  color: color ?? Colors.white,
                  fontSize: 11,
                ),
              ),
              if (showCancel == true)
                ElevatedButton(
                  onPressed: () {
                    Get.back();
                  },
                  child: const Text("Cancel"),
                )
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }
}
