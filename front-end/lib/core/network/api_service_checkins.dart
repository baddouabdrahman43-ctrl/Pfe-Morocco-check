part of 'api_service.dart';

Future<CheckinSubmissionResult> _submitCheckin(
  ApiService service, {
  required String siteId,
  required double latitude,
  required double longitude,
  double accuracy = 20,
  String? status,
  String? comment,
  bool hasPhoto = false,
  List<XFile> photos = const <XFile>[],
  Map<String, dynamic>? deviceInfo,
}) async {
  final hasSelectedPhotos = photos.isNotEmpty;
  final payload = hasSelectedPhotos
      ? await _buildCheckinMultipartPayload(
          siteId: siteId,
          latitude: latitude,
          longitude: longitude,
          accuracy: accuracy,
          status: status,
          comment: comment,
          photos: photos,
          deviceInfo: deviceInfo,
        )
      : <String, dynamic>{
          'site_id': int.tryParse(siteId) ?? 0,
          'latitude': latitude,
          'longitude': longitude,
          'accuracy': accuracy,
          'has_photo': hasPhoto || hasSelectedPhotos,
          if (status != null && status.isNotEmpty) 'status': status,
          if (comment != null && comment.isNotEmpty) 'comment': comment,
          if (deviceInfo != null && deviceInfo.isNotEmpty)
            'device_info': deviceInfo,
        };
  final response = await service.post(
    '/checkins',
    data: payload,
    options: hasSelectedPhotos ? Options(contentType: 'multipart/form-data') : null,
  );

  final data = service._asStringKeyedMap(service._extractData(response.data));
  return CheckinSubmissionResult(
    pointsEarned: int.tryParse('${data['points_earned']}') ?? 0,
    photosUploaded: int.tryParse('${data['photos_uploaded']}') ?? 0,
    validationStatus:
        service._asStringKeyedMap(data['checkin'])['validation_status'] as String?,
    validationContext: service._asStringKeyedMap(data['validation_context']),
  );
}

Future<CheckinDetail> _fetchCheckinDetail(
  ApiService service,
  String checkinId,
) async {
  final response = await service.get('/checkins/$checkinId');
  final data = service._asStringKeyedMap(service._extractData(response.data));
  return CheckinDetail.fromJson(data);
}

Future<PaginatedResult<CheckinHistoryItem>> _fetchMyCheckins(
  ApiService service, {
  int page = 1,
  int limit = 20,
  String? siteId,
}) async {
  final response = await service.get(
    '/checkins',
    queryParameters: <String, dynamic>{
      'page': page,
      'limit': limit,
      if (siteId != null && siteId.isNotEmpty) 'site_id': siteId,
    },
  );

  final items = service._extractList(response.data);
  final responseMap = service._asStringKeyedMap(response.data);
  final meta = service._asStringKeyedMap(responseMap['meta']);
  final pagination = service._asStringKeyedMap(meta['pagination']);

  return PaginatedResult<CheckinHistoryItem>(
    items: items.whereType<Map>().map((item) {
      final rawMap = item;
      return CheckinHistoryItem.fromJson(
        rawMap.map((key, value) => MapEntry(key.toString(), value)),
      );
    }).toList(),
    page: int.tryParse('${pagination['page']}') ?? page,
    limit: int.tryParse('${pagination['limit']}') ?? limit,
    total: int.tryParse('${pagination['total']}') ?? items.length,
  );
}

Future<FormData> _buildCheckinMultipartPayload({
  required String siteId,
  required double latitude,
  required double longitude,
  required double accuracy,
  String? status,
  String? comment,
  required List<XFile> photos,
  Map<String, dynamic>? deviceInfo,
}) async {
  final formData = FormData.fromMap(<String, dynamic>{
    'site_id': int.tryParse(siteId) ?? 0,
    'latitude': latitude,
    'longitude': longitude,
    'accuracy': accuracy,
    'has_photo': true,
    if (status != null && status.isNotEmpty) 'status': status,
    if (comment != null && comment.isNotEmpty) 'comment': comment,
    if (deviceInfo != null && deviceInfo.isNotEmpty)
      'device_info': jsonEncode(deviceInfo),
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
