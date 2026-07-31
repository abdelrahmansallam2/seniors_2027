import 'package:flutter/material.dart';
import 'package:seniors_27/core/api/api_constants.dart';
import 'package:seniors_27/features/dashboard/models/announcement.dart';
import 'package:seniors_27/features/dashboard/models/poll_option.dart';

class AnnouncementColors {
  static const ink = Color(0xFF171214);
  static const paper = Color(0xFFFFFCF3);
  static const pinkCard = Color(0xFFFFFFFF);
  static const pinkTitle = Color(0xFFFFD6E4);
  static const pinkBadge = Color(0xFFFFFFFF);
  static const pollCream = Color(0xFFFFF6CE);
  static const labelYellow = Color(0xFFFFFF73);
  static const selectedYellow = Color(0xFFFFCD38);
  static const sideYellow = Color(0xFFFFC928);
  static const magenta = Color(0xFFFF00F5);
  static const secondary = Color(0xFF5E585A);
}

String _formatDate(String isoDate) {
  final dt = DateTime.tryParse(isoDate);
  if (dt == null) return isoDate;
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}

class AnnouncementCard extends StatelessWidget {
  static const double _contentHorizontalInset = 8;

  const AnnouncementCard({
    required this.announcement,
    this.isVoting = false,
    this.onVote,
    this.onWhoVoted,
    super.key,
  });

  final Announcement announcement;
  final bool isVoting;
  final void Function(String optionLabel)? onVote;
  final void Function(PollOption option)? onWhoVoted;

  bool get _hasPhoto {
    final url = announcement.photoUrl;
    return url != null && url.trim().isNotEmpty;
  }

  String get _resolvedPhotoUrl {
    final url = announcement.photoUrl;
    if (url == null || url.trim().isEmpty) return '';
    final trimmed = url.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    return '${ApiConstants.baseUrl}$trimmed';
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 0.95,
      child: Container(
        decoration: BoxDecoration(
          color: AnnouncementColors.paper,
          border: Border.all(color: AnnouncementColors.ink, width: 2),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: AnnouncementColors.ink,
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Container(
            decoration: BoxDecoration(
              color: AnnouncementColors.paper,
              border: Border.all(color: AnnouncementColors.ink, width: 1.5),
              borderRadius: BorderRadius.circular(14),
            ),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _contentHorizontalInset,
          ),
          child: _buildMetaRow(),
        ),
        const SizedBox(height: 4),
        if (_hasPhoto) ...[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _contentHorizontalInset,
            ),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(minHeight: 140, maxHeight: 260),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AnnouncementColors.ink, width: 1.5),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                _resolvedPhotoUrl,
                width: double.infinity,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Could not load image',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AnnouncementColors.ink,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _contentHorizontalInset,
          ),
          child: _buildTitleBox(),
        ),
        if (announcement.body.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            announcement.body,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.4,
              color: AnnouncementColors.ink,
              decoration: TextDecoration.none,
            ),
          ),
        ],
        if (announcement.hasPoll) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: _contentHorizontalInset,
            ),
            child: _PollCard(
              poll: announcement.poll!,
              isVoting: isVoting,
              onVote: onVote,
              onWhoVoted: onWhoVoted,
            ),
          ),
        ],
        const SizedBox(height: 6),
        Row(
          children: [
            CircleAvatar(
              radius: 7,
              backgroundColor: AnnouncementColors.pinkTitle,
              child: const Icon(
                Icons.person,
                size: 8,
                color: AnnouncementColors.ink,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              announcement.createdByUsername,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AnnouncementColors.ink,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetaRow() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          decoration: BoxDecoration(
            color: AnnouncementColors.labelYellow,
            border: Border.all(color: AnnouncementColors.ink, width: 2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.star, size: 10, color: AnnouncementColors.ink),
              SizedBox(width: 2),
              Text(
                'SPOTLIGHT',
                style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w900,
                  color: AnnouncementColors.ink,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Text(
          _formatDate(announcement.createdAt),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: AnnouncementColors.secondary,
            decoration: TextDecoration.none,
          ),
        ),
      ],
    );
  }

  Widget _buildTitleBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: AnnouncementColors.pinkTitle,
        border: Border.all(color: AnnouncementColors.ink, width: 1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: AnnouncementColors.ink,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AnnouncementColors.labelYellow,
              border: Border.all(color: AnnouncementColors.ink, width: 1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'TITLE',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: AnnouncementColors.ink,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            announcement.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              height: 1.1,
              color: AnnouncementColors.ink,
              decoration: TextDecoration.none,
            ),
          ),
        ],
      ),
    );
  }
}

