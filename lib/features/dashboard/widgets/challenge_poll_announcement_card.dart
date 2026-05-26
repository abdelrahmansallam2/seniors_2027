import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/features/dashboard/models/announcement.dart';
import 'package:seniors_27/features/dashboard/models/poll_option.dart';
import 'package:seniors_27/shared/widgets/retro_card.dart';

class ChallengePollAnnouncementCard extends StatelessWidget {
  const ChallengePollAnnouncementCard({
    required this.announcement,
    this.onOptionTap,
    this.onWhoVotedTap,
    super.key,
  });

  final Announcement announcement;
  final Function(String optionId)? onOptionTap;
  final Function(String optionId)? onWhoVotedTap;

  @override
  Widget build(BuildContext context) {
    return RetroCard(
      backgroundColor: AppColors.paper,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top metadata row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (announcement.isSpotlight)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.yellow,
                    border: Border.all(color: AppColors.ink, width: 2),
                  ),
                  child: const Text(
                    'SPOTLIGHT',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
                  ),
                ),
              Text(
                announcement.date,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Title Area
          const Text(
            'TITLE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.paper,
              border: Border.all(color: AppColors.ink, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.pink,
                  offset: Offset(4, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Text(
              announcement.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            announcement.description,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Poll Block
          if (announcement.pollTitle != null) ...[
            Text(
              'Poll: ${announcement.pollTitle}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            const Text(
              'Click your selected option again to remove your vote.',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Poll Options
          if (announcement.options != null)
            ...announcement.options!.map(
              (option) => _PollOptionRow(
                option: option,
                onTap: () => onOptionTap?.call(option.id),
                onWhoVotedTap: () => onWhoVotedTap?.call(option.id),
              ),
            ),

          const SizedBox(height: 12),

          // Footer
          Text(
            'Latest by ${announcement.author}',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _PollOptionRow extends StatelessWidget {
  const _PollOptionRow({
    required this.option,
    required this.onTap,
    required this.onWhoVotedTap,
  });

  final PollOption option;
  final VoidCallback onTap;
  final VoidCallback onWhoVotedTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.paper,
              border: Border.all(
                color: AppColors.ink,
                width: option.isSelected ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.ink,
                  offset: option.isSelected
                      ? const Offset(2, 2)
                      : const Offset(4, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Stack(
              children: [
                // Progress Bar
                LayoutBuilder(
                  builder: (context, constraints) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: constraints.maxWidth * option.percentage,
                      height: 48,
                      decoration: BoxDecoration(
                        color: option.isSelected
                            ? AppColors.yellow.withOpacity(0.4)
                            : AppColors.green.withOpacity(0.2),
                      ),
                    );
                  },
                ),
                // Text Content
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          option.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        '${option.votes} VOTES - ${(option.percentage * 100).toInt()}%',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // Who Voted Button
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: InkWell(
            onTap: onWhoVotedTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.paper,
                border: Border.all(color: AppColors.ink, width: 1.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'WHO VOTED (${option.votes})',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
