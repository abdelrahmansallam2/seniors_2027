import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/core/navigation/retro_page_route.dart';
import 'package:seniors_27/features/seniors_directory/senior_details_screen.dart';
import 'package:seniors_27/features/seniors_directory/models/senior_student.dart';
import 'package:seniors_27/shared/widgets/retro_button.dart';
import 'package:seniors_27/shared/widgets/retro_card.dart';
import 'package:seniors_27/shared/widgets/retro_photo_placeholder.dart';

class SeniorCard extends StatelessWidget {
  const SeniorCard({required this.senior, super.key});

  final SeniorStudent senior;

  @override
  Widget build(BuildContext context) {
    return RetroCard(
      padding: const EdgeInsets.all(8),
      backgroundColor: AppColors.paper,
      borderRadius: 0,
      shadowOffset: const Offset(4, 4),
      child: Column(
        children: [
          Expanded(
            child: RetroPhotoPlaceholder(
              label: 'PHOTO',
              backgroundColor: _getDepartmentColor(senior.department),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            senior.name.split(' ').first, // Show first name for compactness
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          RetroButton(
            label: 'VISIT',
            height: 24,
            shadowOffset: const Offset(2, 2),
            onPressed: () {
              Navigator.push(
                context,
                RetroPageRoute(
                  builder: (_) => SeniorDetailsScreen(senior: senior),
                ),
              );
            },
            textStyle: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDepartmentColor(String dept) {
    switch (dept.toUpperCase()) {
      case 'DEV':
        return AppColors.cyan;
      case 'DESIGN':
        return AppColors.green;
      case 'AI':
        return AppColors.orange;
      case 'DATA':
        return AppColors.magenta;
      case 'MEDIA':
        return AppColors.pink;
      default:
        return AppColors.yellowWarm;
    }
  }
}
