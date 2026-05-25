import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';

class LoginProgress extends StatelessWidget {
  const LoginProgress({required this.step, super.key});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STEP $step / 5',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 9,
          decoration: BoxDecoration(
            color: AppColors.paper,
            border: Border.all(color: AppColors.ink, width: 1.5),
            borderRadius: BorderRadius.circular(5),
            boxShadow: const [
              BoxShadow(
                color: AppColors.ink,
                offset: Offset(4, 4),
                blurRadius: 0,
              ),
            ],
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: step / 5,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.yellowWarm,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: List.generate(5, (index) {
            return Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.only(right: 9),
              decoration: BoxDecoration(
                color: index < step ? AppColors.yellowWarm : AppColors.paper,
                border: Border.all(color: AppColors.ink, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.ink,
                    offset: Offset(2, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }
}
