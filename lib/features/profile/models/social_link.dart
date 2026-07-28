enum SocialPlatform {
  instagram,
  facebook,
  linkedin,
  spotify,
  github,
  twitter,
  tiktok,
  youtube,
  snapchat,
  discord,
  generic,
}

class SocialLink {
  final String url;
  final SocialPlatform platform;

  const SocialLink({required this.url, required this.platform});

  factory SocialLink.fromUrl(String url) {
    final normalized = url.trim();
    final lower = normalized.toLowerCase();
    return SocialLink(url: normalized, platform: _detectPlatform(lower));
  }

  static SocialPlatform _detectPlatform(String url) {
    if (url.contains('instagram.com')) return SocialPlatform.instagram;
    if (url.contains('facebook.com')) return SocialPlatform.facebook;
    if (url.contains('linkedin.com')) return SocialPlatform.linkedin;
    if (url.contains('spotify.com')) return SocialPlatform.spotify;
    if (url.contains('github.com')) return SocialPlatform.github;
    if (url.contains('x.com') || url.contains('twitter.com')) {
      return SocialPlatform.twitter;
    }
    if (url.contains('tiktok.com')) return SocialPlatform.tiktok;
    if (url.contains('youtube.com')) return SocialPlatform.youtube;
    if (url.contains('snapchat.com')) return SocialPlatform.snapchat;
    if (url.contains('discord.com') || url.contains('discordapp.com')) {
      return SocialPlatform.discord;
    }
    return SocialPlatform.generic;
  }

  static String normalizeUrl(String input) {
    var url = input.trim();
    if (url.isEmpty) return url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    return url;
  }
}
