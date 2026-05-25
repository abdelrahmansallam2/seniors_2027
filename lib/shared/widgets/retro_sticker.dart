import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';

class RetroSticker extends StatelessWidget {
  const RetroSticker({
    required this.color,
    this.width = 62,
    this.height = 24,
    this.angle = 0,
    this.child,
    super.key,
  });

  final Color color;
  final double width;
  final double height;
  final double angle;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        width: width,
        height: height,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: AppColors.ink, width: 3),
          borderRadius: BorderRadius.circular(7),
        ),
        child: child,
      ),
    );
  }
}
