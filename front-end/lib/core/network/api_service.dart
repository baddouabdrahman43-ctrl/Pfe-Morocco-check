import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/app_constants.dart';
import '../storage/storage_service.dart';
import '../../features/profile/presentation/models/checkin_history_item.dart';
import '../../features/profile/presentation/models/my_review_item.dart';
import '../../features/profile/presentation/models/leaderboard_entry.dart';
import '../../features/profile/presentation/models/badge_catalog_item.dart';
import '../../features/profile/presentation/models/public_user_profile.dart';
import '../../features/professional/models/professional_site_detail.dart';
import '../../features/professional/models/professional_site.dart';
import '../../features/sites/presentation/models/checkin_detail.dart';
import '../../features/sites/presentation/models/review.dart';
import '../../features/sites/presentation/models/site_photo.dart';
import '../../features/sites/presentation/sites/site.dart';
import '../../shared/models/site_category.dart';

part 'api_service_checkins.dart';
part 'api_service_reviews.dart';
part 'api_service_sites.dart';
part 'api_service_profile.dart';
part 'api_service_models.dart';

class ApiService {
  static Future<bool>? _refreshFuture;
  static final Set<ApiService> _instances = <ApiService>{};

  late final Dio _dio;
  late final Dio _refreshDio;

  ApiService() {
    final options = BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      sendTimeout: AppConstants.sendTimeout,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    _dio = Dio(options);
    _refreshDio = Dio(options);
    _setupInterceptors();
    _instances.add(this);
  }

  static void updateBaseUrl(String baseUrl) {
    final normalized = AppConstants.normalizeApiBaseUrl(baseUrl);
    for (final instance in _instances) {
      instance._dio.options.baseUrl = normalized;
      instance._refreshDio.options.baseUrl = normalized;
    }
  }

  bool _canRefreshRequest(RequestOptions options) {
    final path = options.path;
    final isAuthBootstrapRoute =
        path == '${AppConstants.authBasePath}/login' ||
        path == '${AppConstants.authBasePath}/register' ||
        path == '${AppConstants.authBasePath}/refresh';

    return options.extra['tokenRefreshed'] != true && !isAuthBootstrapRoute;
  }

  Future<void> _clearStoredSession() async {
    await StorageService().clearAll();
    _dio.options.headers.remove('Authorization');
  }

