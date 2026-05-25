import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';

class RetroValidationMessage extends StatelessWidget {
  const RetroValidationMessage({
    required this.message,
    this.backgroundColor = AppColors.pink,
    this.uppercase = true,
    super.key,
  });

  final String message;
  final Color backgroundColor;
  final bool uppercase;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: AppColors.ink, width: 2),
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(3, 3), blurRadius: 0),
        ],
      ),
      child: Text(
        uppercase ? message.toUpperCase() : message,
        style: const TextStyle(
          color: AppColors.ink,
          fontFamily: 'monospace',
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
