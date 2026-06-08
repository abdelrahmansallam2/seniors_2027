import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/features/app_shell/widgets/main_page_header.dart';
import 'package:seniors_27/features/profile/models/profile_user.dart';
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
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Stack(
            clipBehavior: Clip.none,
            children: [
              MainPageHeader(
                title: 'My Profile',
                subtitle: 'Your senior identity.',
              ),
              Positioned(
                top: 2,
                right: 4,
                child: RetroSticker(
                  color: AppColors.magenta,
                  width: 58,
                  height: 20,
                  angle: 0.12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _ProfileCard(user: mockProfileUser),
          const SizedBox(height: 26),
          const _LinksSection(),
          const SizedBox(height: 26),
          const _FavoriteSongSection(),
          const SizedBox(height: 26),
          const _GalleryPreviewSection(),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: RetroButton(
              label: 'OPEN NOTES',
              height: 46,
              backgroundColor: AppColors.orange,
              onPressed: onOpenNotes,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});

  final ProfileUser user;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        RetroCard(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
          child: Column(
            children: [
              Center(
                child: RetroPhotoPlaceholder(
                  label: 'PHOTO',
                  width: 140,
                  height: 180,
                  backgroundColor: AppColors.cyan,
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Text(
                      user.name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user.role,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      user.description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (user.gender.isNotEmpty || user.email.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.paper,
                          border: Border.all(color: AppColors.ink, width: 1.5),
                        ),
                        child: Column(
                          children: [
                            if (user.gender.isNotEmpty)
                              _MetaLine(label: 'Gender', value: user.gender),
                            if (user.gender.isNotEmpty && user.email.isNotEmpty)
                              const SizedBox(height: 4),
                            if (user.email.isNotEmpty)
                              _MetaLine(label: 'Email', value: user.email),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -8,
          right: -6,
          child: Transform.rotate(
            angle: 0.15,
            child: const RetroSticker(
              color: AppColors.pink,
              width: 36,
              height: 36,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: AppColors.muted,
          ),
        ),
        Expanded(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _LinksSection extends StatelessWidget {
  const _LinksSection();

  @override
  Widget build(BuildContext context) {
    return RetroCard(
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.paper,
      child: Column(
        children: [
          const RetroSectionHeader(
            title: 'LINKS',
            backgroundColor: AppColors.yellow,
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _LinkButton(label: 'IG', color: AppColors.pink),
                _LinkButton(label: 'LN', color: AppColors.cyan),
                _LinkButton(label: 'GH', color: AppColors.green),
                _LinkButton(label: 'PF', color: AppColors.orange),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      child: RetroButton(
        label: label,
        height: 38,
        backgroundColor: color,
        shadowOffset: const Offset(3, 3),
        onPressed: () {},
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _FavoriteSongSection extends StatelessWidget {
  const _FavoriteSongSection();

  @override
  Widget build(BuildContext context) {
    return RetroCard(
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.paper,
      child: Column(
        children: [
          const RetroSectionHeader(
            title: 'FAVORITE SONG',
            backgroundColor: AppColors.pink,
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.paper,
                border: Border.all(color: AppColors.ink, width: 2),
              ),
              child: Row(
                children: [
                  const Icon(Icons.music_note, size: 28, color: AppColors.ink),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mockProfileUser.song?.title ?? 'No song yet',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mockProfileUser.song?.artist ?? '',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryPreviewSection extends StatelessWidget {
  const _GalleryPreviewSection();

  @override
  Widget build(BuildContext context) {
    return RetroCard(
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const RetroSectionHeader(
            title: 'GALLERY',
            backgroundColor: AppColors.cyan,
          ),
          const SizedBox(height: 14),
          const SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.fromLTRB(18, 0, 18, 18),
            child: Row(
              children: [
                RetroPhotoPlaceholder(
                  label: 'MEMORY',
                  width: 100,
                  height: 110,
                  backgroundColor: AppColors.yellow,
                ),
                SizedBox(width: 10),
                RetroPhotoPlaceholder(
                  label: 'MEMORY',
                  width: 100,
                  height: 110,
                  backgroundColor: AppColors.green,
                ),
                SizedBox(width: 10),
                RetroPhotoPlaceholder(
                  label: 'MEMORY',
                  width: 100,
                  height: 110,
                  backgroundColor: AppColors.pink,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
