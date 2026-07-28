import 'package:flutter/material.dart';
import 'package:seniors_27/core/constants/app_colors.dart';
import 'package:seniors_27/features/profile/models/profile_gallery_photo.dart';

class ProfileGalleryCard extends StatelessWidget {
  const ProfileGalleryCard({
    required this.photos,
    required this.onOpenGallery,
    required this.onRetry,
    this.isLoading = false,
    this.errorMessage,
    super.key,
  });

  final List<ProfileGalleryPhoto> photos;
  final VoidCallback onOpenGallery;
  final VoidCallback onRetry;
  final bool isLoading;
  final String? errorMessage;

  int get _previewCount => photos.length.clamp(0, 4);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading || errorMessage != null ? null : onOpenGallery,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.paper,
          border: Border.all(color: AppColors.ink, width: 3),
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            BoxShadow(
              color: AppColors.ink,
              offset: Offset(6, 7),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTopRow(),
            const SizedBox(height: 16),
            _buildCenter(),
            const SizedBox(height: 12),
            _buildBottomRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Archive Stack',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: AppColors.ink,
          ),
        ),
        GestureDetector(
          onTap: isLoading || errorMessage != null ? null : onOpenGallery,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.cyan,
              border: Border.all(color: AppColors.ink, width: 2),
            ),
            child: const Text(
              'OPEN BOOK',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
                color: AppColors.ink,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCenter() {
    if (isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'Loading gallery...',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    if (errorMessage != null) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Could not load gallery.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onRetry,
                child: const Text(
                  'TAP TO RETRY',
                  style: TextStyle(
                    color: AppColors.orange,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (photos.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text(
            'No photos yet.',
            style: TextStyle(
              color: AppColors.muted,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    final int count = _previewCount;

    return SizedBox(
      height: 110,
      child: Center(
        child: SizedBox(
          width: 140,
          height: 110,
          child: Stack(
            alignment: Alignment.center,
            children: List.generate(count, (i) {
              final photo = photos[i];
              final int behindCount = count - 1 - i;
              final double dx = behindCount * -14.0;
              final double dy = behindCount * -6.0;
              final double rotation = behindCount.isEven ? 0.05 : -0.05;
              final double scale = 1.0 - behindCount * 0.03;

              return Transform.rotate(
                angle: rotation,
                child: Transform.scale(
                  scale: scale.clamp(0.8, 1.0),
                  child: Transform.translate(
                    offset: Offset(dx, dy),
                    child: Container(
                      width: 80,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        border: Border.all(color: AppColors.ink, width: 2),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.ink,
                            offset: Offset(2, 2),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3),
                      child: ClipRect(
                        child: Image.network(
                          photo.photoUrl ?? '',
                          width: 74,
                          height: 94,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            color: AppColors.cyan,
                            alignment: Alignment.center,
                            child: const Text(
                              'PHOTO',
                              style: TextStyle(
                                color: AppColors.muted,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Tap to open the archive.',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.muted,
          ),
        ),
        if (!isLoading && errorMessage == null)
          Text(
            '${photos.length} ${photos.length == 1 ? 'photo' : 'photos'}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
      ],
    );
  }
}
