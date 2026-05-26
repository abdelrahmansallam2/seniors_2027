import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/features/seniors_directory/models/senior_student.dart';
import 'package:seniors_27/shared/widgets/retro_button.dart';
import 'package:seniors_27/shared/widgets/retro_card.dart';
import 'package:seniors_27/shared/widgets/retro_grid_background.dart';
import 'package:seniors_27/shared/widgets/retro_photo_placeholder.dart';
import 'package:seniors_27/shared/widgets/retro_sticker.dart';

class SeniorDetailsScreen extends StatelessWidget {
  const SeniorDetailsScreen({required this.senior, super.key});

  final SeniorStudent senior;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RetroGridBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back Button
                SizedBox(
                  width: 100,
                  child: RetroButton(
                    label: '← BACK',
                    height: 36,
                    onPressed: () => Navigator.pop(context),
                    textStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Main Profile Card
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    RetroCard(
                      padding: const EdgeInsets.all(20),
                      backgroundColor: AppColors.paper,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Photo Placeholder
                          AspectRatio(
                            aspectRatio: 1,
                            child: RetroPhotoPlaceholder(
                              label: senior.department,
                              backgroundColor: _getDepartmentColor(
                                senior.department,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Name
                          Text(
                            senior.name.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              height: 1.1,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Role & Dept
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.ink,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  senior.department,
                                  style: const TextStyle(
                                    color: AppColors.paper,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                senior.role,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Tags
                          const Text(
                            'KEYWORDS',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: senior.tags
                                .map((tag) => _DetailTag(tag: tag))
                                .toList(),
                          ),
                          const SizedBox(height: 24),

                          // Stats Row
                          Row(
                            children: [
                              Expanded(
                                child: _StatBox(
                                  label: 'POINTS',
                                  value: senior.points.toString(),
                                  color: AppColors.yellow,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _StatBox(
                                  label: 'MEMORIES',
                                  value: senior.memoriesCount.toString(),
                                  color: AppColors.pink,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Positioned(
                      top: -10,
                      right: -10,
                      child: RetroSticker(
                        color: AppColors.yellowWarm,
                        width: 64,
                        height: 24,
                        angle: 0.08,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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

class _DetailTag extends StatelessWidget {
  const _DetailTag({required this.tag});
  final String tag;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.ink, width: 1.5),
      ),
      child: Text(
        '#$tag',
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        border: Border.all(color: AppColors.ink, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w900,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
