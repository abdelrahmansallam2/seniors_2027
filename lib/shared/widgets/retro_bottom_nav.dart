import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: AppColors.ink, width: 3.5),
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(0, 6), blurRadius: 0),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(labels.length, (index) {
          final selected = index == currentIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: selected ? AppColors.purple : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? AppColors.white : AppColors.ink,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
