import 'package:flutter/material.dart';
import 'package:message_app/common/extension/custom_theme_extension.dart';
import 'package:message_app/common/utils/coloors.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    this.controller,
    this.hintText,
    this.readOnly,
    this.textAlign,
    this.keyboardType,
    this.prefixText,
    this.onTap,
    this.suffixIcon,
    this.onChanged,
    this.fontSize,
    this.autoFocus,
    this.enabled,
    this.focusNode,
  });

  final TextEditingController? controller;
  final String? hintText;
  final bool? readOnly;
  final TextAlign? textAlign;
  final TextInputType? keyboardType;
  final String? prefixText;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final Function(String)? onChanged;
  final double? fontSize;
  final bool? autoFocus;
  final bool? enabled;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      focusNode: focusNode,
      enabled: enabled,
      onTap: onTap,
      controller: controller,
      readOnly: readOnly ?? false,
      textAlign: textAlign ?? TextAlign.center,
      keyboardType: readOnly == null ? keyboardType : null,
      onChanged: onChanged,
      autofocus: autoFocus ?? false,
      style: TextStyle(fontSize: fontSize),
      decoration: InputDecoration(
        isDense: true,
        prefixText: prefixText,
        suffix: suffixIcon,
        hintText: hintText,
        hintStyle: TextStyle(color: context.theme.greyColor),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Coloors.blueDark),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Coloors.blueDark, width: 2),
        ),
      ),
    );
  }
}
