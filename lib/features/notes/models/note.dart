class Note {
  final String id;
  final String content;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String recipientId;
  final String recipientName;
  final String? recipientPhotoUrl;
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
    this.senderPhotoUrl,
    required this.recipientId,
    required this.recipientName,
    this.recipientPhotoUrl,
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
      senderPhotoUrl: senderPhotoUrl,
      recipientId: recipientId,
      recipientName: recipientName,
      recipientPhotoUrl: recipientPhotoUrl,
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
    final sender = json['sender'] as Map<String, dynamic>?;
    final recipient = json['recipient'] as Map<String, dynamic>?;
    final reactions = json['reactions'] as List<dynamic>? ?? [];

    int loveCount = 0;
    int likeCount = 0;
    bool lovedByMe = false;
    bool likedByMe = false;
    String? currentUserReaction;

    for (final r in reactions) {
      if (r is! Map<String, dynamic>) continue;
      final type = r['type']?.toString() ?? '';
      final isCurrentUser = r['isCurrentUser'] == true;
      if (type == 'Love') {
        loveCount++;
        if (isCurrentUser) lovedByMe = true;
      } else if (type == 'Ahaha') {
        likeCount++;
        if (isCurrentUser) likedByMe = true;
      }
      if (isCurrentUser && currentUserReaction == null) {
        currentUserReaction = type;
      }
    }

    return Note(
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      senderId: sender?['id']?.toString() ?? '',
      senderName: sender?['username']?.toString() ?? '',
      senderPhotoUrl: sender?['photoUrl']?.toString(),
      recipientId: recipient?['id']?.toString() ?? '',
      recipientName: recipient?['username']?.toString() ?? '',
      recipientPhotoUrl: recipient?['photoUrl']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
      canDelete: json['canDelete'] as bool?,
      isOwnedByCurrentUser: json['isOwnedByCurrentUser'] as bool?,
      isCreatedByCurrentUser: json['isCreatedByCurrentUser'] as bool?,
      likeCount: likeCount,
      loveCount: loveCount,
      likedByMe: likedByMe,
      lovedByMe: lovedByMe,
      currentUserReaction: currentUserReaction,
      rawJson: json,
    );
  }
}
