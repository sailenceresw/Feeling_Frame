import 'package:flutter/material.dart';

class CustomTextFormField extends StatelessWidget {
  final TextEditingController? controller;
  final dynamic formKey;
  final String? hintText;
  final TextInputType textInputType;
  final String? labelText;
  final Widget? suffix;
  final bool? isEnabled;
  final bool readOnly;
  final bool obscureText;

  final Function? validator;
  final bool onlyText;
  final bool onlyNumber;
  final int? maxLine;
  final int? minLine;
  final int? maxLength;
  final String? prefixText;
  final bool? filled;
  final Color? fillColor;
  final IconData? prefixIcon;
  final Function()? onTap;
  final Function? onChanged;
  final Function? onFieldSubmitted;
  final String? initialValue;
  final bool? isSearch;
  final bool? autoFocus;
  final AutovalidateMode? autovalidateMode;
  final List<String> autoFillHint;
  final bool searchString;
  final bool fullNameString;
  final bool allowMultipleSpace;
  final bool? showBorder;
  final TextInputAction? textInputAction;
  final double borderRadius;
  final double? hintTextSize;
  final FontWeight? hintTextWeight;
  final double? enteredTextSize;
  final FontWeight? enteredTextWeight;
  final TextAlign? textAlignment;
  final bool? notFromFormType;
  final bool? allowDouble;
  final bool? onlyPhoneNumber;
  final dynamic prefixIconSize;
  final bool? isPrefixText;
  final Widget? prefix;
  final Widget? suffixInside;

  const CustomTextFormField({
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
