import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:seniors_27/core/constants/app_assets.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/features/app_shell/widgets/main_page_header.dart';
import 'package:seniors_27/shared/widgets/retro_button.dart';
import 'package:seniors_27/shared/widgets/retro_card.dart';
import 'package:seniors_27/shared/widgets/retro_photo_placeholder.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const PageStorageKey('leaderboard_scroll'),
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
      child: Column(
        children: [
          const MainPageHeader(
            title: 'Leaderboard',
            subtitle: 'All seniors ranked by points.',
          ),
          const SizedBox(height: 25),
          RetroCard(
            padding: EdgeInsets.zero,
            borderRadius: 4,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    children: [
                      SvgPicture.asset(
                        AppAssets.trophyWinner,
                        width: 72,
                        height: 72,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'TOP SENIORS',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        'CLASS OF 2027',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                for (var index = 0; index < 8; index++)
                  _RankRow(rank: index + 1),
              ],
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

class _RankRow extends StatelessWidget {
  const _RankRow({required this.rank});

  final int rank;

  Widget _buildRankIcon() {
    if (rank <= 3) {
      final asset = switch (rank) {
        1 => AppAssets.icRank1,
        2 => AppAssets.icRank2,
        _ => AppAssets.icRank3,
      };
      return SvgPicture.asset(asset, width: 24, height: 24);
    }
    return Text(
      '$rank',
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        fontFamily: 'monospace',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTopThree = rank <= 3;
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.ink, width: 2)),
      ),
      child: Row(
        children: [
          SizedBox(width: 30, child: Center(child: _buildRankIcon())),
          const SizedBox(width: 12),
          RetroPhotoPlaceholder(
            label: '',
            width: 32,
            height: 32,
            backgroundColor: rank.isEven ? AppColors.pink : AppColors.cyan,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isTopThree ? 'SENIOR CHAMP' : 'Senior Peer',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isTopThree ? FontWeight.w900 : FontWeight.w800,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isTopThree ? AppColors.yellow : AppColors.paper,
              border: Border.all(color: AppColors.ink, width: 1.5),
            ),
            child: Text(
              '${1000 - (rank * 50)} PTS',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
