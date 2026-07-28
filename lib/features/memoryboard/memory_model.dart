class Memory {
  final String id;
  final String name;
  final String date;
  final String? imageUrl;
  final String? description;

  static const _baseUrl = 'https://sneiors2027.runasp.net';

  const Memory({
    required this.id,
    required this.name,
    required this.date,
    this.imageUrl,
    this.description,
  });

  factory Memory.fromJson(Map<String, dynamic> json) {
    final rawUrl =
        json['imageUrl'] as String? ??
        json['photoUrl'] as String? ??
        json['url'] as String? ??
        json['fileUrl'] as String? ??
        json['imagePath'] as String? ??
        json['path'] as String?;

    String? resolvedUrl;
    if (rawUrl != null && rawUrl.isNotEmpty) {
      if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
        resolvedUrl = rawUrl;
      } else {
        resolvedUrl = '$_baseUrl$rawUrl';
      }
    }

    return Memory(
      id: (json['id'] as num?)?.toString() ?? json['id'] as String? ?? '',
      name: json['username'] as String? ?? json['name'] as String? ?? '',
      date:
          json['sortDateUtc'] as String? ??
          json['createdAt'] as String? ??
          json['date'] as String? ??
          '',
      imageUrl: resolvedUrl,
      description: json['description'] as String?,
    );
  }
}
