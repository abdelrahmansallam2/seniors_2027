class DailyHighlight {
  final String id;
  final String? imageUrl;
  final String authorName;
  final String date;
  final String? description;
  final int reactions;

  const DailyHighlight({
    required this.id,
    this.imageUrl,
    this.authorName = '',
    this.date = '',
    this.description,
    this.reactions = 0,
  });

  factory DailyHighlight.fromJson(Map<String, dynamic> json) {
    return DailyHighlight(
      id: (json['id'] as num?)?.toString() ?? '',
      imageUrl: json['imageUrl'] as String?,
      authorName:
          json['authorName'] as String? ?? json['name'] as String? ?? '',
      date: json['date'] as String? ?? '',
      description: json['description'] as String?,
      reactions: (json['reactions'] as num?)?.toInt() ?? 0,
    );
  }
}
