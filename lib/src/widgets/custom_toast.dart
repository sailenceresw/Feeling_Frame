import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../constant/color.dart';

class CustomToasts {
  static void showToast({
    String? msg,
    Color? color = Colors.green,
  }) {
    Fluttertoast.cancel();
    Fluttertoast.showToast(
      msg: msg.toString(),
      toastLength: Toast.LENGTH_SHORT,
      gravity: Platform.isIOS ? ToastGravity.TOP : ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: color,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }
}

errorToast({String? msg = "Please validate all data"}) {
  CustomToasts.showToast(msg: msg, color: AppColor.kPrimaryMain);
}

successToast({String? msg, Color? color}) {
  CustomToasts.showToast(msg: msg, color: AppColor.kPrimaryMain);
}

warningToast({String? msg}) {
  CustomToasts.showToast(msg: msg, color: AppColor.kPrimaryMain);
}
