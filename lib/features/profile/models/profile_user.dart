class SocialLink {
  final String label;
  final String url;

  const SocialLink({required this.label, this.url = ''});
}

class FavoriteSong {
  final String title;
  final String artist;

  const FavoriteSong({required this.title, required this.artist});
}

class ProfileUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String description;
  final String gender;
  final String? photoUrl;
  final List<SocialLink> links;
  final FavoriteSong? song;
  final int memoriesCount;

  const ProfileUser({
    required this.id,
    required this.name,
    this.email = '',
    this.role = '',
    this.description = '',
    this.gender = '',
    this.photoUrl,
    this.links = const [],
    this.song,
    this.memoriesCount = 0,
  });

  factory ProfileUser.fromJson(Map<String, dynamic> json) {
    final linksData = json['links'] as List<dynamic>?;
    final songData = json['song'] as Map<String, dynamic>?;

    return ProfileUser(
      id: (json['id'] as num?)?.toString() ?? '',
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      description: json['description'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      links: linksData != null
          ? linksData
                .map(
                  (e) => SocialLink(
                    label:
                        (e as Map<String, dynamic>)['label'] as String? ?? '',
                    url: e['url'] as String? ?? '',
                  ),
                )
                .toList()
          : const [],
      song: songData != null
          ? FavoriteSong(
              title: songData['title'] as String? ?? '',
              artist: songData['artist'] as String? ?? '',
            )
          : null,
      memoriesCount: (json['memoriesCount'] as num?)?.toInt() ?? 0,
    );
  }
}

const mockProfileUser = ProfileUser(
  id: '1',
  name: 'BILLY J.',
  email: 'billy@seniors2027.edu',
  role: 'Lead Developer',
  description: 'When life gets loud, turn the music up.',
  gender: 'Male',
  links: [
    SocialLink(label: 'IG'),
    SocialLink(label: 'LN'),
    SocialLink(label: 'GH'),
    SocialLink(label: 'PF'),
  ],
  song: FavoriteSong(title: 'Blinding Lights', artist: 'The Weeknd'),
  memoriesCount: 42,
);
