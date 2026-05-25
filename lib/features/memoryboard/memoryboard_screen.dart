import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/features/app_shell/widgets/main_page_header.dart';
import 'package:seniors_27/shared/widgets/retro_button.dart';
import 'package:seniors_27/shared/widgets/retro_card.dart';
import 'package:seniors_27/shared/widgets/retro_photo_placeholder.dart';
import 'package:seniors_27/shared/widgets/retro_section_header.dart';
import 'package:seniors_27/shared/widgets/retro_sticker.dart';

class MemoryboardScreen extends StatelessWidget {
  const MemoryboardScreen({super.key});

  static const _memoryColors = [
    AppColors.paper,
    AppColors.green,
    AppColors.cyan,
    AppColors.yellow,
    AppColors.pink,
    AppColors.paper,
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const PageStorageKey('memoryboard_scroll'),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RetroSectionHeader(
            title: 'MEMORYBOARD',
            backgroundColor: AppColors.cyan,
          ),
          const SizedBox(height: 18),
          const MainPageHeader(
            title: 'Memoryboard',
            subtitle: 'Bring your funniest shots and cozy moments.',
          ),
          const SizedBox(height: 25),
          Stack(
            clipBehavior: Clip.none,
            children: [
              RetroCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SHARE YOUR\nMEMORIES',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Add a moment from your senior year.',
                      style: TextStyle(fontFamily: 'monospace', fontSize: 10),
                    ),
                    const SizedBox(height: 15),
                    RetroButton(
                      label: 'UPLOAD PHOTO',
                      height: 42,
                      backgroundColor: AppColors.green,
                      onPressed: () {},
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Positioned(
                bottom: -15,
                right: -10,
                child: RetroSticker(
                  color: AppColors.yellow,
                  width: 60,
                  height: 22,
                  angle: 0.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const RetroSectionHeader(
            title: 'RETRO PHOTO WALL',
            backgroundColor: AppColors.yellow,
          ),
          const SizedBox(height: 15),
          RetroCard(
            backgroundColor: AppColors.paper,
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _memoryColors.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 20,
                childAspectRatio: 0.85,
              ),
              itemBuilder: (context, index) {
                final rotation = (index % 2 == 0 ? -2.0 : 2.0) * math.pi / 180;
                return Transform.rotate(
                  angle: rotation,
                  child: Column(
                    children: [
                      Expanded(
                        child: RetroPhotoPlaceholder(
                          label: 'MEMORY',
                          height: double.infinity,
                          backgroundColor: _memoryColors[index],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        color: AppColors.ink,
                        child: const Text(
                          'JAN 2027',
                          style: TextStyle(
                            color: AppColors.paper,
                            fontFamily: 'monospace',
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: RetroButton(
                  label: 'PREV.',
                  height: 42,
                  onPressed: () {},
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: RetroButton(
                  label: 'NEXT',
                  height: 42,
                  onPressed: () {},
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
