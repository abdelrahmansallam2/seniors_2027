import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/shared/widgets/retro_card.dart';

class AnnouncementCard extends StatelessWidget {
  const AnnouncementCard({
    required this.title,
    required this.content,
    required this.date,
    this.isSpotlight = false,
    super.key,
  });

  final String title;
  final String content;
  final String date;
  final bool isSpotlight;

  @override
  Widget build(BuildContext context) {
    return RetroCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isSpotlight)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.yellow,
                    border: Border.all(color: AppColors.ink, width: 2),
                  ),
                  child: const Text(
                    'SPOTLIGHT',
                    style: TextStyle(fontSize: 8, fontWeight: FontWeight.w900),
                  ),
                ),
              Text(
                date,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 8,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
