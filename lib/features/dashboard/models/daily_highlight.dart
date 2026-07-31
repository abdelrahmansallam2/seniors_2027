import 'dart:math';
import 'dart:ui' as ui;

class DailyHighlight {
  final String id;
  final String? photoUrl;
  final String createdAt;
  final bool isOwnedByCurrentUser;
  final DailyHighlightUser? user;
  final List<DailyHighlightUser> mentionedUsers;
  final List<DailyHighlightReaction> reactions;
  final String? captionText;
  final double? captionYPercent;

  const DailyHighlight({
    required this.id,
    this.photoUrl,
    this.createdAt = '',
    this.isOwnedByCurrentUser = false,
    this.user,
    this.mentionedUsers = const [],
    this.reactions = const [],
    this.captionText,
    this.captionYPercent,
  });

  factory DailyHighlight.fromJson(Map<String, dynamic> json) {
    return DailyHighlight(
      id: (json['id'] as num?)?.toString() ?? json['id'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      createdAt: json['createdAt'] as String? ?? '',
      isOwnedByCurrentUser: json['isOwnedByCurrentUser'] as bool? ?? false,
      user: json['user'] != null
          ? DailyHighlightUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      mentionedUsers: json['mentionedUsers'] is List
          ? (json['mentionedUsers'] as List)
                .map(
                  (e) => DailyHighlightUser.fromJson(e as Map<String, dynamic>),
                )
                .toList()
          : [],
      reactions: json['reactions'] is List
          ? (json['reactions'] as List)
                .map(
                  (e) => DailyHighlightReaction.fromJson(
                    e as Map<String, dynamic>,
                  ),
                )
                .toList()
          : [],
      captionText: json['captionText']?.toString().trim(),
      captionYPercent: (json['captionYPercent'] as num?)?.toDouble(),
    );
  }
}

class DailyHighlightUser {
  final int id;
  final String username;
  final String? photoUrl;
  final String? gender;

  const DailyHighlightUser({
    this.id = 0,
    this.username = '',
    this.photoUrl,
    this.gender,
  });

  factory DailyHighlightUser.fromJson(Map<String, dynamic> json) {
    return DailyHighlightUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: json['username'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      gender: json['gender'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'photoUrl': photoUrl,
    'gender': gender,
  };
}

class DailyHighlightReaction {
  final int id;
  final String type;
  final String createdAt;
  final bool isCurrentUser;
  final DailyHighlightUser? user;

  const DailyHighlightReaction({
    this.id = 0,
    this.type = '',
    this.createdAt = '',
    this.isCurrentUser = false,
    this.user,
  });

  factory DailyHighlightReaction.fromJson(Map<String, dynamic> json) {
    return DailyHighlightReaction(
      id: (json['id'] as num?)?.toInt() ?? 0,
      type: json['type'] as String? ?? '',
      createdAt: json['createdAt'] as String? ?? '',
      isCurrentUser: json['isCurrentUser'] as bool? ?? false,
      user: json['user'] != null
          ? DailyHighlightUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

ui.Size fittedSize(ui.Size container, ui.Size image) {
  final scaleX = container.width / max(image.width, 1);
  final scaleY = container.height / max(image.height, 1);
  final scale = scaleX < scaleY ? scaleX : scaleY;
  return ui.Size(image.width * scale, image.height * scale);
}

ui.Offset fittedOffset(ui.Size container, ui.Size fitted) {
  return ui.Offset(
    (container.width - fitted.width) / 2,
    (container.height - fitted.height) / 2,
  );
}

ui.Rect fittedRect(ui.Size container, ui.Size image) {
  final f = fittedSize(container, image);
  final o = fittedOffset(container, f);
  return ui.Rect.fromLTWH(o.dx, o.dy, f.width, f.height);
}
