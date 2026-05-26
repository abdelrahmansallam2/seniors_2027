import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';

class SeniorsEmptyState extends StatelessWidget {
  const SeniorsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.paper,
                border: Border.all(color: AppColors.ink, width: 3),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.ink,
                    offset: Offset(8, 8),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: const Icon(
                Icons.person_search_rounded,
                size: 64,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'No seniors found.',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            const Text(
              'Try another search or filter.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
