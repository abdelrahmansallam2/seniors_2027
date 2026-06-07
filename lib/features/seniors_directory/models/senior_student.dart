class SeniorStudent {
  final String id;
  final String name;
  final String role;
  final String department;
  final List<String> tags;
  final int points;
  final int memoriesCount;

  const SeniorStudent({
    required this.id,
    required this.name,
    this.role = 'Senior Student',
    this.department = 'DEV',
    this.tags = const [],
    this.points = 0,
    this.memoriesCount = 0,
  });

  factory SeniorStudent.fromJson(Map<String, dynamic> json) {
    return SeniorStudent(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? 'Senior Student',
      department: json['department'] as String? ?? 'DEV',
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          const [],
      points: (json['points'] as num?)?.toInt() ?? 0,
      memoriesCount: (json['memoriesCount'] as num?)?.toInt() ?? 0,
    );
  }
}
