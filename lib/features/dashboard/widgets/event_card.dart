import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/shared/widgets/retro_card.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    required this.title,
    required this.description,
    required this.date,
    super.key,
  });

  final String title;
  final String description;
  final String date;

  @override
  Widget build(BuildContext context) {
    return RetroCard(
      padding: const EdgeInsets.all(12),
      backgroundColor: AppColors.paper,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.orange,
              border: Border.all(color: AppColors.ink, width: 2),
            ),
            child: const Icon(Icons.event, color: AppColors.ink, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.ink,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              date,
              style: const TextStyle(
                color: AppColors.white,
                fontFamily: 'monospace',
                fontSize: 8,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
