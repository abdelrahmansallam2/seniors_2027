import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';

class RetroTextField extends StatelessWidget {
  const RetroTextField({
    required this.controller,
    this.hintText,
    this.keyboardType,
    this.maxLength,
    this.textAlign = TextAlign.start,
    this.autofocus = false,
    this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String? hintText;
  final TextInputType? keyboardType;
  final int? maxLength;
  final TextAlign textAlign;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      onChanged: onChanged,
      keyboardType: keyboardType,
      maxLength: maxLength,
      textAlign: textAlign,
      style: const TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
      cursorColor: AppColors.ink,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: AppColors.muted, fontSize: 12),
        counterText: '',
        isDense: true,
        filled: true,
        fillColor: AppColors.paper,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        enabledBorder: _border(),
        focusedBorder: _border(width: 2.5),
      ),
    );
  }

  OutlineInputBorder _border({double width = 2}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: AppColors.ink, width: width),
    );
  }
}
