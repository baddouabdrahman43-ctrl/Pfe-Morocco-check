class LeaderboardEntry {
  final String id;
  final String firstName;
  final String lastName;
  final String? profilePicture;
  final int points;
  final int level;
  final String rank;
  final int checkinsCount;
  final int reviewsCount;

  const LeaderboardEntry({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.profilePicture,
    required this.points,
    required this.level,
    required this.rank,
    required this.checkinsCount,
    required this.reviewsCount,
  });

  String get displayName {
    final fullName = '$firstName $lastName'.trim();
    return fullName.isEmpty ? 'Utilisateur' : fullName;
  }

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse('$value') ?? fallback;
    }

    return LeaderboardEntry(
      id: '${json['id']}',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      profilePicture: json['profile_picture'] as String?,
      points: parseInt(json['points']),
      level: parseInt(json['level'], fallback: 1),
      rank: json['rank'] as String? ?? 'BRONZE',
      checkinsCount: parseInt(json['checkins_count']),
      reviewsCount: parseInt(json['reviews_count']),
    );
  }
}
