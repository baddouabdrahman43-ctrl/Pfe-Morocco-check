class ProfessionalSite {
  final String id;
  final String name;
  final String description;
  final String nameAr;
  final String descriptionAr;
  final String categoryName;
  final int? categoryId;
  final String subcategory;
  final double latitude;
  final double longitude;
  final String address;
  final String city;
  final String region;
  final String postalCode;
  final String country;
  final String phoneNumber;
  final String email;
  final String website;
  final String? priceRange;
  final bool acceptsCardPayment;
  final bool hasWifi;
  final bool hasParking;
  final bool isAccessible;
  final String status;
  final String verificationStatus;
  final String moderationNotes;
  final int? moderatedBy;
  final String moderatedByName;
  final int? ownerId;
  final bool isProfessionalClaimed;
  final String? subscriptionPlan;
  final double rating;
  final int totalReviews;
  final int freshnessScore;
  final int viewsCount;
  final int favoritesCount;
  final String coverPhoto;
  final List<String> amenities;
  final String ownerName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? moderatedAt;
  final DateTime? lastVerifiedAt;
  final DateTime? lastUpdatedAt;

  const ProfessionalSite({
    required this.id,
    required this.name,
    required this.description,
    required this.nameAr,
    required this.descriptionAr,
    required this.categoryName,
    required this.categoryId,
    required this.subcategory,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.city,
    required this.region,
    required this.postalCode,
    required this.country,
    required this.phoneNumber,
    required this.email,
    required this.website,
    required this.priceRange,
    required this.acceptsCardPayment,
    required this.hasWifi,
    required this.hasParking,
    required this.isAccessible,
    required this.status,
    required this.verificationStatus,
    required this.moderationNotes,
    required this.moderatedBy,
    required this.moderatedByName,
    required this.ownerId,
    required this.isProfessionalClaimed,
    required this.subscriptionPlan,
    required this.rating,
    required this.totalReviews,
    required this.freshnessScore,
    required this.viewsCount,
    required this.favoritesCount,
    required this.coverPhoto,
    required this.amenities,
    required this.ownerName,
    required this.createdAt,
    required this.updatedAt,
    required this.moderatedAt,
    required this.lastVerifiedAt,
    required this.lastUpdatedAt,
  });

  factory ProfessionalSite.fromJson(Map<String, dynamic> json) {
    int? parseNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse('$value');
    }

    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse('$value') ?? 0;
    }

    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      final text = '$value'.toLowerCase();
      return text == 'true' || text == '1';
    }

    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse('$value') ?? 0;
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      return DateTime.tryParse('$value');
    }

    final ownerFirstName = json['owner_first_name'] as String? ?? '';
    final ownerLastName = json['owner_last_name'] as String? ?? '';
    final ownerName = '$ownerFirstName $ownerLastName'.trim();
    final moderatorFirstName = json['moderator_first_name'] as String? ?? '';
    final moderatorLastName = json['moderator_last_name'] as String? ?? '';
    final moderatedByName = '$moderatorFirstName $moderatorLastName'.trim();
    List<String> parseAmenities(dynamic value) {
      if (value is List) {
        return value
            .map((item) => '$item'.trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }

      if (value is String && value.trim().isNotEmpty) {
        final trimmed = value.trim();
        if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
          final raw = trimmed.substring(1, trimmed.length - 1);
          return raw
              .split(',')
              .map((item) => item.replaceAll('"', '').trim())
              .where((item) => item.isNotEmpty)
              .toList();
        }

        return trimmed
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }

      return const <String>[];
    }

    return ProfessionalSite(
      id: '${json['id']}',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      nameAr: json['name_ar'] as String? ?? '',
      descriptionAr: json['description_ar'] as String? ?? '',
      categoryName:
          json['category_name'] as String? ?? json['category'] as String? ?? '',
      categoryId: parseNullableInt(json['category_id']),
      subcategory: json['subcategory'] as String? ?? '',
      latitude: parseDouble(json['latitude']),
      longitude: parseDouble(json['longitude']),
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      region: json['region'] as String? ?? '',
      postalCode: json['postal_code'] as String? ?? '',
      country: json['country'] as String? ?? 'MA',
      phoneNumber: json['phone_number'] as String? ?? '',
      email: json['email'] as String? ?? '',
      website: json['website'] as String? ?? '',
      priceRange: json['price_range'] as String?,
      acceptsCardPayment: parseBool(json['accepts_card_payment']),
      hasWifi: parseBool(json['has_wifi']),
      hasParking: parseBool(json['has_parking']),
      isAccessible: parseBool(json['is_accessible']),
      status: json['status'] as String? ?? 'PENDING_REVIEW',
      verificationStatus: json['verification_status'] as String? ?? 'PENDING',
      moderationNotes: json['moderation_notes'] as String? ?? '',
      moderatedBy: parseNullableInt(json['moderated_by']),
      moderatedByName: moderatedByName,
      ownerId: parseNullableInt(json['owner_id']),
      isProfessionalClaimed: parseBool(json['is_professional_claimed']),
      subscriptionPlan: json['subscription_plan'] as String?,
      rating: parseDouble(json['average_rating'] ?? json['rating']),
      totalReviews: parseInt(json['total_reviews']),
      freshnessScore: parseInt(
        json['freshness_score'] ?? json['freshnessScore'],
      ),
      viewsCount: parseInt(json['views_count']),
      favoritesCount: parseInt(json['favorites_count']),
      coverPhoto: json['cover_photo'] as String? ?? '',
      amenities: parseAmenities(json['amenities']),
      ownerName: ownerName,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      moderatedAt: parseDate(json['moderated_at']),
      lastVerifiedAt: parseDate(json['last_verified_at']),
      lastUpdatedAt: parseDate(json['last_updated_at']),
    );
  }
}
