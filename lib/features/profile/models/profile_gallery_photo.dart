import 'package:seniors_27/core/api/api_constants.dart';

class ProfileGalleryPhoto {
  final String id;
  final String? photoUrl;

  const ProfileGalleryPhoto({required this.id, this.photoUrl});

  factory ProfileGalleryPhoto.fromJson(Map<String, dynamic> json) {
    final rawUrl =
        json['photoUrl'] as String? ??
        json['imageUrl'] as String? ??
        json['url'] as String? ??
        json['fileUrl'] as String? ??
        json['path'] as String?;

    String? resolvedUrl;
    if (rawUrl != null && rawUrl.isNotEmpty) {
      if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
        resolvedUrl = rawUrl;
      } else {
        resolvedUrl = '${ApiConstants.baseUrl}$rawUrl';
      }
    }

    return ProfileGalleryPhoto(
      id: (json['id'] as num?)?.toString() ?? json['id'] as String? ?? '',
      photoUrl: resolvedUrl,
    );
  }
}
