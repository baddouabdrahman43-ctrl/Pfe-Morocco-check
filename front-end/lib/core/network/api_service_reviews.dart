part of 'api_service.dart';

Future<ReviewSubmissionResult> _submitReview(
  ApiService service, {
  required String siteId,
  required int rating,
  required String content,
  String? title,
  List<XFile> photos = const <XFile>[],
}) async {
  final hasPhotos = photos.isNotEmpty;
  final payload = hasPhotos
      ? await _buildReviewMultipartPayload(
          siteId: siteId,
          rating: rating,
          content: content,
          title: title,
          photos: photos,
        )
      : <String, dynamic>{
          'site_id': int.tryParse(siteId) ?? 0,
          'rating': rating,
          'content': content,
          if (title != null && title.isNotEmpty) 'title': title,
        };
  final response = await service.post(
    '/reviews',
    data: payload,
    options: hasPhotos ? Options(contentType: 'multipart/form-data') : null,
  );

  final data = service._asStringKeyedMap(service._extractData(response.data));
  return ReviewSubmissionResult(
    moderationStatus: data['moderation_status'] as String?,
    pointsEarned: int.tryParse('${data['points_earned']}') ?? 0,
  );
}

Future<FormData> _buildReviewMultipartPayload({
  required String siteId,
  required int rating,
  required String content,
  String? title,
  required List<XFile> photos,
}) async {
  final formData = FormData.fromMap(<String, dynamic>{
    'site_id': int.tryParse(siteId) ?? 0,
    'rating': rating,
    'content': content,
    if (title != null && title.isNotEmpty) 'title': title,
  });

  for (final photo in photos) {
    final bytes = await photo.readAsBytes();
    formData.files.add(
      MapEntry(
        'photos',
        MultipartFile.fromBytes(bytes, filename: photo.name),
      ),
    );
  }

  return formData;
}

Future<List<Review>> _fetchSiteReviews(
  ApiService service,
  String siteId, {
  Map<String, dynamic>? queryParameters,
}) async {
  final items = await service._fetchAllPaginatedItems(
    '/sites/$siteId/reviews',
    queryParameters: queryParameters,
  );

  return items.map(Review.fromJson).toList();
}

Future<PaginatedResult<MyReviewItem>> _fetchMyReviews(
  ApiService service, {
  required int userId,
  int page = 1,
  int limit = 20,
  String? status,
}) async {
  final response = await service.get(
    '/reviews',
    queryParameters: <String, dynamic>{
      'user_id': userId,
      'page': page,
      'limit': limit,
      if (status != null && status.isNotEmpty) 'status': status,
    },
  );
  final items = service._extractList(response.data);
  final responseMap = service._asStringKeyedMap(response.data);
  final meta = service._asStringKeyedMap(responseMap['meta']);
  final pagination = service._asStringKeyedMap(meta['pagination']);

  return PaginatedResult<MyReviewItem>(
    items: items.whereType<Map>().map((item) {
      final rawMap = item;
      return MyReviewItem.fromJson(
        rawMap.map((key, value) => MapEntry(key.toString(), value)),
      );
    }).toList(),
    page: int.tryParse('${pagination['page']}') ?? page,
    limit: int.tryParse('${pagination['limit']}') ?? limit,
    total: int.tryParse('${pagination['total']}') ?? items.length,
  );
}

Future<MyReviewItem> _fetchMyReview(ApiService service, String reviewId) async {
  final response = await service.get('/reviews/$reviewId');
  final data = service._asStringKeyedMap(service._extractData(response.data));
  return MyReviewItem.fromJson(data);
}

Future<MyReviewItem> _updateMyReview(
  ApiService service, {
  required String reviewId,
  required int rating,
  required String content,
  String? title,
}) async {
  final response = await service.put(
    '/reviews/$reviewId',
    data: <String, dynamic>{
      'rating': rating,
      'content': content,
      ...?title == null ? null : <String, dynamic>{'title': title},
    },
  );
  final data = service._asStringKeyedMap(service._extractData(response.data));
  return MyReviewItem.fromJson(data);
}

Future<void> _deleteMyReview(ApiService service, String reviewId) async {
  await service.delete('/reviews/$reviewId');
}

Future<Review> _respondToReview(
  ApiService service, {
  required String reviewId,
  required String responseText,
}) async {
  final response = await service.post(
    '/reviews/$reviewId/owner-response',
    data: <String, dynamic>{'response': responseText},
  );
  final data = service._asStringKeyedMap(service._extractData(response.data));
  return Review.fromJson(data);
}
