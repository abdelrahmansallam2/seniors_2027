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
    );
  }
}
