import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/shared/widgets/retro_shadow_container.dart';

class RetroPhotoPlaceholder extends StatelessWidget {
  const RetroPhotoPlaceholder({
    this.label = 'PHOTO',
    this.width,
    this.height = 128,
    this.backgroundColor = AppColors.paper,
    super.key,
  });

  final String label;
  final double? width;
  final double height;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return RetroShadowContainer(
      width: width,
      height: height,
      backgroundColor: backgroundColor,
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }
}
