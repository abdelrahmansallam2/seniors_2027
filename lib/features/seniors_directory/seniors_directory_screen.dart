import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/features/app_shell/widgets/main_page_header.dart';
import 'package:seniors_27/shared/widgets/retro_button.dart';
import 'package:seniors_27/shared/widgets/retro_card.dart';
import 'package:seniors_27/shared/widgets/retro_photo_placeholder.dart';
import 'package:seniors_27/shared/widgets/retro_shadow_container.dart';
import 'package:seniors_27/shared/widgets/retro_sticker.dart';

class SeniorsDirectoryScreen extends StatelessWidget {
  const SeniorsDirectoryScreen({super.key});

  static const _seniors = [
    ('BILLY', AppColors.cyan),
    ('HANA', AppColors.green),
    ('MAHDI', AppColors.orange),
    ('SARAH', AppColors.pink),
    ('EHAB', AppColors.yellow),
    ('TAHA', AppColors.cyan),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const PageStorageKey('directory_scroll'),
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
      child: Column(
        children: [
          const MainPageHeader(
            title: 'Senior Directory',
            subtitle: 'Browse the faces of the Class of 2027.',
          ),
          const SizedBox(height: 25),
          Stack(
            clipBehavior: Clip.none,
            children: [
              const RetroShadowContainer(
                padding: EdgeInsets.symmetric(horizontal: 15, vertical: 14),
                borderRadius: 2,
                shadowOffset: Offset(6, 6),
                child: Row(
                  children: [
                    Icon(Icons.search, color: AppColors.ink, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Search seniors...',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 14,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -15,
                right: 10,
                child: Transform.rotate(
                  angle: -5 * math.pi / 180,
                  child: const RetroSticker(
                    color: AppColors.green,
                    width: 45,
                    height: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _seniors.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 20,
              childAspectRatio: 0.8,
            ),
            itemBuilder: (context, index) {
              final senior = _seniors[index];
              return _SeniorTile(
                name: senior.$1,
                accent: senior.$2,
                rotation: (index % 2 == 0 ? -1.5 : 1.5) * math.pi / 180,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SeniorTile extends StatelessWidget {
  const _SeniorTile({
    required this.name,
    required this.accent,
    required this.rotation,
  });

  final String name;
  final Color accent;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: RetroCard(
        padding: const EdgeInsets.all(10),
        shadowOffset: const Offset(5, 6),
        borderRadius: 0,
        child: Column(
          children: [
            Expanded(
              child: RetroPhotoPlaceholder(
                label: 'PHOTO',
                height: double.infinity,
                backgroundColor: accent,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            RetroButton(
              label: 'VIEW',
              height: 32,
              shadowOffset: const Offset(3, 3),
              onPressed: () {},
              textStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
