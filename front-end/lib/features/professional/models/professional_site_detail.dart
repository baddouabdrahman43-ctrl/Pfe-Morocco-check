import '../../sites/presentation/models/review.dart';
import 'professional_site.dart';

class ProfessionalSiteDetail {
  final ProfessionalSite site;
  final List<ProfessionalOpeningHour> openingHours;
  final List<Review> recentReviews;
  final ProfessionalSiteAnalytics analytics;

  const ProfessionalSiteDetail({
    required this.site,
    required this.openingHours,
    required this.recentReviews,
    required this.analytics,
  });

  factory ProfessionalSiteDetail.fromJson(Map<String, dynamic> json) {
    List<ProfessionalOpeningHour> parseOpeningHours(dynamic value) {
      if (value is! List) return const <ProfessionalOpeningHour>[];
      return value
          .whereType<Map>()
          .map(
            (item) => ProfessionalOpeningHour.fromJson(
              item.map((key, data) => MapEntry(key.toString(), data)),
            ),
          )
          .toList();
    }

    List<Review> parseReviews(dynamic value) {
      if (value is! List) return const <Review>[];
      return value
          .whereType<Map>()
          .map(
            (item) => Review.fromJson(
              item.map((key, data) => MapEntry(key.toString(), data)),
            ),
          )
          .toList();
    }

    final siteJson = json['site'] is Map
        ? (json['site'] as Map).map(
            (key, value) => MapEntry(key.toString(), value),
          )
        : json;

    return ProfessionalSiteDetail(
      site: ProfessionalSite.fromJson(siteJson),
      openingHours: parseOpeningHours(json['opening_hours']),
      recentReviews: parseReviews(json['recent_reviews']),
      analytics: ProfessionalSiteAnalytics.fromJson(
        json['analytics'] is Map
            ? (json['analytics'] as Map).map(
                (key, value) => MapEntry(key.toString(), value),
              )
            : const <String, dynamic>{},
      ),
    );
  }
}

class ProfessionalSiteAnalytics {
  final int publishedReviews;
  final int pendingReviews;
  final int ownerRepliesCount;
  final int responseRate;
  final int recentReviews30d;
  final double averageRating30d;
  final int totalCheckins;
  final int recentCheckins30d;

  const ProfessionalSiteAnalytics({
    required this.publishedReviews,
    required this.pendingReviews,
    required this.ownerRepliesCount,
    required this.responseRate,
    required this.recentReviews30d,
    required this.averageRating30d,
    required this.totalCheckins,
    required this.recentCheckins30d,
  });

  factory ProfessionalSiteAnalytics.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse('$value') ?? 0;
    }

    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse('$value') ?? 0;
    }

    return ProfessionalSiteAnalytics(
      publishedReviews: parseInt(json['published_reviews']),
      pendingReviews: parseInt(json['pending_reviews']),
      ownerRepliesCount: parseInt(json['owner_replies_count']),
      responseRate: parseInt(json['response_rate']),
      recentReviews30d: parseInt(json['recent_reviews_30d']),
      averageRating30d: parseDouble(json['average_rating_30d']),
      totalCheckins: parseInt(json['total_checkins']),
      recentCheckins30d: parseInt(json['recent_checkins_30d']),
    );
  }
}

class ProfessionalOpeningHour {
  final String dayOfWeek;
  final String? opensAt;
  final String? closesAt;
  final bool isClosed;
  final bool is24Hours;
  final String notes;

  const ProfessionalOpeningHour({
    required this.dayOfWeek,
    required this.opensAt,
    required this.closesAt,
    required this.isClosed,
    required this.is24Hours,
    required this.notes,
  });

  factory ProfessionalOpeningHour.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      final text = '$value'.toLowerCase();
      return text == 'true' || text == '1';
    }

    return ProfessionalOpeningHour(
      dayOfWeek: json['day_of_week'] as String? ?? '',
      opensAt: json['opens_at'] as String?,
      closesAt: json['closes_at'] as String?,
      isClosed: parseBool(json['is_closed']),
      is24Hours: parseBool(json['is_24_hours']),
      notes: json['notes'] as String? ?? '',
    );
  }
}
