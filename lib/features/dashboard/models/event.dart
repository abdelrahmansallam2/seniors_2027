class Event {
  const Event({
    required this.id,
    required this.title,
    this.eventDate,
    this.location,
    this.details,
    this.photoUrl,
    this.createdByUsername,
    this.createdAt,
  });

  final String id;
  final String title;
  final DateTime? eventDate;
  final String? location;
  final String? details;
  final String? photoUrl;
  final String? createdByUsername;
  final DateTime? createdAt;

  static String? _clean(dynamic value) {
    final s = value?.toString().trim();
    return (s != null && s.isNotEmpty) ? s : null;
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    final rawEventDate = json['eventDate']?.toString();
    final rawCreatedAt = json['createdAt']?.toString();

    return Event(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString().trim() ?? '',
      eventDate: rawEventDate != null ? DateTime.tryParse(rawEventDate) : null,
      location: _clean(json['location']),
      details: _clean(json['details']),
      photoUrl: _clean(json['photoUrl']),
      createdByUsername: _clean(json['createdByUsername']),
      createdAt: rawCreatedAt != null ? DateTime.tryParse(rawCreatedAt) : null,
    );
  }
}
