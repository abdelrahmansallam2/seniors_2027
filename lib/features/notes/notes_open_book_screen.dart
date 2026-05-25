import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/features/app_shell/widgets/main_page_header.dart';
import 'package:seniors_27/shared/widgets/retro_button.dart';
import 'package:seniors_27/shared/widgets/retro_card.dart';
import 'package:seniors_27/shared/widgets/retro_section_header.dart';
import 'package:seniors_27/shared/widgets/retro_sticker.dart';

class NotesOpenBookScreen extends StatelessWidget {
  const NotesOpenBookScreen({super.key});

  static const _notes = [
    ('JOE', 'HOBAAAAAAAAAAAAAAAA'),
    ('EHAB', 'Best memories live here.'),
    ('MEGZ', 'Retro board forever.'),
    ('TAHA', 'Class of 2027.'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const PageStorageKey('notes_scroll'),
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const MainPageHeader(
            title: 'Open Book',
            subtitle: 'Latest notes from seniors.',
          ),
          const SizedBox(height: 30),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: RetroSectionHeader(
                      title: 'NOTES',
                      backgroundColor: AppColors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 120,
                    child: RetroButton(
                      label: 'ADD NOTE',
                      height: 42,
                      backgroundColor: AppColors.green,
                      onPressed: () {},
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                top: -15,
                left: 20,
                child: Transform.rotate(
                  angle: -0.1,
                  child: const RetroSticker(
                    color: AppColors.cyan,
                    width: 40,
                    height: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 25),
          for (var index = 0; index < _notes.length; index++) ...[
            _OpenBookNote(
              author: _notes[index].$1,
              message: _notes[index].$2,
              canDelete: index < 2,
              rotation: (index % 2 == 0 ? -1.0 : 1.0) * math.pi / 180,
            ),
            const SizedBox(height: 20),
          ],
        ],
      ),
    );
  }
}

class _OpenBookNote extends StatelessWidget {
  const _OpenBookNote({
    required this.author,
    required this.message,
    required this.canDelete,
    required this.rotation,
  });

  final String author;
  final String message;
  final bool canDelete;
  final double rotation;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: rotation,
      child: RetroCard(
        borderRadius: 0,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        shadowOffset: const Offset(5, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  color: AppColors.ink,
                  child: Text(
                    author,
                    style: const TextStyle(
                      color: AppColors.paper,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Text(
                  'MAY 2026',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontFamily: 'monospace',
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ),
                if (canDelete) ...[
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 75,
                    child: RetroButton(
                      label: 'DELETE',
                      height: 32,
                      backgroundColor: AppColors.pink,
                      onPressed: () {},
                      textStyle: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
