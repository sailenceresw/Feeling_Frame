import 'package:flutter/material.dart';

class CustomText {
  static Text ourText(
    String? data, {
    Color? color,
    FontStyle? fontStyle,
    FontWeight? fontWeight,
    TextAlign? textAlign,
    double? fontSize = 16,
    int? maxLines = 2,
    TextDecoration? textDecoration,
    Color? decorationColor,
    bool? isFontFamily = true,
    double? letterSpacing = 0,
  }) =>
      Text(
        data ?? '',
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        textAlign: textAlign,
        style: TextStyle(
          decoration: textDecoration ?? TextDecoration.none,
          decorationColor: decorationColor ?? Colors.grey.shade400,
          fontSize: fontSize,
          letterSpacing: letterSpacing,
          fontFamily: isFontFamily == true ? "Quicksand" : null,
          fontStyle: fontStyle ?? FontStyle.normal,
          fontWeight: fontWeight ?? FontWeight.normal,
          color: color ?? Colors.white,
        ),
      );
}
