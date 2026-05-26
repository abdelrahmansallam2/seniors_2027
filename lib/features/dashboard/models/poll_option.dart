class PollOption {
  const PollOption({
    required this.id,
    required this.title,
    required this.votes,
    required this.percentage,
    this.isSelected = false,
  });

  final String id;
  final String title;
  final int votes;

  /// Value from 0.0 to 1.0
  final double percentage;

  final bool isSelected;

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      votes: json['votes'] as int? ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      isSelected: json['isSelected'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'votes': votes,
      'percentage': percentage,
      'isSelected': isSelected,
    };
  }
}
