class Event {
  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
  });

  final String id;
  final String title;
  final String description;
  final String date;

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      date: json['date'] as String? ?? '',
    );
  }
}
