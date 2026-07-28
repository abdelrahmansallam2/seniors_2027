class ProfileUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String description;
  final String gender;
  final String? photoUrl;
  final int? points;
  final String? status;
  final String? favoriteSongEmbedUrl;

  const ProfileUser({
    required this.id,
    required this.name,
    this.email = '',
    this.role = '',
    this.description = '',
    this.gender = '',
    this.photoUrl,
    this.points,
    this.status,
    this.favoriteSongEmbedUrl,
  });

  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    return ProfileUser(
      id: (json['id'] as num?)?.toString() ?? json['id'] as String? ?? '',
      name: json['username'] as String? ?? json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      description: json['description'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      points: (json['points'] as num?)?.toInt(),
      status: json['status'] as String?,
      favoriteSongEmbedUrl: json['favoriteSongEmbedUrl'] as String?,
    );
  }
}

class SpotifyTrackInfo {
  final String trackId;

  const SpotifyTrackInfo({required this.trackId});

  static SpotifyTrackInfo? fromUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) return null;
    if (!uri.host.contains('spotify.com')) return null;

    final segments = uri.pathSegments;
    final clean = segments.where((s) => s != 'embed').toList();
    if (clean.length != 2 || clean[0] != 'track') return null;

    final trackId = clean[1];
    if (trackId.isEmpty) return null;

    return SpotifyTrackInfo(trackId: trackId);
  }

  String toEmbedUrl() => 'https://open.spotify.com/embed/track/$trackId';

  String toOpenUrl() => 'https://open.spotify.com/track/$trackId';
}
