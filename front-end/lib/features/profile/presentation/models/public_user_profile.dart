class PublicUserProfile {
  final String id;
  final String firstName;
  final String lastName;
  final String? profilePicture;
  final String? bio;
  final String rank;
  final int level;
  final int points;
  final int badgeCount;
  final int checkinsCount;
  final int reviewsCount;
  final DateTime? createdAt;

  const PublicUserProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.profilePicture,
    required this.bio,
    required this.rank,
    required this.level,
    required this.points,
    required this.badgeCount,
    required this.checkinsCount,
    required this.reviewsCount,
    required this.createdAt,
  });

  factory PublicUserProfile.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse('$value') ?? fallback;
    }

    return PublicUserProfile(
      id: '${json['id']}',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      profilePicture: json['profile_picture'] as String?,
      bio: json['bio'] as String?,
      rank: json['rank'] as String? ?? 'BRONZE',
      level: parseInt(json['level'], fallback: 1),
      points: parseInt(json['points']),
      badgeCount: parseInt(json['badges_count']),
      checkinsCount: parseInt(json['checkins_count']),
      reviewsCount: parseInt(json['reviews_count']),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  String get displayName {
    final fullName = '$firstName $lastName'.trim();
    return fullName.isEmpty ? 'Utilisateur' : fullName;
  }
}
