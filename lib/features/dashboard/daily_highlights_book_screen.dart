import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:seniors_27/core/api/api_client.dart';
import 'package:seniors_27/core/api/api_exception.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/features/dashboard/data/daily_highlights_api_service.dart';
import 'package:seniors_27/features/dashboard/models/daily_highlight.dart';

class DailyHighlightsBookScreen extends StatefulWidget {
  final List<DailyHighlight> highlights;
  final VoidCallback onDashboardRefresh;
  final int initialIndex;

  const DailyHighlightsBookScreen({
    super.key,
    required this.highlights,
    required this.onDashboardRefresh,
    this.initialIndex = 0,
  });

  @override
  State<DailyHighlightsBookScreen> createState() =>
      _DailyHighlightsBookScreenState();
}

class _DailyHighlightsBookScreenState extends State<DailyHighlightsBookScreen> {
  late List<DailyHighlight> _highlights;
  late int _currentIndex;
  final _api = DailyHighlightsApiService(ApiClient());
  final Set<String> _reactingIds = {};
  final Set<String> _deletingIds = {};

  @override
  void initState() {
    super.initState();
    _highlights = List.from(widget.highlights);
    _currentIndex = widget.initialIndex;
  }

  void _goTo(int index) {
    if (index < 0 || index >= _highlights.length) return;
    setState(() => _currentIndex = index);
  }

  Future<void> _toggleReaction(int index, String type) async {
    if (index < 0 || index >= _highlights.length) return;
    final highlight = _highlights[index];
    if (_reactingIds.contains(highlight.id)) return;

    setState(() => _reactingIds.add(highlight.id));
    try {
      final updated = await _api.addReaction(highlight.id, type);
      if (!mounted) return;
      setState(() {
        _highlights[index] = updated;
        _reactingIds.remove(highlight.id);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
      setState(() => _reactingIds.remove(highlight.id));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update reaction.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteHighlight(int index) async {
    if (index < 0 || index >= _highlights.length) return;
    final highlight = _highlights[index];
    if (_deletingIds.contains(highlight.id)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: const Text(
          'Delete Highlight',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        content: const Text(
          'Are you sure you want to delete this highlight?',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w700, color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _deletingIds.add(highlight.id));
    try {
      await _api.delete(highlight.id);
      if (!mounted) return;
      widget.onDashboardRefresh();
      setState(() {
        _highlights.removeAt(index);
        if (_highlights.isEmpty) {
          Navigator.pop(context);
          return;
        }
        if (_currentIndex >= _highlights.length) {
          _currentIndex = _highlights.length - 1;
        }
        _deletingIds.remove(highlight.id);
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
      setState(() => _deletingIds.remove(highlight.id));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to delete highlight.'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _deletingIds.remove(highlight.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final highlights = _highlights;
    final highlight = highlights[_currentIndex];
    final bool isFirst = _currentIndex == 0;
    final bool isLast = _currentIndex == highlights.length - 1;

    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        color: Colors.black.withValues(alpha: 0.25),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 60, bottom: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPhotoCard(highlight, isFirst, isLast),
                      const SizedBox(height: 16),
                      _buildInfoCard(highlight),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 12,
                right: 16,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      border: Border.all(color: Colors.white24, width: 1.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoCard(DailyHighlight highlight, bool isFirst, bool isLast) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.ink, width: 3),
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(6, 7), blurRadius: 0),
        ],
      ),
      child: SizedBox(
        height: screenHeight * 0.45,
        child: Stack(
          children: [
            _BookImage(highlight: highlight),
            if (!isFirst)
              Positioned(
                left: 4,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _ArrowButton(
                    icon: Icons.chevron_left,
                    onTap: () => _goTo(_currentIndex - 1),
                  ),
                ),
              ),
            if (!isLast)
              Positioned(
                right: 4,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _ArrowButton(
                    icon: Icons.chevron_right,
                    onTap: () => _goTo(_currentIndex + 1),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(DailyHighlight highlight) {
    final currentUserLoved = highlight.reactions.any(
      (r) => r.type.trim().toLowerCase() == 'love' && r.isCurrentUser,
    );
    final loveCount = highlight.reactions
        .where((r) => r.type.trim().toLowerCase() == 'love')
        .length;
    final currentUserAhaha = highlight.reactions.any(
      (r) => r.type.trim().toLowerCase() == 'ahaha' && r.isCurrentUser,
    );
    final ahahaCount = highlight.reactions
        .where((r) => r.type.trim().toLowerCase() == 'ahaha')
        .length;
    final isReacting = _reactingIds.contains(highlight.id);
    final isDeleting = _deletingIds.contains(highlight.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.ink, width: 3),
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(color: AppColors.ink, offset: Offset(6, 7), blurRadius: 0),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (highlight.user?.photoUrl != null &&
                  highlight.user!.photoUrl!.isNotEmpty)
                CircleAvatar(
                  radius: 14,
                  backgroundImage: NetworkImage(highlight.user!.photoUrl!),
                ),
              if (highlight.user?.photoUrl != null &&
                  highlight.user!.photoUrl!.isNotEmpty)
                const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      highlight.user?.username ?? '',
                      style: const TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    if (highlight.createdAt.isNotEmpty)
                      Text(
                        _formatTime(highlight.createdAt),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                          decoration: TextDecoration.none,
                        ),
                      ),
                  ],
                ),
              ),
              _ReactionButton(
                isSelected: currentUserLoved,
                selectedIcon: Icons.favorite,
                unselectedIcon: Icons.favorite_border,
                selectedColor: Colors.red,
                count: loveCount,
                isLoading: isReacting,
                onTap: isReacting
                    ? null
                    : () => _toggleReaction(_currentIndex, 'Love'),
              ),
              const SizedBox(width: 6),
              _ReactionButton(
                isSelected: currentUserAhaha,
                selectedIcon: Icons.emoji_emotions,
                unselectedIcon: Icons.emoji_emotions_outlined,
                selectedColor: AppColors.yellow,
                count: ahahaCount,
                isLoading: isReacting,
                onTap: isReacting
                    ? null
                    : () => _toggleReaction(_currentIndex, 'Ahaha'),
              ),
              if (highlight.isOwnedByCurrentUser) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: isDeleting
                      ? null
                      : () => _deleteHighlight(_currentIndex),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: isDeleting
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.red,
                            ),
                          )
                        : const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 18,
                          ),
                  ),
                ),
              ],
            ],
          ),
          if (highlight.mentionedUsers.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 28,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: highlight.mentionedUsers.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final user = highlight.mentionedUsers[i];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cyan.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.ink.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                          CircleAvatar(
                            radius: 8,
                            backgroundImage: NetworkImage(user.photoUrl!),
                          ),
                        if (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                          const SizedBox(width: 4),
                        Text(
                          '@${user.username}',
                          style: const TextStyle(
                            color: AppColors.ink,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return iso;
    }
  }
}

class _BookImage extends StatefulWidget {
  final DailyHighlight highlight;

  const _BookImage({required this.highlight});

  @override
  State<_BookImage> createState() => _BookImageState();
}

class _BookImageState extends State<_BookImage> {
  ui.Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(_BookImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.highlight.photoUrl != widget.highlight.photoUrl) {
      _imageSize = null;
      _resolveImage();
    }
  }

  void _resolveImage() {
    final url = widget.highlight.photoUrl;
    if (url == null || url.isEmpty) return;
    final stream = NetworkImage(url).resolve(const ImageConfiguration());
    stream.addListener(
      ImageStreamListener((info, _) {
        if (mounted) {
          setState(() {
            _imageSize = ui.Size(
              info.image.width.toDouble(),
              info.image.height.toDouble(),
            );
          });
        }
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final highlight = widget.highlight;
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final container = ui.Size(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          children: [
            Center(
              child: Image.network(
                highlight.photoUrl ?? '',
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.broken_image,
                  color: Colors.white54,
                  size: 48,
                ),
              ),
            ),
            if (highlight.captionText != null &&
                highlight.captionText!.isNotEmpty &&
                _imageSize != null)
              _CaptionOverlay(
                containerSize: container,
                imageSize: _imageSize!,
                captionText: highlight.captionText!,
                captionYPercent: highlight.captionYPercent ?? 0.5,
              ),
          ],
        );
      },
    );
  }
}

class _CaptionOverlay extends StatelessWidget {
  final ui.Size containerSize;
  final ui.Size imageSize;
  final String captionText;
  final double captionYPercent;

