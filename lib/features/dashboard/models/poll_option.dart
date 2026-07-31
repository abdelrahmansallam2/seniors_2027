class PollVoter {
  const PollVoter({
    required this.username,
    this.photoUrl,
    required this.votedAt,
    required this.isCurrentUser,
  });

  final String username;
  final String? photoUrl;
  final String votedAt;
  final bool isCurrentUser;

  factory PollVoter.fromJson(Map<String, dynamic> json) {
    return PollVoter(
      username: json['username'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      votedAt: json['votedAt'] as String? ?? '',
      isCurrentUser: json['isCurrentUser'] as bool? ?? false,
    );
  }
}

class PollOption {
  const PollOption({
    required this.label,
    required this.voteCount,
    required this.voters,
  });

  final String label;
  final int voteCount;
  final List<PollVoter> voters;

  bool get isSelected => voters.any((v) => v.isCurrentUser);

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      label: json['label'] as String? ?? '',
      voteCount: json['voteCount'] as int? ?? 0,
      voters: (json['voters'] as List<dynamic>? ?? [])
          .map((v) => PollVoter.fromJson(v as Map<String, dynamic>))
          .toList(),
    );
  }
}

class Poll {
  const Poll({required this.title, required this.options});

  final String title;
  final List<PollOption> options;

  int get totalVotes => options.fold(0, (sum, o) => sum + o.voteCount);

  bool get hasOptions => options.isNotEmpty;

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      title: json['title'] as String? ?? '',
      options: (json['options'] as List<dynamic>? ?? [])
          .map((o) => PollOption.fromJson(o as Map<String, dynamic>))
          .toList(),
    );
  }
}
