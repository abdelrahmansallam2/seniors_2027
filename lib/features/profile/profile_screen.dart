import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/features/app_shell/widgets/main_page_header.dart';
import 'package:seniors_27/shared/widgets/retro_button.dart';
import 'package:seniors_27/shared/widgets/retro_card.dart';
import 'package:seniors_27/shared/widgets/retro_photo_placeholder.dart';
import 'package:seniors_27/shared/widgets/retro_section_header.dart';
import 'package:seniors_27/shared/widgets/retro_sticker.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({required this.onOpenNotes, super.key});

  final VoidCallback onOpenNotes;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const PageStorageKey('profile_scroll'),
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MainPageHeader(
            title: 'My Profile',
            subtitle: 'Senior 2027 page',
          ),
          const SizedBox(height: 25),
          Stack(
            clipBehavior: Clip.none,
            children: [
              const RetroSectionHeader(
                title: 'SENIOR_HERO',
                backgroundColor: AppColors.yellowWarm,
              ),
              Positioned(
                top: -15,
                right: -5,
                child: Transform.rotate(
                  angle: 0.1,
                  child: const RetroSticker(
                    color: AppColors.pink,
                    width: 40,
                    height: 40,
                  ),
                ),
              ),
            ],
          ),
          RetroCard(
            borderRadius: 0,
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RetroPhotoPlaceholder(
                  label: 'PROFILE',
                  width: 100,
                  height: 130,
                  backgroundColor: AppColors.cyan,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HELLO\nSENIOR BILLY',
                        style: TextStyle(
                          fontSize: 22,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'When life gets loud,\nturn the music up.',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _SocialButton(label: 'IG', color: AppColors.pink),
                          const SizedBox(width: 8),
                          _SocialButton(label: 'IN', color: AppColors.cyan),
                          const SizedBox(width: 8),
                          _SocialButton(label: 'SP', color: AppColors.green),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          const RetroSectionHeader(
            title: 'MY STATS',
            backgroundColor: AppColors.cyan,
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(
                child: _StatBox(label: 'POINTS', value: '850'),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _StatBox(label: 'RANK', value: '#12'),
              ),
            ],
          ),
          const SizedBox(height: 25),
          const RetroSectionHeader(
            title: 'NOTES',
            backgroundColor: AppColors.orange,
          ),
          const SizedBox(height: 12),
          RetroCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                const _NotePreview(
                  author: 'JOE',
                  message: 'Best memories live here.',
                ),
                const SizedBox(height: 12),
                const _NotePreview(
                  author: 'TAHA',
                  message: 'Class of 2027 forever.',
                ),
                const SizedBox(height: 16),
                RetroButton(
                  label: 'OPEN FULL BOOK',
                  height: 42,
                  onPressed: onOpenNotes,
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          const RetroSectionHeader(
            title: 'GALLERY',
            backgroundColor: AppColors.yellow,
          ),
          const SizedBox(height: 12),
          const RetroPhotoPlaceholder(height: 140, label: 'GALLERY PHOTO'),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.ink, width: 2.5),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.w800,
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

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      child: RetroButton(
        label: label,
        height: 34,
        backgroundColor: color,
        shadowOffset: const Offset(3, 3),
        onPressed: () {},
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _NotePreview extends StatelessWidget {
  const _NotePreview({required this.author, required this.message});

  final String author;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                author,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Icon(Icons.push_pin, size: 14, color: AppColors.pink),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}