  const _CaptionOverlay({
    required this.containerSize,
    required this.imageSize,
    required this.captionText,
    required this.captionYPercent,
  });

  @override
  Widget build(BuildContext context) {
    final rect = fittedRect(containerSize, imageSize);
    const bandHeight = 44.0;
    final maxTravel = rect.height - bandHeight;
    final top =
        rect.top +
        captionYPercent.clamp(0.0, 1.0) * (maxTravel > 0 ? maxTravel : 0);

    return Positioned(
      top: top.clamp(rect.top, rect.bottom - bandHeight),
      left: rect.left,
      width: rect.width,
      child: Container(
        constraints: const BoxConstraints(minHeight: bandHeight),
        color: Colors.black54,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          captionText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ArrowButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
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
        child: Icon(icon, size: 20, color: AppColors.ink),
      ),
    );
  }
}

class _ReactionButton extends StatelessWidget {
  final bool isSelected;
  final IconData selectedIcon;
  final IconData unselectedIcon;
  final Color selectedColor;
  final int count;
  final bool isLoading;
  final VoidCallback? onTap;

  const _ReactionButton({
    required this.isSelected,
    required this.selectedIcon,
    required this.unselectedIcon,
    required this.selectedColor,
    required this.count,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? selectedColor.withValues(alpha: 0.2)
              : AppColors.cyan.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? selectedColor.withValues(alpha: 0.5)
                : AppColors.ink.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            isLoading
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isSelected ? selectedColor : AppColors.ink,
                    ),
                  )
                : Icon(
                    isSelected ? selectedIcon : unselectedIcon,
                    color: isSelected ? selectedColor : AppColors.ink,
                    size: 18,
                  ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                color: isSelected ? selectedColor : AppColors.ink,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
