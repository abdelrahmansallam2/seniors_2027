import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/shared/widgets/retro_card.dart';

class CountdownBoardRow extends StatelessWidget {
  const CountdownBoardRow({required this.count, super.key});

  final int count;

  @override
  Widget build(BuildContext context) {
    return RetroCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      backgroundColor: AppColors.paper,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cyan,
              border: Border.all(color: AppColors.ink, width: 2),
            ),
            child: const Text(
              'COUNTDOWN BOARD',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
            ),
          ),
          Text(
            '$count scheduled',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