  Future<bool> _refreshAccessToken() async {
    final pendingRefresh = _refreshFuture;
    if (pendingRefresh != null) {
      return pendingRefresh;
    }

    final completer = Completer<bool>();
    _refreshFuture = completer.future;

    try {
      final refreshToken = await StorageService().getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        await _clearStoredSession();
        completer.complete(false);
        return completer.future;
      }

      final response = await _refreshDio.post(
        '${AppConstants.authBasePath}/refresh',
        data: <String, dynamic>{'refresh_token': refreshToken},
      );

      final payload = _asStringKeyedMap(_extractData(response.data));
      final accessToken =
          payload['access_token'] as String? ?? payload['token'] as String?;
      final nextRefreshToken = payload['refresh_token'] as String?;

      if (accessToken == null || accessToken.isEmpty) {
        await _clearStoredSession();
        completer.complete(false);
        return completer.future;
      }

      await StorageService().saveToken(accessToken);
      if (nextRefreshToken != null && nextRefreshToken.isNotEmpty) {
        await StorageService().saveRefreshToken(nextRefreshToken);
      }
      _dio.options.headers['Authorization'] = 'Bearer $accessToken';

      completer.complete(true);
      return completer.future;
    } on DioException catch (_) {
      await _clearStoredSession();
      completer.complete(false);
      return completer.future;
    } catch (_) {
      await _clearStoredSession();
      completer.complete(false);
      return completer.future;
    } finally {
      _refreshFuture = null;
    }
  }

  bool _canRetryWithAlternativeBaseUrl(DioException error) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return false;
    }

    if (error.requestOptions.extra['baseUrlRetried'] == true) {
      return false;
    }

    return error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout;
  }

  List<String> _resolveAlternativeBaseUrls(RequestOptions options) {
    final currentBaseUrl = options.baseUrl.isNotEmpty
        ? options.baseUrl
        : _dio.options.baseUrl;

    return AppConstants.androidConnectionFallbackBaseUrls
        .map(AppConstants.normalizeApiBaseUrl)
        .where((candidate) => candidate != currentBaseUrl)
        .toList();
  }

  Future<Response<dynamic>?> _retryWithAlternativeBaseUrl(
    RequestOptions requestOptions,
  ) async {
    final alternativeBaseUrls = _resolveAlternativeBaseUrls(requestOptions);

    for (final baseUrl in alternativeBaseUrls) {
      final retryDio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: _dio.options.connectTimeout,
          receiveTimeout: _dio.options.receiveTimeout,
          sendTimeout: _dio.options.sendTimeout,
          headers: <String, dynamic>{..._dio.options.headers},
        ),
      );

      try {
        final response = await retryDio.request<dynamic>(
          requestOptions.path,
          data: requestOptions.data,
          queryParameters: requestOptions.queryParameters,
          cancelToken: requestOptions.cancelToken,
          onReceiveProgress: requestOptions.onReceiveProgress,
          onSendProgress: requestOptions.onSendProgress,
          options: Options(
            method: requestOptions.method,
            headers: <String, dynamic>{...requestOptions.headers},
            extra: <String, dynamic>{
              ...requestOptions.extra,
              'baseUrlRetried': true,
            },
            responseType: requestOptions.responseType,
            contentType: requestOptions.contentType,
            sendTimeout: requestOptions.sendTimeout,
            receiveTimeout: requestOptions.receiveTimeout,
            followRedirects: requestOptions.followRedirects,
            validateStatus: requestOptions.validateStatus,
            receiveDataWhenStatusError:
                requestOptions.receiveDataWhenStatusError,
          ),
        );

        _dio.options.baseUrl = baseUrl;
        _refreshDio.options.baseUrl = baseUrl;
        await StorageService().saveApiBaseUrl(baseUrl);
        return response;
      } catch (_) {}
    }

    return null;
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService().getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          debugPrint('REQUEST[${options.method}] => ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
            'RESPONSE[${response.statusCode}] => ${response.requestOptions.path}',
          );
          return handler.next(response);
        },
        onError: (error, handler) async {
          debugPrint(
            'ERROR[${error.response?.statusCode}] => ${error.requestOptions.path}',
          );

          final shouldRefresh =
              error.response?.statusCode == 401 &&
              _canRefreshRequest(error.requestOptions);

          if (shouldRefresh) {
            final refreshed = await _refreshAccessToken();
            if (refreshed) {
              final token = await StorageService().getToken();
              if (token != null && token.isNotEmpty) {
                final requestOptions = error.requestOptions;
                final retryResponse = await _dio.request<dynamic>(
                  requestOptions.path,
                  data: requestOptions.data,
                  queryParameters: requestOptions.queryParameters,
                  cancelToken: requestOptions.cancelToken,
                  onReceiveProgress: requestOptions.onReceiveProgress,
                  onSendProgress: requestOptions.onSendProgress,
                  options: Options(
                    method: requestOptions.method,
                    headers: <String, dynamic>{
                      ...requestOptions.headers,
                      'Authorization': 'Bearer $token',
                    },
                    extra: <String, dynamic>{
                      ...requestOptions.extra,
                      'tokenRefreshed': true,
                    },
                    responseType: requestOptions.responseType,
                    contentType: requestOptions.contentType,
                    sendTimeout: requestOptions.sendTimeout,
                    receiveTimeout: requestOptions.receiveTimeout,
                    followRedirects: requestOptions.followRedirects,
                    validateStatus: requestOptions.validateStatus,
                    receiveDataWhenStatusError:
                        requestOptions.receiveDataWhenStatusError,
                  ),
                );

                return handler.resolve(retryResponse);
              }
            }
          }

          if (_canRetryWithAlternativeBaseUrl(error)) {
            final retryResponse = await _retryWithAlternativeBaseUrl(
              error.requestOptions,
            );
            if (retryResponse != null) {
              return handler.resolve(retryResponse);
            }
          }

          return handler.reject(_handleError(error));
        },
      ),
    );
  }

  DioException _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return DioException(
          requestOptions: error.requestOptions,
          error:
              'Delai de connexion depasse. Verifiez votre connexion internet.',
          type: error.type,
        );
      case DioExceptionType.connectionError:
        return DioException(
          requestOptions: error.requestOptions,
          error: 'Impossible de se connecter au serveur.',
          type: error.type,
        );
      case DioExceptionType.badResponse:
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return error;
    }
  }

  String? _getErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data['message'] as String? ??
          data['error'] as String? ??
          data['detail'] as String? ??
          data['errors']?.toString();
    }
    if (data is String) return data;
    return null;
  }

  ApiException _formatException(DioException e) {
    String message = 'Une erreur est survenue';
    int? statusCode;
    String? code;
    dynamic details;

    if (e.response != null) {
      statusCode = e.response?.statusCode;
      final responseMap = _asStringKeyedMap(e.response?.data);
      code = responseMap['code'] as String?;
      details = responseMap['details'];
      message =
          _getErrorMessage(responseMap) ??
          e.response?.statusMessage ??
          'Erreur serveur';
    } else if (e.error != null) {
      message = e.error.toString();
    } else if (e.message != null) {
      message = e.message!;
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      type: e.type,
      code: code,
      details: details,
    );
  }

  Map<String, dynamic> _asStringKeyedMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.map((key, data) => MapEntry(key.toString(), data));
    }
    return <String, dynamic>{};
  }

  dynamic _extractData(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      return payload['data'] ?? payload;
    }
    if (payload is Map) {
      final map = _asStringKeyedMap(payload);
      return map['data'] ?? map;
    }
    return payload;
  }

  List<dynamic> _extractList(dynamic payload) {
    final data = _extractData(payload);
    if (data is List<dynamic>) {
      return data;
    }
    return <dynamic>[];
  }

  Future<List<Map<String, dynamic>>> _fetchAllPaginatedItems(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final baseParams = <String, dynamic>{...?queryParameters};
    final hasExplicitPage = baseParams.containsKey('page');

    if (hasExplicitPage) {
      final response = await get(path, queryParameters: baseParams);
      final items = _extractList(response.data);
      return items.whereType<Map>().map((item) {
        final rawMap = item;
        return rawMap.map((key, value) => MapEntry(key.toString(), value));
      }).toList();
    }

    final requestedLimit = int.tryParse('${baseParams['limit']}');
    final limit = requestedLimit != null && requestedLimit > 0
        ? requestedLimit
        : 100;

    final collected = <Map<String, dynamic>>[];
    var page = 1;

    while (true) {
      final response = await get(
        path,
        queryParameters: <String, dynamic>{
          ...baseParams,
          'page': page,
          'limit': limit,
        },
      );

      final items = _extractList(response.data);
      collected.addAll(
        items.whereType<Map>().map((item) {
          final rawMap = item;
          return rawMap.map((key, value) => MapEntry(key.toString(), value));
        }),
      );

      final responseMap = _asStringKeyedMap(response.data);
      final meta = _asStringKeyedMap(responseMap['meta']);
      final pagination = _asStringKeyedMap(meta['pagination']);
      final total = int.tryParse('${pagination['total']}');

      if (items.isEmpty) {
        break;
      }
      if (total != null && collected.length >= total) {
        break;
      }
      if (items.length < limit) {
        break;
      }

      page += 1;
    }

    return collected;
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _formatException(e);
    }
  }

  Future<Response<dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _formatException(e);
    }
  }

  Future<Response<dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _formatException(e);
    }
  }

  Future<Response<dynamic>> patch(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } on DioException catch (e) {
      throw _formatException(e);
    }
  }

  Future<Response<dynamic>> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _formatException(e);
    }
  }

  Future<void> updateAuthToken(String token) async {
    await StorageService().saveToken(token);
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<void> clearAuthToken() async {
    await StorageService().deleteToken();
    _dio.options.headers.remove('Authorization');
  }

  Future<CheckinSubmissionResult> submitCheckin({
    required String siteId,
    required double latitude,
    required double longitude,
    double accuracy = 20,
    String? status,
    String? comment,
    bool hasPhoto = false,
    List<XFile> photos = const <XFile>[],
    Map<String, dynamic>? deviceInfo,
  }) {
    return _submitCheckin(
      this,
      siteId: siteId,
      latitude: latitude,
      longitude: longitude,
      accuracy: accuracy,
      status: status,
      comment: comment,
      hasPhoto: hasPhoto,
      photos: photos,
      deviceInfo: deviceInfo,
    );
  }

  Future<CheckinDetail> fetchCheckinDetail(String checkinId) {
    return _fetchCheckinDetail(this, checkinId);
  }

  Future<PaginatedResult<CheckinHistoryItem>> fetchMyCheckins({
    int page = 1,
    int limit = 20,
    String? siteId,
  }) {
    return _fetchMyCheckins(this, page: page, limit: limit, siteId: siteId);
  }

  Future<ReviewSubmissionResult> submitReview({
    required String siteId,
    required int rating,
    required String content,
    String? title,
    List<XFile> photos = const <XFile>[],
  }) {
    return _submitReview(
      this,
      siteId: siteId,
      rating: rating,
      content: content,
      title: title,
      photos: photos,
    );
  }

  Future<List<Site>> fetchSites({Map<String, dynamic>? queryParameters}) {
    return _fetchSites(this, queryParameters: queryParameters);
  }

  Future<List<SiteCategory>> fetchCategories({
    bool topLevelOnly = false,
    bool includeChildren = true,
    Map<String, dynamic>? queryParameters,
  }) {
    return _fetchCategories(
      this,
      topLevelOnly: topLevelOnly,
      includeChildren: includeChildren,
      queryParameters: queryParameters,
    );
  }

  Future<List<ProfessionalSite>> fetchProfessionalSites({
    Map<String, dynamic>? queryParameters,
  }) {
    return _fetchProfessionalSites(this, queryParameters: queryParameters);
  }

  Future<ProfessionalSiteDetail> fetchProfessionalSiteDetail(String siteId) {
    return _fetchProfessionalSiteDetail(this, siteId);
  }

  Future<ProfessionalSiteDetail> claimProfessionalSite(String siteId) {
    return _claimProfessionalSite(this, siteId);
  }

  Future<ProfessionalSite> createSite({
    required String name,
    required int categoryId,
    required double latitude,
    required double longitude,
    String? nameAr,
    String? description,
    String? descriptionAr,
    String? subcategory,
    String? address,
    String? city,
    String? region,
    String? postalCode,
    String? phoneNumber,
    String? email,
    String? website,
    String? priceRange,
    List<String>? amenities,
    String? coverPhoto,
    bool acceptsCardPayment = false,
    bool hasWifi = false,
    bool hasParking = false,
    bool isAccessible = false,
  }) {
    return _createSite(
      this,
      name: name,
      categoryId: categoryId,
      latitude: latitude,
      longitude: longitude,
      nameAr: nameAr,
      description: description,
      descriptionAr: descriptionAr,
      subcategory: subcategory,
      address: address,
      city: city,
      region: region,
      postalCode: postalCode,
      phoneNumber: phoneNumber,
      email: email,
      website: website,
      priceRange: priceRange,
      amenities: amenities,
      coverPhoto: coverPhoto,
      acceptsCardPayment: acceptsCardPayment,
      hasWifi: hasWifi,
      hasParking: hasParking,
      isAccessible: isAccessible,
    );
  }

  Future<ProfessionalSite> updateSite({
    required String siteId,
    required String name,
    required int categoryId,
    required double latitude,
    required double longitude,
    String? nameAr,
    String? description,
    String? descriptionAr,
    String? subcategory,
    String? address,
    String? city,
    String? region,
    String? postalCode,
    String? phoneNumber,
    String? email,
    String? website,
    String? priceRange,
    List<String>? amenities,
    String? coverPhoto,
    bool acceptsCardPayment = false,
    bool hasWifi = false,
    bool hasParking = false,
    bool isAccessible = false,
  }) {
    return _updateSite(
      this,
      siteId: siteId,
      name: name,
      categoryId: categoryId,
      latitude: latitude,
      longitude: longitude,
      nameAr: nameAr,
      description: description,
      descriptionAr: descriptionAr,
      subcategory: subcategory,
      address: address,
      city: city,
      region: region,
      postalCode: postalCode,
      phoneNumber: phoneNumber,
      email: email,
      website: website,
      priceRange: priceRange,
      amenities: amenities,
      coverPhoto: coverPhoto,
      acceptsCardPayment: acceptsCardPayment,
      hasWifi: hasWifi,
      hasParking: hasParking,
      isAccessible: isAccessible,
    );
  }

  Future<Site> fetchSiteDetail(String siteId) {
    return _fetchSiteDetail(this, siteId);
  }

  Future<List<Review>> fetchSiteReviews(
    String siteId, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _fetchSiteReviews(this, siteId, queryParameters: queryParameters);
  }

  Future<PaginatedResult<MyReviewItem>> fetchMyReviews({
    required int userId,
    int page = 1,
    int limit = 20,
    String? status,
  }) {
    return _fetchMyReviews(
      this,
      userId: userId,
      page: page,
      limit: limit,
      status: status,
    );
  }

  Future<MyReviewItem> fetchMyReview(String reviewId) {
    return _fetchMyReview(this, reviewId);
  }

  Future<MyReviewItem> updateMyReview({
    required String reviewId,
    required int rating,
    required String content,
    String? title,
  }) {
    return _updateMyReview(
      this,
      reviewId: reviewId,
      rating: rating,
      content: content,
      title: title,
    );
  }

  Future<void> deleteMyReview(String reviewId) {
    return _deleteMyReview(this, reviewId);
  }

  Future<Review> respondToReview({
    required String reviewId,
    required String responseText,
  }) {
    return _respondToReview(
      this,
      reviewId: reviewId,
      responseText: responseText,
    );
  }

  Future<List<SitePhoto>> fetchSitePhotos(
    String siteId, {
    Map<String, dynamic>? queryParameters,
  }) {
    return _fetchSitePhotos(this, siteId, queryParameters: queryParameters);
  }

  Future<PasswordUpdateResult> updateMyPassword({
    required String currentPassword,
    required String newPassword,
  }) {
    return _updateMyPassword(
      this,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }

  Future<Map<String, dynamic>> fetchMyStats() {
    return _fetchMyStats(this);
  }

  Future<Map<String, dynamic>> fetchContributorRequestStatus() {
    return _fetchContributorRequestStatus(this);
  }

  Future<Map<String, dynamic>> submitContributorRequest({
    required String motivation,
  }) {
    return _submitContributorRequest(this, motivation: motivation);
  }

  Future<UserProfileUpdateResult> updateMyProfile({
    required String firstName,
    required String lastName,
    required String email,
    String? phoneNumber,
    String? nationality,
    String? bio,
    String? profilePicture,
  }) {
    return _updateMyProfile(
      this,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phoneNumber: phoneNumber,
      nationality: nationality,
      bio: bio,
      profilePicture: profilePicture,
    );
  }

  Future<List<Map<String, dynamic>>> fetchMyBadges() {
    return _fetchMyBadges(this);
  }

  Future<List<BadgeCatalogItem>> fetchBadgesCatalog() {
    return _fetchBadgesCatalog(this);
  }

  Future<PaginatedResult<LeaderboardEntry>> fetchLeaderboard({
    int page = 1,
    int limit = 20,
  }) {
    return _fetchLeaderboard(this, page: page, limit: limit);
  }

  Future<PublicUserProfile> fetchPublicUserProfile(String userId) {
    return _fetchPublicUserProfile(this, userId);
  }
}
