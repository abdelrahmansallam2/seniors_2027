import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:seniors_27/core/constants/app_assets.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/features/app_shell/widgets/main_page_header.dart';
import 'package:seniors_27/features/dashboard/widgets/announcement_card.dart';
import 'package:seniors_27/features/dashboard/widgets/challenge_preview_card.dart';
import 'package:seniors_27/features/dashboard/widgets/challenges_empty_state.dart';
import 'package:seniors_27/features/dashboard/widgets/dashboard_upload_placeholder.dart';
import 'package:seniors_27/shared/widgets/app_logo.dart';
import 'package:seniors_27/features/dashboard/widgets/countdown_board_row.dart';
import 'package:seniors_27/features/dashboard/widgets/events_empty_state.dart';
import 'package:seniors_27/shared/widgets/retro_button.dart';
import 'package:seniors_27/shared/widgets/retro_card.dart';
import 'package:seniors_27/shared/widgets/retro_section_header.dart';
import 'package:seniors_27/shared/widgets/retro_sticker.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({required this.onOpenNotes, super.key});

  final VoidCallback onOpenNotes;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const PageStorageKey('dashboard_scroll'),
      padding: const EdgeInsets.fromLTRB(22, 30, 22, 110),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Stack(
                clipBehavior: Clip.none,
                children: [
                  MainPageHeader(
                    title: 'Dashboard',
                    subtitle: 'Your senior portal home.',
                  ),
                  Positioned(
                    top: 2,
                    right: 4,
                    child: RetroSticker(
                      color: AppColors.yellow,
                      width: 58,
                      height: 20,
                      angle: 0.12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              const _DashboardHeroCard(),
              const SizedBox(height: 26),

              _DailyHighlightsSection(),
              const SizedBox(height: 26),

              _AnnouncementsSection(),
              const SizedBox(height: 26),

              const _UpcomingEventsSection(),
              const SizedBox(height: 26),

              _ChallengesPreviewSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHeroCard extends StatelessWidget {
  const _DashboardHeroCard();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        RetroCard(
          backgroundColor: AppColors.paper,
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                const AppLogo(size: 130),
                const SizedBox(height: 14),
                const Text(
                  'BUILT TO BE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Transform.rotate(
                  angle: -0.025,
                  child: Container(
                    width: 245,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.yellow,
                      border: Border.all(color: AppColors.ink, width: 2.5),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.ink,
                          offset: Offset(5, 5),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: const Text(
                      'REMEMBERED',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        Positioned(
          top: 30,
          left: 22,
          child: Transform.rotate(
            angle: -0.16,
            child: SvgPicture.asset(
              AppAssets.seniorCardSticker,
              width: 58,
              height: 58,
            ),
          ),
        ),

        const Positioned(
          bottom: -10,
          right: 18,
          child: RetroSticker(
            color: AppColors.pink,
            width: 54,
            height: 18,
            angle: -0.12,
          ),
        ),
      ],
    );
  }
}

class _DailyHighlightsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RetroCard(
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.paper,
      child: Column(
        children: [
          const RetroSectionHeader(
            title: 'DAILY_HIGHLIGHTS',
            backgroundColor: AppColors.green,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 132,
            child: RetroButton(
              label: 'ADD TODAY',
              height: 34,
              onPressed: () {},
              textStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: DashboardUploadPlaceholder(),
          ),
          const SizedBox(height: 10),
          const Text(
            'click to open memories',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.fromLTRB(18, 0, 18, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Latest by admin',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
                Text(
                  'Today',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnnouncementsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RetroCard(
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.paper,
      child: const Column(
        children: [
          RetroSectionHeader(
            title: 'ANNOUNCEMENTS',
            backgroundColor: AppColors.magenta,
          ),
          SizedBox(height: 12),
          _AdminBadge(color: AppColors.pink),
          SizedBox(height: 14),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: AnnouncementCard(
              title: 'CHALLENGES TIME!!!',
              content: 'Eid challenges soon...',
              date: 'May 24, 2026',
              isSpotlight: true,
            ),
          ),
          SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _UpcomingEventsSection extends StatelessWidget {
  const _UpcomingEventsSection();

  @override
  Widget build(BuildContext context) {
    return RetroCard(
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.paper,
      child: const Column(
        children: [
          RetroSectionHeader(
            title: 'UPCOMING_EVENTS',
            backgroundColor: AppColors.orange,
          ),
          SizedBox(height: 18),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: CountdownBoardRow(count: 0),
          ),
          SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 18),
            child: EventsEmptyState(),
          ),
          SizedBox(height: 18),
        ],
      ),
    );
  }
}

class _ChallengesPreviewSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Backend-ready placeholder list
    final challenges = [];

    return RetroCard(
      padding: EdgeInsets.zero,
      backgroundColor: AppColors.paper,
      child: Column(
        children: [
          const RetroSectionHeader(
            title: 'TOP_CHALLENGES',
            backgroundColor: AppColors.yellow,
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: challenges.isEmpty
                ? const ChallengesEmptyState()
                : Column(
                    children: [
                      ...challenges.asMap().entries.map((entry) {
                        final i = entry.key;
                        final challenge = entry.value;
                        return ChallengePreviewCard(
                          index: i + 1,
                          title: challenge['title'] ?? '',
                          votes: challenge['votes'] ?? 0,
                        );
                      }),
                    ],
                  ),
          ),
          const SizedBox(height: 10),
          if (challenges.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
              child: RetroButton(
                label: 'VIEW ALL CHALLENGES',
                height: 40,
                onPressed: () {},
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          if (challenges.isEmpty) const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _AdminBadge extends StatelessWidget {
  const _AdminBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.ink, width: 2),
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RetroSticker(color: color, width: 12, height: 12, angle: 0.2),
          const SizedBox(width: 8),
          const Text(
            'Fresh from admin',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
