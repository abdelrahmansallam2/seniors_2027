import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';

class RetroShadowContainer extends StatelessWidget {
  const RetroShadowContainer({
    required this.child,
    this.backgroundColor = AppColors.paper,
    this.borderWidth = 3,
    this.borderRadius = 8,
    this.shadowOffset = const Offset(6, 7),
    this.padding,
    this.width,
    this.height,
    super.key,
  });

  final Widget child;
  final Color backgroundColor;
  final double borderWidth;
  final double borderRadius;
  final Offset shadowOffset;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: AppColors.ink, width: borderWidth),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(color: AppColors.ink, offset: shadowOffset, blurRadius: 0),
        ],
      ),
      child: child,
    );
  }
}
