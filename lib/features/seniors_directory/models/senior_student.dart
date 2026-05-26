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
}
