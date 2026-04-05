import 'dart:convert';

class SiteOpeningHour {
  final String dayOfWeek;
  final String? opensAt;
  final String? closesAt;
  final bool isClosed;
  final bool is24Hours;
  final String notes;

  const SiteOpeningHour({
    required this.dayOfWeek,
    required this.opensAt,
    required this.closesAt,
    required this.isClosed,
    required this.is24Hours,
    required this.notes,
  });

  factory SiteOpeningHour.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      final text = '$value'.toLowerCase();
      return text == 'true' || text == '1';
    }

    return SiteOpeningHour(
      dayOfWeek: json['day_of_week'] as String? ?? '',
      opensAt: json['opens_at'] as String?,
      closesAt: json['closes_at'] as String?,
      isClosed: parseBool(json['is_closed']),
      is24Hours: parseBool(json['is_24_hours']),
      notes: json['notes'] as String? ?? '',
    );
  }
}

class Site {
  final String id;
  final String name;
  final String description;
  final int? categoryId;
  final int? subcategoryId;
  final String category;
  final String? subcategory;
  final String imageUrl;
  final String address;
  final String city;
  final String region;
  final double latitude;
  final double longitude;
  final double? distanceMeters;
  final int freshnessScore;
  final double rating;
  final String phoneNumber;
  final String website;
  final String? priceRange;
  final bool acceptsCardPayment;
  final bool hasWifi;
  final bool hasParking;
  final bool isAccessible;
  final String verificationStatus;
  final int totalReviews;
  final int favoritesCount;
  final int? ownerId;
  final bool isProfessionalClaimed;
  final int viewsCount;
  final List<String> amenities;
  final List<String> previewPhotos;
  final List<SiteOpeningHour> openingHours;

  const Site({
    required this.id,
    required this.name,
    required this.description,
    this.categoryId,
    this.subcategoryId,
    required this.category,
    this.subcategory,
    required this.imageUrl,
    required this.address,
    required this.city,
    required this.region,
    required this.latitude,
    required this.longitude,
    this.distanceMeters,
    required this.freshnessScore,
    required this.rating,
    this.phoneNumber = '',
    this.website = '',
    this.priceRange,
    this.acceptsCardPayment = false,
    this.hasWifi = false,
    this.hasParking = false,
    this.isAccessible = false,
    this.verificationStatus = 'PENDING',
    this.totalReviews = 0,
    this.favoritesCount = 0,
    this.ownerId,
    this.isProfessionalClaimed = false,
    this.viewsCount = 0,
    this.amenities = const <String>[],
    this.previewPhotos = const <String>[],
    this.openingHours = const <SiteOpeningHour>[],
  });

