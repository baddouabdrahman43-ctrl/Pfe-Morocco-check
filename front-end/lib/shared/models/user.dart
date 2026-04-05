class User {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final String? nationality;
  final String? bio;
  final String? role;
  final String? status;
  final String? rank;
  final String? profilePicture;
  final int points;
  final int level;
  final int checkinsCount;
  final int reviewsCount;
  final int badgeCount;
  final String? token;
  final String? refreshToken;

  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    this.nationality,
    this.bio,
    this.role,
    this.status,
    this.rank,
    this.profilePicture,
    this.points = 0,
    this.level = 1,
    this.checkinsCount = 0,
    this.reviewsCount = 0,
    this.badgeCount = 0,
    this.token,
    this.refreshToken,
  });

  String get name => '$firstName $lastName'.trim();

  factory User.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];

    return User(
      id: rawId is int ? rawId : int.tryParse('${json['id']}') ?? 0,
      firstName:
          json['first_name'] as String? ?? json['firstName'] as String? ?? '',
      lastName:
          json['last_name'] as String? ?? json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phone_number'] as String?,
      nationality: json['nationality'] as String?,
      bio: json['bio'] as String?,
      role: json['role'] as String?,
      status: json['status'] as String?,
      rank: json['rank'] as String?,
      profilePicture:
          json['profile_picture'] as String? ??
          json['profilePicture'] as String?,
      points: _readInt(json, 'points'),
      level: _readInt(json, 'level', fallback: 1),
      checkinsCount: _readInt(json, 'checkins_count'),
      reviewsCount: _readInt(json, 'reviews_count'),
      badgeCount: _readBadgeCount(json),
      token: json['token'] as String?,
      refreshToken: json['refresh_token'] as String?,
    );
  }

  static int _readInt(
    Map<String, dynamic> json,
    String key, {
    int fallback = 0,
  }) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }

  static int _readBadgeCount(Map<String, dynamic> json) {
    final rawBadges = json['badges'];
    if (rawBadges is List) {
      return rawBadges.length;
    }
    return _readInt(json, 'badges_count');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (nationality != null) 'nationality': nationality,
      if (bio != null) 'bio': bio,
      if (role != null) 'role': role,
      if (status != null) 'status': status,
      if (rank != null) 'rank': rank,
      if (profilePicture != null) 'profile_picture': profilePicture,
      'points': points,
      'level': level,
      'checkins_count': checkinsCount,
      'reviews_count': reviewsCount,
      'badges_count': badgeCount,
      if (token != null) 'token': token,
      if (refreshToken != null) 'refresh_token': refreshToken,
    };
  }

  User copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? nationality,
    String? bio,
    String? role,
    String? status,
    String? rank,
    String? profilePicture,
    int? points,
    int? level,
    int? checkinsCount,
    int? reviewsCount,
    int? badgeCount,
    String? token,
    String? refreshToken,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      nationality: nationality ?? this.nationality,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      status: status ?? this.status,
      rank: rank ?? this.rank,
      profilePicture: profilePicture ?? this.profilePicture,
      points: points ?? this.points,
      level: level ?? this.level,
      checkinsCount: checkinsCount ?? this.checkinsCount,
      reviewsCount: reviewsCount ?? this.reviewsCount,
      badgeCount: badgeCount ?? this.badgeCount,
      token: token ?? this.token,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, name: $name, email: $email, role: $role, token: ${token != null ? "***" : null})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is User &&
        other.id == id &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.email == email &&
        other.phoneNumber == phoneNumber &&
        other.nationality == nationality &&
        other.bio == bio &&
        other.role == role &&
        other.status == status &&
        other.rank == rank &&
        other.profilePicture == profilePicture &&
        other.points == points &&
        other.level == level &&
        other.checkinsCount == checkinsCount &&
        other.reviewsCount == reviewsCount &&
        other.badgeCount == badgeCount &&
        other.token == token &&
        other.refreshToken == refreshToken;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        firstName.hashCode ^
        lastName.hashCode ^
        email.hashCode ^
        phoneNumber.hashCode ^
        nationality.hashCode ^
        bio.hashCode ^
        role.hashCode ^
        status.hashCode ^
        rank.hashCode ^
        profilePicture.hashCode ^
        points.hashCode ^
        level.hashCode ^
        checkinsCount.hashCode ^
        reviewsCount.hashCode ^
        badgeCount.hashCode ^
        token.hashCode ^
        refreshToken.hashCode;
  }
}
