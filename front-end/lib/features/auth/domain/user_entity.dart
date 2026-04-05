class UserEntity {
  final int id;
  final String email;
  final String name;
  final String? avatar;
  final String level;
  final int points;
  final List<String> badges;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.avatar,
    this.level = 'Bronze',
    this.points = 0,
    this.badges = const <String>[],
    required this.createdAt,
  });

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      avatar: json['avatar'] as String?,
      level: json['level'] as String? ?? 'Bronze',
      points: json['points'] is int
          ? json['points'] as int
          : int.tryParse('${json['points']}') ?? 0,
      badges: (json['badges'] as List<dynamic>? ?? const <dynamic>[])
          .map((dynamic e) => e.toString())
          .toList(),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'email': email,
      'name': name,
      'avatar': avatar,
      'level': level,
      'points': points,
      'badges': badges,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  UserEntity copyWith({
    int? id,
    String? email,
    String? name,
    String? avatar,
    String? level,
    int? points,
    List<String>? badges,
    DateTime? createdAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      level: level ?? this.level,
      points: points ?? this.points,
      badges: badges ?? this.badges,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserEntity &&
        other.id == id &&
        other.email == email &&
        other.name == name &&
        other.avatar == avatar &&
        other.level == level &&
        other.points == points &&
        _listEquals(other.badges, badges) &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        email.hashCode ^
        name.hashCode ^
        avatar.hashCode ^
        level.hashCode ^
        points.hashCode ^
        badges.join('|').hashCode ^
        createdAt.hashCode;
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
