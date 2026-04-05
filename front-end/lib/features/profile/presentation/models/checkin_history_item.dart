import '../../../sites/presentation/models/site_photo.dart';

class CheckinHistoryItem {
  final String id;
  final String siteId;
  final String siteName;
  final String city;
  final String region;
  final String status;
  final String validationStatus;
  final int pointsEarned;
  final DateTime createdAt;
  final double distance;
  final double accuracy;
  final List<SitePhoto> photos;

  const CheckinHistoryItem({
    required this.id,
    required this.siteId,
    required this.siteName,
    required this.city,
    required this.region,
    required this.status,
    required this.validationStatus,
    required this.pointsEarned,
    required this.createdAt,
    required this.distance,
    required this.accuracy,
    required this.photos,
  });

  factory CheckinHistoryItem.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is double) return value;
      if (value is num) return value.toDouble();
      return double.tryParse('$value') ?? 0;
    }

    final rawPhotos = json['photos'] as List<dynamic>? ?? const <dynamic>[];

    return CheckinHistoryItem(
      id: '${json['id']}',
      siteId: '${json['site_id']}',
      siteName: json['site_name'] as String? ?? 'Site',
      city: json['city'] as String? ?? '',
      region: json['region'] as String? ?? '',
      status: json['status'] as String? ?? 'NO_CHANGE',
      validationStatus: json['validation_status'] as String? ?? 'APPROVED',
      pointsEarned: int.tryParse('${json['points_earned']}') ?? 0,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      distance: parseDouble(json['distance']),
      accuracy: parseDouble(json['accuracy']),
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

  String get primaryLocationLabel {
    final parts = <String>[
      if (city.trim().isNotEmpty) city.trim(),
      if (region.trim().isNotEmpty) region.trim(),
    ];
    return parts.join(', ');
  }

  bool get hasPhotos => photos.isNotEmpty;

  bool get isPendingReview => validationStatus == 'PENDING';

  bool get isApproved => validationStatus == 'APPROVED';

  String get formattedValidationStatus {
    switch (validationStatus) {
      case 'APPROVED':
        return 'Valide';
      case 'PENDING':
        return 'A verifier';
      case 'REJECTED':
        return 'Refuse';
      default:
        return validationStatus;
    }
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
