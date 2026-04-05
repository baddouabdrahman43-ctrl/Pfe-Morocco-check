import 'dart:convert';

import 'site_photo.dart';

class CheckinDetail {
  final String id;
  final String siteId;
  final String siteName;
  final String address;
  final String city;
  final String region;
  final String status;
  final String? comment;
  final double latitude;
  final double longitude;
  final double accuracy;
  final double distance;
  final bool hasPhoto;
  final int pointsEarned;
  final String validationStatus;
  final String verificationNotes;
  final int visitDurationSeconds;
  final Map<String, dynamic> validationContext;
  final DateTime createdAt;
  final String authorName;
  final List<SitePhoto> photos;

  const CheckinDetail({
    required this.id,
    required this.siteId,
    required this.siteName,
    required this.address,
    required this.city,
    required this.region,
    required this.status,
    required this.comment,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.distance,
    required this.hasPhoto,
    required this.pointsEarned,
    required this.validationStatus,
    required this.verificationNotes,
    required this.visitDurationSeconds,
    required this.validationContext,
    required this.createdAt,
    required this.authorName,
    required this.photos,
  });

  factory CheckinDetail.fromJson(Map<String, dynamic> json) {
    final firstName = json['first_name'] as String? ?? '';
    final lastName = json['last_name'] as String? ?? '';
    final rawPhotos = json['photos'] as List<dynamic>? ?? const <dynamic>[];
    final rawDeviceInfo = json['device_info'];
    final deviceInfo = rawDeviceInfo is Map
        ? rawDeviceInfo.map((key, value) => MapEntry(key.toString(), value))
        : rawDeviceInfo is String && rawDeviceInfo.trim().isNotEmpty
        ? (() {
            try {
              final parsed = jsonDecode(rawDeviceInfo);
              if (parsed is Map) {
                return parsed.map(
                  (key, value) => MapEntry(key.toString(), value),
                );
              }
            } catch (_) {}
            return const <String, dynamic>{};
          })()
        : const <String, dynamic>{};
    final validationContext = deviceInfo['validation_context'] is Map
        ? (deviceInfo['validation_context'] as Map).map(
            (key, value) => MapEntry(key.toString(), value),
          )
        : const <String, dynamic>{};

    double parseDouble(dynamic value) {
      if (value is double) return value;
      if (value is num) return value.toDouble();
      return double.tryParse('$value') ?? 0;
    }

    return CheckinDetail(
      id: '${json['id']}',
      siteId: '${json['site_id']}',
      siteName: json['site_name'] as String? ?? 'Site',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      region: json['region'] as String? ?? '',
      status: json['status'] as String? ?? 'OPEN',
      comment: json['comment'] as String?,
      latitude: parseDouble(json['latitude']),
      longitude: parseDouble(json['longitude']),
      accuracy: parseDouble(json['accuracy']),
      distance: parseDouble(json['distance']),
      hasPhoto:
          json['has_photo'] == true ||
          json['has_photo'] == 1 ||
          json['has_photo'] == '1',
      pointsEarned: int.tryParse('${json['points_earned']}') ?? 0,
      validationStatus: json['validation_status'] as String? ?? 'APPROVED',
      verificationNotes: json['verification_notes'] as String? ?? '',
      visitDurationSeconds:
          int.tryParse('${deviceInfo['visit_duration_seconds']}') ?? 0,
      validationContext: validationContext,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      authorName: '$firstName $lastName'.trim().isNotEmpty
          ? '$firstName $lastName'.trim()
          : 'Utilisateur',
      photos: rawPhotos
          .whereType<Map>()
          .map(
            (item) => SitePhoto.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList(),
    );
  }

  String get formattedStatus {
    switch (status) {
      case 'OPEN':
        return 'Ouvert';
      case 'CLOSED':
        return 'Ferme';
      case 'UNDER_CONSTRUCTION':
        return 'En construction';
      case 'CLOSED_TEMPORARILY':
        return 'Fermeture temporaire';
      case 'CLOSED_PERMANENTLY':
        return 'Ferme definitivement';
      case 'RENOVATING':
        return 'En renovation';
      case 'RELOCATED':
        return 'Relocalise';
      case 'NO_CHANGE':
        return 'Aucun changement';
      default:
        return status;
    }
  }
}
