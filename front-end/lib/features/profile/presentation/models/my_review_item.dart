import '../../../sites/presentation/models/site_photo.dart';

class MyReviewItem {
  final String id;
  final String siteId;
  final String siteName;
  final int rating;
  final String? title;
  final String content;
  final String status;
  final String moderationStatus;
  final int helpfulCount;
  final bool hasOwnerResponse;
  final String? ownerResponse;
  final DateTime? ownerResponseDate;
  final DateTime createdAt;
  final List<SitePhoto> photos;

  const MyReviewItem({
    required this.id,
    required this.siteId,
    required this.siteName,
    required this.rating,
    required this.title,
    required this.content,
    required this.status,
    required this.moderationStatus,
    required this.helpfulCount,
    required this.hasOwnerResponse,
    required this.ownerResponse,
    required this.ownerResponseDate,
    required this.createdAt,
    required this.photos,
  });

  factory MyReviewItem.fromJson(Map<String, dynamic> json) {
    final rawPhotos = json['photos'] as List<dynamic>? ?? const <dynamic>[];

    return MyReviewItem(
      id: '${json['id']}',
      siteId: '${json['site_id']}',
      siteName: json['site_name'] as String? ?? 'Site',
      rating: int.tryParse('${json['overall_rating'] ?? json['rating']}') ?? 0,
      title: json['title'] as String?,
      content: json['content'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      moderationStatus: json['moderation_status'] as String? ?? 'PENDING',
      helpfulCount: int.tryParse('${json['helpful_count']}') ?? 0,
      hasOwnerResponse:
          json['has_owner_response'] == true ||
          json['has_owner_response'] == 1 ||
          '${json['has_owner_response']}'.toLowerCase() == 'true',
      ownerResponse: json['owner_response'] as String?,
      ownerResponseDate: DateTime.tryParse(
        json['owner_response_date'] as String? ?? '',
      ),
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
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

  bool get isPublished => status == 'PUBLISHED';

  bool get isPending => status == 'PENDING';

  bool get hasPhotos => photos.isNotEmpty;

  String get formattedStatus {
    switch (status) {
      case 'PUBLISHED':
        return 'Publie';
      case 'PENDING':
        return 'En attente';
      case 'HIDDEN':
        return 'Masque';
      default:
        return status;
    }
  }

  String get formattedModerationStatus {
    switch (moderationStatus) {
      case 'APPROVED':
        return 'Approuve';
      case 'PENDING':
        return 'Moderation';
      case 'REJECTED':
        return 'Refuse';
      case 'FLAGGED':
        return 'Signale';
      case 'SPAM':
        return 'Spam';
      default:
        return moderationStatus;
    }
  }
}
