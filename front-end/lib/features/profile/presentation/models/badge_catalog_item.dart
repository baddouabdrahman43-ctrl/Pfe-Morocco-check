class BadgeCatalogItem {
  final String id;
  final String name;
  final String description;
  final String type;
  final String category;
  final String rarity;
  final int requiredCheckins;
  final int requiredReviews;
  final int requiredPoints;
  final int requiredLevel;
  final int pointsReward;
  final int totalAwarded;
  final String color;

  const BadgeCatalogItem({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.category,
    required this.rarity,
    required this.requiredCheckins,
    required this.requiredReviews,
    required this.requiredPoints,
    required this.requiredLevel,
    required this.pointsReward,
    required this.totalAwarded,
    required this.color,
  });

  factory BadgeCatalogItem.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse('$value') ?? 0;
    }

    return BadgeCatalogItem(
      id: '${json['id']}',
      name: json['name'] as String? ?? 'Badge',
      description: json['description'] as String? ?? '',
      type: json['type'] as String? ?? 'UNKNOWN',
      category: json['category'] as String? ?? 'GENERAL',
      rarity: json['rarity'] as String? ?? 'COMMON',
      requiredCheckins: parseInt(json['required_checkins']),
      requiredReviews: parseInt(json['required_reviews']),
      requiredPoints: parseInt(json['required_points']),
      requiredLevel: parseInt(json['required_level']),
      pointsReward: parseInt(json['points_reward']),
      totalAwarded: parseInt(json['total_awarded']),
      color: json['color'] as String? ?? '#2563EB',
    );
  }
}
