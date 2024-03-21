import 'package:flutter/material.dart';

class CustomTextFormField extends StatelessWidget {
  TextEditingController? controller;
  dynamic formKey;
  String? hintText;
  TextInputType textInputType;
  String? labelText;
  Widget? suffix;
  bool? isEnabled;
  bool readOnly;
  bool obscureText;

  final Function? validator;
  bool onlyText;
  bool onlyNumber;
  int? maxLine;
  int? minLine;
  int? maxLength;
  String? prefixText;
  bool? filled;
  Color? fillColor;
  IconData? prefixIcon;
  Function()? onTap;
  Function? onChanged;
  Function? onFieldSubmitted;
  String? initialValue;
  bool? isSearch;
  bool? autoFocus;
  AutovalidateMode? autovalidateMode;
  List<String> autoFillHint;
  bool searchString;
  bool fullNameString;
  bool allowMultipleSpace;
  bool? showBorder;
  TextInputAction? textInputAction;
  double borderRadius;
  double? hintTextSize;
  FontWeight? hintTextWeight;
  double? enteredTextSize;
  FontWeight? enteredTextWeight;
  TextAlign? textAlignment;
  bool? notFromFormType = false;
  bool? allowDouble;
  bool? onlyPhoneNumber;
  dynamic prefixIconSize;
  bool? isPrefixText;
  Widget? prefix;
  Widget? suffixInside;

  CustomTextFormField({
    Key? key,
    this.formKey,
    this.suffixInside,
    this.prefix,
    this.controller,
    this.onlyPhoneNumber = false,
    this.hintText,
    this.textInputType = TextInputType.text,
    this.labelText,
    this.suffix,
    this.isEnabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.validator,
    this.onlyText = false,
    this.onlyNumber = false,
    this.maxLine = 1,
    this.minLine = 1,
    this.isPrefixText,
    this.maxLength,
    this.prefixText,
    this.filled = false,
    this.fillColor = const Color(0xffF4F4F4),
    this.prefixIcon,
    this.onTap,
    this.onChanged,
    this.onFieldSubmitted,
    this.initialValue,
    this.isSearch = false,
    this.autoFocus = false,
    this.autovalidateMode,
    this.autoFillHint = const [],
    this.searchString = false,
    this.fullNameString = false,
    this.allowMultipleSpace = true,
    this.textInputAction,
    this.showBorder,
    this.borderRadius = 12,
    this.hintTextSize,
    this.hintTextWeight,
    this.enteredTextSize,
    this.enteredTextWeight,
    this.textAlignment,
    this.notFromFormType,
    this.allowDouble,
    this.prefixIconSize = 22.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      autofocus: autoFocus ?? false,
      textAlign: textAlignment ?? TextAlign.left,
      minLines: minLine,
      maxLines: maxLine,
      maxLength: maxLength,
      textInputAction: textInputAction ?? TextInputAction.done,
      autofillHints: autoFillHint,
      // autofocus: autoFocus ?? false,

      validator: (value) {
        return validator == null ? null : validator!(value);
      },
      style: TextStyle(
        color: readOnly ? Colors.grey : null,
        fontSize: enteredTextSize ?? 16,
        fontFamily: "Quicksand",
        fontWeight: enteredTextWeight ?? FontWeight.w400,
      ),

      readOnly: readOnly,
      initialValue: initialValue,
      enabled: isEnabled,
      onTap: onTap,
      onChanged: (val) => isSearch == true ? onChanged!(val) : null,
      onFieldSubmitted: (val) =>
          isSearch == true ? onFieldSubmitted!(val) : null,
      autovalidateMode: autovalidateMode ?? AutovalidateMode.onUserInteraction,
      controller: controller,
      keyboardType: textInputType,
      obscureText: obscureText,
      decoration: InputDecoration(
        prefixText: isPrefixText == true ? prefixText : null,
        prefixStyle: const TextStyle(
          fontFamily: "Quicksand",
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        filled: filled,
        // contentPadding: notFromFormType == true
        //     ? EdgeInsets.zero
        //     : const EdgeInsets.all(8.0),
        labelStyle: const TextStyle(
          fontFamily: "Quicksand",
          color: Colors.grey,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        errorStyle: const TextStyle(
          fontSize: 10.0,
          fontFamily: "Quicksand",
        ),
        hintStyle: TextStyle(
          fontFamily: "Quicksand",
          // fontSize: 16.0,
          color: Colors.grey,
          fontSize: hintTextSize ?? 15,
          fontWeight: hintTextWeight ?? FontWeight.w400,
        ),
        prefixIcon: prefixIcon != null
            ? Transform.translate(
                offset: const Offset(0, 3),
                child: Icon(
                  prefixIcon,
                  color: Colors.grey,
                  size: prefixIconSize,
                ),
              )
            : null,
        fillColor: filled == true ? fillColor : null,
        hintText: hintText,
        labelText: labelText,
        suffixIcon: suffix,
        suffix: suffixInside,
        suffixIconColor: Colors.grey,
        enabledBorder: filled == true || showBorder == false
            ? InputBorder.none
            : OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: const BorderSide(
                  color: Colors.grey,
                ),
              ),
        border: filled == true
            ? InputBorder.none
            : OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: const BorderSide(
                  color: Colors.grey,
                ),
              ),
        focusedBorder: filled == true || showBorder == false
            ? InputBorder.none
            : OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                borderSide: const BorderSide(
                  color: Colors.grey,
                ),
              ),
      ),
    );
  }
}
