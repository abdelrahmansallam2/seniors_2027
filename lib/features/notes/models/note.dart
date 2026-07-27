import 'package:flutter/foundation.dart';

class Note {
  final String id;
  final String content;
  final String senderId;
  final String senderName;
  final String recipientId;
  final String recipientName;
  final String createdAt;
  final bool? canDelete;
  final bool? isOwnedByCurrentUser;
  final bool? isCreatedByCurrentUser;
  final int? likeCount;
  final int? loveCount;
  final bool likedByMe;
  final bool lovedByMe;
  final String? currentUserReaction;
  final Map<String, dynamic> rawJson;

  const Note({
    required this.id,
    required this.content,
    required this.senderId,
    required this.senderName,
    required this.recipientId,
    required this.recipientName,
    required this.createdAt,
    this.canDelete,
    this.isOwnedByCurrentUser,
    this.isCreatedByCurrentUser,
    this.likeCount,
    this.loveCount,
    this.likedByMe = false,
    this.lovedByMe = false,
    this.currentUserReaction,
    required this.rawJson,
  });

  Note copyWith({
    bool? likedByMe,
    bool? lovedByMe,
    int? likeCount,
    int? loveCount,
    String? currentUserReaction,
  }) {
    return Note(
      id: id,
      content: content,
      senderId: senderId,
      senderName: senderName,
      recipientId: recipientId,
      recipientName: recipientName,
      createdAt: createdAt,
      canDelete: canDelete,
      isOwnedByCurrentUser: isOwnedByCurrentUser,
      isCreatedByCurrentUser: isCreatedByCurrentUser,
      likeCount: likeCount ?? this.likeCount,
      loveCount: loveCount ?? this.loveCount,
      likedByMe: likedByMe ?? this.likedByMe,
      lovedByMe: lovedByMe ?? this.lovedByMe,
      currentUserReaction: currentUserReaction ?? this.currentUserReaction,
      rawJson: rawJson,
    );
  }

  factory Note.fromJson(Map<String, dynamic> json) {
    debugPrint('[Notes] item keys: ${json.keys.toList()}');

    final Map<String, dynamic> safe = {};
    for (final k in json.keys) {
      final kLower = k.toString().toLowerCase();
      if (kLower.contains('token') ||
          kLower.contains('password') ||
          kLower.contains('otp') ||
          kLower.contains('secret') ||
          kLower.contains('pin')) {
        safe[k] = '***';
      } else {
        safe[k] = json[k];
      }
    }
    debugPrint('[Notes] item sample: $safe');

    final reaction = _str(
      json,
      'currentUserReaction',
      'userReaction',
      'reactionType',
      'myReaction',
    );

    final bool detectedLiked =
        json['likedByMe'] as bool? ??
        json['isLikedByMe'] as bool? ??
        json['hasLiked'] as bool? ??
        (reaction.isNotEmpty && reaction.toLowerCase() == 'like');

    final bool detectedLoved =
        json['lovedByMe'] as bool? ??
        json['isLovedByMe'] as bool? ??
        json['hasLoved'] as bool? ??
        (reaction.isNotEmpty && reaction.toLowerCase() == 'love');

    return Note(
      id: _str(json, 'id', 'noteId', 'Id'),
      content: _str(json, 'content', 'message', 'text', 'body'),
      senderId: _str(
        json,
        'senderId',
        'authorId',
        'createdBy',
        'userId',
        'fromUserId',
      ),
      senderName: _str(
        json,
        'senderName',
        'senderUsername',
        'authorName',
        'authorUsername',
        'createdByName',
        'username',
        'fromUserName',
      ),
      recipientId: _str(json, 'recipientId', 'receiverId', 'toUserId'),
      recipientName: _str(
        json,
        'recipientName',
        'recipientUsername',
        'receiverName',
        'toUserName',
      ),
      createdAt: _str(
        json,
        'createdAt',
        'createdDate',
        'date',
        'timestamp',
        'sentAt',
      ),
      canDelete: json['canDelete'] as bool?,
      isOwnedByCurrentUser: json['isOwnedByCurrentUser'] as bool?,
      isCreatedByCurrentUser: json['isCreatedByCurrentUser'] as bool?,
      likeCount: _parseInt(
        json['likeCount'],
        json['likesCount'],
        json['like_count'],
      ),
      loveCount: _parseInt(
        json['loveCount'],
        json['lovesCount'],
        json['love_count'],
      ),
      likedByMe: detectedLiked,
      lovedByMe: detectedLoved,
      currentUserReaction: reaction.isNotEmpty ? reaction : null,
      rawJson: json,
    );
  }

  static String _str(
    Map<String, dynamic> json, [
    String? a,
    String? b,
    String? c,
    String? d,
    String? e,
    String? f,
    String? g,
  ]) {
    for (final key in [a, b, c, d, e, f, g]) {
      if (key != null) {
        final val = json[key];
        if (val != null && val.toString().isNotEmpty) return val.toString();
      }
    }
    return '';
  }

  static int? _parseInt(dynamic a, [dynamic b, dynamic c]) {
    for (final val in [a, b, c]) {
      if (val is num) return val.toInt();
      if (val is String) {
        final parsed = int.tryParse(val);
        if (parsed != null) return parsed;
      }
    }
    return null;
  }
}
