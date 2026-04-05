class SiteCategory {
  final int id;
  final String name;
  final String? nameAr;
  final String? description;
  final String? icon;
  final String? color;
  final int? parentId;
  final int displayOrder;
  final int activeSitesCount;
  final List<SiteCategory> children;

  const SiteCategory({
    required this.id,
    required this.name,
    this.nameAr,
    this.description,
    this.icon,
    this.color,
    this.parentId,
    this.displayOrder = 0,
    this.activeSitesCount = 0,
    this.children = const <SiteCategory>[],
  });

  bool get isTopLevel => parentId == null;

  factory SiteCategory.fromJson(Map<String, dynamic> json) {
    int? parseNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse('$value');
    }

    int parseInt(dynamic value, {int fallback = 0}) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse('$value') ?? fallback;
    }

    return SiteCategory(
      id: parseInt(json['id']),
      name: json['name'] as String? ?? '',
      nameAr: json['name_ar'] as String?,
      description: json['description'] as String?,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      parentId: parseNullableInt(json['parent_id']),
      displayOrder: parseInt(json['display_order']),
      activeSitesCount: parseInt(json['active_sites_count']),
      children: (json['children'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<Map>()
          .map(
            (item) => SiteCategory.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(),
    );
  }
}