  factory Site.fromJson(Map<String, dynamic> json) {
    int? parseNullableInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse('$value');
    }

    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse('$value') ?? 0;
    }

    double? parseNullableDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is num) return value.toDouble();
      return double.tryParse('$value');
    }

    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      final text = '$value'.toLowerCase();
      return text == 'true' || text == '1';
    }

    List<String> parseAmenities(dynamic value) {
      if (value is List) {
        return value
            .map((item) => '$item'.trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }

      if (value is String && value.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is List) {
            return decoded
                .map((item) => '$item'.trim())
                .where((item) => item.isNotEmpty)
                .toList();
          }
        } catch (_) {
          return value
              .split(',')
              .map((item) => item.trim())
              .where((item) => item.isNotEmpty)
              .toList();
        }
      }

      return const <String>[];
    }

    List<SiteOpeningHour> parseOpeningHours(dynamic value) {
      if (value is! List) return const <SiteOpeningHour>[];
      return value
          .whereType<Map>()
          .map(
            (item) => SiteOpeningHour.fromJson(
              item.map((key, data) => MapEntry(key.toString(), data)),
            ),
          )
          .toList();
    }

    List<String> parsePreviewPhotos(dynamic value) {
      if (value is! List) return const <String>[];

      return value
          .map((item) {
            if (item is Map) {
              final mapped = item.map(
                (key, data) => MapEntry(key.toString(), data),
              );
              return mapped['thumbnail_url'] as String? ??
                  mapped['url'] as String? ??
                  '';
            }
            return '$item';
          })
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    final dynamic rawLatitude = json['latitude'];
    final dynamic rawLongitude = json['longitude'];
    final dynamic rawFreshnessScore =
        json['freshness_score'] ?? json['freshnessScore'];
    final dynamic rawRating = json['average_rating'] ?? json['rating'];

    return Site(
      id: '${json['id']}',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      categoryId:
          parseNullableInt(json['top_level_category_id']) ??
          parseNullableInt(json['category_id']),
      subcategoryId: parseNullableInt(json['category_parent_id']) != null
          ? parseNullableInt(json['category_id'])
          : null,
      category:
          json['category_name'] as String? ?? json['category'] as String? ?? '',
      subcategory:
          json['subcategory_name'] as String? ?? json['subcategory'] as String?,
      imageUrl: json['cover_photo'] as String? ?? json['imageUrl'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      region: json['region'] as String? ?? '',
      latitude: rawLatitude is num
          ? rawLatitude.toDouble()
          : double.tryParse('$rawLatitude') ?? 0,
      longitude: rawLongitude is num
          ? rawLongitude.toDouble()
          : double.tryParse('$rawLongitude') ?? 0,
      distanceMeters: parseNullableDouble(json['distance_meters']),
      freshnessScore: rawFreshnessScore is int
          ? rawFreshnessScore
          : int.tryParse('$rawFreshnessScore') ?? 0,
      rating: rawRating is num
          ? rawRating.toDouble()
          : double.tryParse('$rawRating') ?? 0,
      phoneNumber: json['phone_number'] as String? ?? '',
      website: json['website'] as String? ?? '',
      priceRange: json['price_range'] as String?,
      acceptsCardPayment: parseBool(json['accepts_card_payment']),
      hasWifi: parseBool(json['has_wifi']),
      hasParking: parseBool(json['has_parking']),
      isAccessible: parseBool(json['is_accessible']),
      verificationStatus: json['verification_status'] as String? ?? 'PENDING',
      totalReviews: parseInt(json['total_reviews']),
      favoritesCount: parseInt(json['favorites_count']),
      ownerId: parseNullableInt(json['owner_id']),
      isProfessionalClaimed: parseBool(json['is_professional_claimed']),
      viewsCount: parseInt(json['views_count']),
      amenities: parseAmenities(json['amenities']),
      previewPhotos: parsePreviewPhotos(json['preview_photos']),
      openingHours: parseOpeningHours(json['opening_hours']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      if (categoryId != null) 'category_id': categoryId,
      if (subcategoryId != null) 'subcategory_id': subcategoryId,
      'category': category,
      if (subcategory != null) 'subcategory': subcategory,
      'imageUrl': imageUrl,
      'address': address,
      'city': city,
      'region': region,
      'latitude': latitude,
      'longitude': longitude,
      'distance_meters': distanceMeters,
      'freshnessScore': freshnessScore,
      'rating': rating,
      'phone_number': phoneNumber,
      'website': website,
      'price_range': priceRange,
      'accepts_card_payment': acceptsCardPayment,
      'has_wifi': hasWifi,
      'has_parking': hasParking,
      'is_accessible': isAccessible,
      'verification_status': verificationStatus,
      'total_reviews': totalReviews,
      'favorites_count': favoritesCount,
      'owner_id': ownerId,
      'is_professional_claimed': isProfessionalClaimed,
      'views_count': viewsCount,
      'amenities': amenities,
      'preview_photos': previewPhotos,
      'opening_hours': openingHours
          .map(
            (hours) => {
              'day_of_week': hours.dayOfWeek,
              'opens_at': hours.opensAt,
              'closes_at': hours.closesAt,
              'is_closed': hours.isClosed,
              'is_24_hours': hours.is24Hours,
              'notes': hours.notes,
            },
          )
          .toList(),
    };
  }

  /// Create a copy of this Site with updated values
  Site copyWith({
    String? id,
    String? name,
    String? description,
    int? categoryId,
    int? subcategoryId,
    String? category,
    String? subcategory,
    String? imageUrl,
    String? address,
    String? city,
    String? region,
    double? latitude,
    double? longitude,
    double? distanceMeters,
    int? freshnessScore,
    double? rating,
    String? phoneNumber,
    String? website,
    String? priceRange,
    bool? acceptsCardPayment,
    bool? hasWifi,
    bool? hasParking,
    bool? isAccessible,
    String? verificationStatus,
    int? totalReviews,
    int? favoritesCount,
    int? ownerId,
    bool? isProfessionalClaimed,
    int? viewsCount,
    List<String>? amenities,
    List<String>? previewPhotos,
    List<SiteOpeningHour>? openingHours,
  }) {
    return Site(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      imageUrl: imageUrl ?? this.imageUrl,
      address: address ?? this.address,
      city: city ?? this.city,
      region: region ?? this.region,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      freshnessScore: freshnessScore ?? this.freshnessScore,
      rating: rating ?? this.rating,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      website: website ?? this.website,
      priceRange: priceRange ?? this.priceRange,
      acceptsCardPayment: acceptsCardPayment ?? this.acceptsCardPayment,
      hasWifi: hasWifi ?? this.hasWifi,
      hasParking: hasParking ?? this.hasParking,
      isAccessible: isAccessible ?? this.isAccessible,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      totalReviews: totalReviews ?? this.totalReviews,
      favoritesCount: favoritesCount ?? this.favoritesCount,
      ownerId: ownerId ?? this.ownerId,
      isProfessionalClaimed:
          isProfessionalClaimed ?? this.isProfessionalClaimed,
      viewsCount: viewsCount ?? this.viewsCount,
      amenities: amenities ?? this.amenities,
      previewPhotos: previewPhotos ?? this.previewPhotos,
      openingHours: openingHours ?? this.openingHours,
    );
  }

  @override
  String toString() {
    return 'Site(id: $id, name: $name, category: $category, rating: $rating, freshnessScore: $freshnessScore, distanceMeters: $distanceMeters)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Site && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  bool get hasDistance => distanceMeters != null && distanceMeters! >= 0;

  String get formattedDistance {
    if (!hasDistance) return '';

    final distance = distanceMeters!;
    if (distance < 1000) {
      return '${distance.round()} m';
    }

    final kilometers = distance / 1000;
    final formatted = kilometers >= 10
        ? kilometers.toStringAsFixed(0)
        : kilometers.toStringAsFixed(1).replaceAll('.', ',');
    return '$formatted km';
  }
}
