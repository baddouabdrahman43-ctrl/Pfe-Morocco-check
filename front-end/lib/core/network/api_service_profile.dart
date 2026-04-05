part of 'api_service.dart';

Future<PasswordUpdateResult> _updateMyPassword(
  ApiService service, {
  required String currentPassword,
  required String newPassword,
}) async {
  final response = await service.put(
    '/users/me/password',
    data: <String, dynamic>{
      'current_password': currentPassword,
      'new_password': newPassword,
    },
  );

  final data = service._asStringKeyedMap(service._extractData(response.data));
  return PasswordUpdateResult(
    passwordUpdated: data['password_updated'] == true,
  );
}

Future<Map<String, dynamic>> _fetchMyStats(ApiService service) async {
  final response = await service.get('/users/me/stats');
  return service._asStringKeyedMap(service._extractData(response.data));
}

Future<Map<String, dynamic>> _fetchContributorRequestStatus(
  ApiService service,
) async {
  final response = await service.get('/users/me/contributor-request');
  return service._asStringKeyedMap(service._extractData(response.data));
}

Future<Map<String, dynamic>> _submitContributorRequest(
  ApiService service, {
  required String motivation,
}) async {
  final response = await service.post(
    '/users/me/contributor-request',
    data: <String, dynamic>{'motivation': motivation},
  );
  return service._asStringKeyedMap(service._extractData(response.data));
}

Future<UserProfileUpdateResult> _updateMyProfile(
  ApiService service, {
  required String firstName,
  required String lastName,
  required String email,
  String? phoneNumber,
  String? nationality,
  String? bio,
  String? profilePicture,
}) async {
  final response = await service.put(
    '${AppConstants.authBasePath}/profile',
    data: <String, dynamic>{
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phoneNumber,
      'nationality': nationality,
      'bio': bio,
      'profile_picture': profilePicture,
    },
  );

  final data = service._asStringKeyedMap(service._extractData(response.data));
  final userData = service._asStringKeyedMap(data['user'] ?? data);
  final badges = data['badges'];

  return UserProfileUpdateResult(
    userData: userData,
    badges: badges is List ? badges : const <dynamic>[],
  );
}

Future<List<Map<String, dynamic>>> _fetchMyBadges(ApiService service) async {
  final response = await service.get('/users/me/badges');
  final items = service._extractList(response.data);

  return items.whereType<Map>().map((item) {
    final rawMap = item;
    return rawMap.map((key, value) => MapEntry(key.toString(), value));
  }).toList();
}

Future<List<BadgeCatalogItem>> _fetchBadgesCatalog(ApiService service) async {
  final response = await service.get('/badges');
  final items = service._extractList(response.data);

  return items.whereType<Map>().map((item) {
    final rawMap = item;
    return BadgeCatalogItem.fromJson(
      rawMap.map((key, value) => MapEntry(key.toString(), value)),
    );
  }).toList();
}

Future<PaginatedResult<LeaderboardEntry>> _fetchLeaderboard(
  ApiService service, {
  int page = 1,
  int limit = 20,
}) async {
  final response = await service.get(
    '/leaderboard',
    queryParameters: <String, dynamic>{'page': page, 'limit': limit},
  );
  final items = service._extractList(response.data);
  final responseMap = service._asStringKeyedMap(response.data);
  final meta = service._asStringKeyedMap(responseMap['meta']);
  final pagination = service._asStringKeyedMap(meta['pagination']);

  return PaginatedResult<LeaderboardEntry>(
    items: items.whereType<Map>().map((item) {
      final rawMap = item;
      return LeaderboardEntry.fromJson(
        rawMap.map((key, value) => MapEntry(key.toString(), value)),
      );
    }).toList(),
    page: int.tryParse('${pagination['page']}') ?? page,
    limit: int.tryParse('${pagination['limit']}') ?? limit,
    total: int.tryParse('${pagination['total']}') ?? items.length,
  );
}

Future<PublicUserProfile> _fetchPublicUserProfile(
  ApiService service,
  String userId,
) async {
  final response = await service.get('/users/$userId');
  final data = service._asStringKeyedMap(service._extractData(response.data));
  return PublicUserProfile.fromJson(data);
}
