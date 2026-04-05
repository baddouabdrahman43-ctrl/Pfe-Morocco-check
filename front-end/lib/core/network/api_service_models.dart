part of 'api_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final DioExceptionType? type;
  final String? code;
  final dynamic details;

  ApiException({
    required this.message,
    this.statusCode,
    this.type,
    this.code,
    this.details,
  });

  @override
  String toString() => message;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError => statusCode != null && statusCode! >= 500;
  bool get isClientError =>
      statusCode != null && statusCode! >= 400 && statusCode! < 500;
}

class ReviewSubmissionResult {
  final String? moderationStatus;
  final int pointsEarned;

  const ReviewSubmissionResult({
    required this.moderationStatus,
    required this.pointsEarned,
  });

  bool get isPendingModeration => moderationStatus == 'PENDING';
  bool get isPublished => moderationStatus == 'APPROVED';
}

class CheckinSubmissionResult {
  final int pointsEarned;
  final int photosUploaded;
  final String? validationStatus;
  final Map<String, dynamic> validationContext;

  const CheckinSubmissionResult({
    required this.pointsEarned,
    required this.photosUploaded,
    required this.validationStatus,
    required this.validationContext,
  });

  bool get hasUploadedPhotos => photosUploaded > 0;
  bool get isPendingReview => validationStatus == 'PENDING';
}

class PaginatedResult<T> {
  final List<T> items;
  final int page;
  final int limit;
  final int total;

  const PaginatedResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });
}

class UserProfileUpdateResult {
  final Map<String, dynamic> userData;
  final List<dynamic> badges;

  const UserProfileUpdateResult({required this.userData, required this.badges});
}

class PasswordUpdateResult {
  final bool passwordUpdated;

  const PasswordUpdateResult({required this.passwordUpdated});
}
