import 'package:seniors_27/features/dashboard/models/poll_option.dart';

class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    this.photoUrl,
    required this.createdByUsername,
    required this.createdAt,
    this.poll,
  });

  final String id;
  final String title;
  final String body;
  final String? photoUrl;
  final String createdByUsername;
  final String createdAt;
  final Poll? poll;

  bool get hasPoll => poll != null && poll!.hasOptions;

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: (json['id'] as num?)?.toString() ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      createdByUsername: json['createdByUsername'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      poll: json['poll'] != null
          ? Poll.fromJson(json['poll'] as Map<String, dynamic>)
          : null,
    );
  }
}
