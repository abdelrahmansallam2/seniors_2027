class Memory {
  final String id;
  final String name;
  final String date;
  final String? imageUrl;
  final String? description;

  const Memory({
    required this.id,
    required this.name,
    required this.date,
    this.imageUrl,
    this.description,
  });

  factory Memory.fromJson(Map<String, dynamic> json) {
    return Memory(
      id: (json['id'] as num?)?.toString() ?? '',
      name: json['name'] as String? ?? '',
      date: json['date'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      description: json['description'] as String?,
    );
  }
}
