import 'package:seniors_27/features/dashboard/models/poll_option.dart';

enum AnnouncementType {
  normalAnnouncement,
  challengePoll,
  poll,
  event,
  memoryHighlight,
}

class Announcement {
  const Announcement({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.date,
    required this.author,
    this.isSpotlight = false,
    this.pollTitle,
    this.options = const [],
  });

  final String id;
  final AnnouncementType type;
  final String title;
  final String description;
  final String date;
  final String author;
  final bool isSpotlight;
  final String? pollTitle;
  final List<PollOption> options;

  bool get hasPoll =>
      type == AnnouncementType.challengePoll || type == AnnouncementType.poll;

  bool get hasOptions => options.isNotEmpty;

  factory Announcement.fromJson(Map<String, dynamic> json) {
    final typeValue = json['type'] as String? ?? 'normal_announcement';

    return Announcement(
      id: json['id'] as String? ?? '',
      type: AnnouncementTypeX.fromApi(typeValue),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      date: json['date'] as String? ?? '',
      author: json['author'] as String? ?? 'admin',
      isSpotlight: json['isSpotlight'] as bool? ?? false,
      pollTitle: json['pollTitle'] as String?,
      options: (json['options'] as List<dynamic>? ?? [])
          .map((item) => PollOption.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.apiValue,
      'title': title,
      'description': description,
      'date': date,
      'author': author,
      'isSpotlight': isSpotlight,
      'pollTitle': pollTitle,
      'options': options.map((option) => option.toJson()).toList(),
    };
  }
}

extension AnnouncementTypeX on AnnouncementType {
  String get apiValue {
    switch (this) {
      case AnnouncementType.normalAnnouncement:
        return 'normal_announcement';
      case AnnouncementType.challengePoll:
        return 'challenge_poll';
      case AnnouncementType.poll:
        return 'poll';
      case AnnouncementType.event:
        return 'event';
      case AnnouncementType.memoryHighlight:
        return 'memory_highlight';
    }
  }

  static AnnouncementType fromApi(String value) {
    switch (value) {
      case 'challenge_poll':
        return AnnouncementType.challengePoll;
      case 'poll':
        return AnnouncementType.poll;
      case 'event':
        return AnnouncementType.event;
      case 'memory_highlight':
        return AnnouncementType.memoryHighlight;
      case 'normal_announcement':
      default:
        return AnnouncementType.normalAnnouncement;
    }
  }
}