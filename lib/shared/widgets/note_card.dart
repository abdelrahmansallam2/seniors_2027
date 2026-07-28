import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';

class NoteCard extends StatelessWidget {
  const NoteCard({
    required this.senderName,
    required this.date,
    required this.content,
    super.key,
    this.senderPhotoUrl,
    this.loveCount,
    this.likeCount,
    this.lovedByMe = false,
    this.likedByMe = false,
    this.onLove,
    this.onLike,
    this.canDelete = false,
    this.onDelete,
    this.maxLines,
  });

  final String senderName;
  final String date;
  final String content;
  final String? senderPhotoUrl;
  final int? loveCount;
  final int? likeCount;
  final bool lovedByMe;
  final bool likedByMe;
  final VoidCallback? onLove;
  final VoidCallback? onLike;
  final bool canDelete;
  final VoidCallback? onDelete;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final initial = senderName.isNotEmpty ? senderName[0].toUpperCase() : '?';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.ink, width: 2),
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
            child: Row(
              children: [
                _SenderAvatar(photoUrl: senderPhotoUrl, initial: initial),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        senderName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                if (date.isNotEmpty)
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                    ),
                  ),
              ],
            ),
          ),
          Container(width: double.infinity, height: 1, color: AppColors.ink),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Text(
              content,
              maxLines: maxLines,
              overflow: maxLines != null ? TextOverflow.ellipsis : null,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
                height: 1.4,
              ),
            ),
          ),
          if (onLove != null || onLike != null)
            Container(width: double.infinity, height: 1, color: AppColors.ink),
          if (onLove != null || onLike != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  _PillButton(
                    icon: '❤️',
                    label: 'LOVE',
                    count: loveCount,
                    isSelected: lovedByMe,
                    selectedColor: AppColors.pink,
                    onTap: onLove,
                  ),
                  const SizedBox(width: 8),
                  _PillButton(
                    icon: '😂',
                    label: 'AHAHA',
                    count: likeCount,
                    isSelected: likedByMe,
                    selectedColor: AppColors.yellow,
                    onTap: onLike,
                  ),
                  const Spacer(),
                  if (canDelete && onDelete != null)
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.pink,
                          border: Border.all(color: AppColors.ink, width: 2),
                          boxShadow: const [
                            BoxShadow(
                              color: AppColors.ink,
                              offset: Offset(2, 2),
                              blurRadius: 0,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: const Text('🗑', style: TextStyle(fontSize: 14)),
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

class _SenderAvatar extends StatelessWidget {
  const _SenderAvatar({required this.photoUrl, required this.initial});

  final String? photoUrl;
  final String initial;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.ink, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: hasPhoto
          ? Image.network(
              photoUrl!,
              width: 32,
              height: 32,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _InitialFallback(initial: initial),
            )
          : _InitialFallback(initial: initial),
    );
  }
}

class _InitialFallback extends StatelessWidget {
  const _InitialFallback({required this.initial});

  final String initial;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: AppColors.pink,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.white,
          fontSize: 14,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.count,
    required this.isSelected,
    required this.selectedColor,
    required this.onTap,
  });

  final String icon;
  final String label;
  final int? count;
  final bool isSelected;
  final Color selectedColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final displayCount = count != null && count! > 0 ? ' $count' : '';
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : AppColors.paper,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.ink, width: 2),
          boxShadow: const [
            BoxShadow(
              color: AppColors.ink,
              offset: Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Text(
          '$icon $label$displayCount',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w900,
            color: isSelected ? AppColors.ink : AppColors.muted,
          ),
        ),
      ),
    );
  }
}