class _PollCard extends StatelessWidget {
  const _PollCard({
    required this.poll,
    required this.isVoting,
    required this.onVote,
    required this.onWhoVoted,
  });

  final Poll poll;
  final bool isVoting;
  final void Function(String optionLabel)? onVote;
  final void Function(PollOption option)? onWhoVoted;

  @override
  Widget build(BuildContext context) {
    final totalVotes = poll.totalVotes;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: AnnouncementColors.pollCream,
        border: Border.all(color: AnnouncementColors.ink, width: 1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Poll:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AnnouncementColors.ink,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  poll.title,
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: AnnouncementColors.ink,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          SizedBox(
            width: double.infinity,
            child: const Text(
              'Click your selected option again to remove your vote.',
              softWrap: true,
              maxLines: null,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: AnnouncementColors.secondary,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          const SizedBox(height: 4),
          ...List.generate(poll.options.length, (index) {
            final option = poll.options[index];
            final percentage = totalVotes == 0
                ? 0.0
                : option.voteCount / totalVotes * 100;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: isVoting ? null : () => onVote?.call(option.label),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: option.isSelected
                          ? AnnouncementColors.selectedYellow
                          : AnnouncementColors.paper,
                      border: Border.all(
                        color: AnnouncementColors.ink,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AnnouncementColors.ink,
                          offset: option.isSelected
                              ? const Offset(2, 2)
                              : const Offset(2, 2),
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${index + 1}.',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: AnnouncementColors.ink,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            option.label,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AnnouncementColors.ink,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                        Text(
                          '${option.voteCount} VOTE${option.voteCount == 1 ? '' : 'S'} - ${percentage.toInt()}%',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: AnnouncementColors.ink,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 3, top: 3, bottom: 5),
                  child: InkWell(
                    onTap: () => onWhoVoted?.call(option),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AnnouncementColors.paper,
                        border: Border.all(
                          color: AnnouncementColors.ink,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'WHO VOTED (${option.voteCount})',
                        maxLines: 1,
                        softWrap: false,
                        style: const TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                          color: AnnouncementColors.ink,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

void showPollVotersDialog(BuildContext context, PollOption option) {
  showDialog(
    context: context,
    builder: (context) => _PollVotersDialog(option: option),
  );
}

class _PollVotersDialog extends StatelessWidget {
  const _PollVotersDialog({required this.option});

  final PollOption option;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AnnouncementColors.paper,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
        side: const BorderSide(color: AnnouncementColors.ink, width: 2),
      ),
      title: Row(
        children: [
          const Icon(
            Icons.people_outline,
            size: 20,
            color: AnnouncementColors.ink,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              option.voters.isEmpty
                  ? 'No votes yet'
                  : 'Voters (${option.voters.length})',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AnnouncementColors.ink,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: option.voters.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No votes yet.',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AnnouncementColors.secondary,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              )
            : ListView.separated(
                shrinkWrap: true,
                itemCount: option.voters.length,
                separatorBuilder: (_, _) =>
                    const Divider(color: AnnouncementColors.ink, height: 1),
                itemBuilder: (context, index) {
                  final voter = option.voters[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AnnouncementColors.ink.withValues(
                            alpha: 0.1,
                          ),
                          backgroundImage: voter.photoUrl != null
                              ? NetworkImage(voter.photoUrl!)
                              : null,
                          child: voter.photoUrl == null
                              ? Text(
                                  voter.username.isNotEmpty
                                      ? voter.username[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    color: AnnouncementColors.ink,
                                    decoration: TextDecoration.none,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    voter.username,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: AnnouncementColors.ink,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                  if (voter.isCurrentUser) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AnnouncementColors.labelYellow,
                                        border: Border.all(
                                          color: AnnouncementColors.ink,
                                          width: 1,
                                        ),
                                      ),
                                      child: const Text(
                                        'YOU',
                                        style: TextStyle(
                                          fontSize: 7,
                                          fontWeight: FontWeight.w900,
                                          color: AnnouncementColors.ink,
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                voter.votedAt,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: AnnouncementColors.secondary,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: AnnouncementColors.ink),
          child: const Text(
            'CLOSE',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 11,
              color: AnnouncementColors.ink,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ],
    );
  }
}
