import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/shared/widgets/retro_pressable.dart';

class RetroButton extends StatelessWidget {
  const RetroButton({
    required this.label,
    required this.onPressed,
    this.backgroundColor = AppColors.paper,
    this.textStyle,
    this.height = 56,
    this.shadowOffset = const Offset(5, 6),
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final TextStyle? textStyle;
  final double height;
  final Offset shadowOffset;

  static const _animationDuration = Duration(milliseconds: 110);
  static const _pressedScale = 0.985;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height + shadowOffset.dy + 3,
      child: RetroPressable(
        onTap: onPressed,
        builder: (context, isHovered, isPressed) {
          final isLifted = isHovered && !isPressed && onPressed != null;
          final offset = isPressed
              ? shadowOffset
              : isLifted
              ? const Offset(0, -2)
              : Offset.zero;
          final shadows = isPressed
              ? const <BoxShadow>[]
              : [
                  BoxShadow(
                    color: AppColors.ink,
                    offset: isLifted
                        ? Offset(shadowOffset.dx + 2, shadowOffset.dy + 3)
                        : shadowOffset,
                    blurRadius: 0,
                  ),
                ];

          return AnimatedScale(
            duration: _animationDuration,
            curve: Curves.easeOutCubic,
            scale: isPressed ? _pressedScale : 1,
            child: AnimatedContainer(
              duration: _animationDuration,
              curve: Curves.easeOutCubic,
              height: height,
              alignment: Alignment.center,
              transform: Matrix4.translationValues(offset.dx, offset.dy, 0),
              decoration: BoxDecoration(
                color: isPressed ? AppColors.yellowWarm : backgroundColor,
                border: Border.all(color: AppColors.ink, width: 3),
                borderRadius: BorderRadius.circular(9),
                boxShadow: shadows,
              ),
              child: Text(
                label.toUpperCase(),
                style: textStyle ?? Theme.of(context).textTheme.labelLarge,
              ),
            ),
          );
        },
      ),
    );
  }
}
