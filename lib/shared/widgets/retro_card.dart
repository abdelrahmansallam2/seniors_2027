import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/shared/widgets/retro_shadow_container.dart';

class RetroCard extends StatelessWidget {
  const RetroCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.backgroundColor = AppColors.paper,
    this.shadowOffset = const Offset(6, 7),
    this.borderRadius = 10,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Offset shadowOffset;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return RetroShadowContainer(
      backgroundColor: backgroundColor,
      shadowOffset: shadowOffset,
      borderRadius: borderRadius,
      padding: padding,
      child: child,
    );
  }
}
