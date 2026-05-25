import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/shared/widgets/retro_pressable.dart';
import 'package:seniors_27/shared/widgets/retro_shadow_container.dart';

class RetroBottomNav extends StatelessWidget {
  const RetroBottomNav({
    required this.currentIndex,
    required this.onTap,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const labels = ['DASH', 'SENIORS', 'MEMORY', 'BOARD', 'PROFILE'];

  @override
  Widget build(BuildContext context) {
    return RetroShadowContainer(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = index == currentIndex;
          return Expanded(
            child: RetroPressable(
              onTap: () => onTap(index),
              builder: (context, isHovered, isPressed) {
                final isLifted = isHovered && !isPressed;
                final offset = isPressed
                    ? const Offset(1, 2)
                    : isLifted
                    ? const Offset(0, -2)
                    : Offset.zero;
                return AnimatedContainer(
                  duration: Duration(milliseconds: isPressed ? 100 : 150),
                  curve: Curves.easeOutCubic,
                  transform: Matrix4.translationValues(offset.dx, offset.dy, 0),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.yellow : Colors.transparent,
                    boxShadow: isLifted
                        ? const [
                            BoxShadow(
                              color: AppColors.ink,
                              offset: Offset(2, 3),
                              blurRadius: 0,
                            ),
                          ]
                        : const [],
                  ),
                  child: Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}
