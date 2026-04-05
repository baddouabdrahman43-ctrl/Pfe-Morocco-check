import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../network/api_service.dart';
import '../storage/storage_service.dart';

class PendingSiteSubmissionPayload {
  final String action;
  final String? siteId;
  final Map<String, dynamic> data;
  final DateTime queuedAt;

  const PendingSiteSubmissionPayload({
    required this.action,
    required this.siteId,
    required this.data,
    required this.queuedAt,
  });

  factory PendingSiteSubmissionPayload.fromJson(Map<String, dynamic> json) {
    return PendingSiteSubmissionPayload(
      action: '${json['action'] ?? 'create'}',
      siteId: json['site_id'] as String?,
      data:
          (json['data'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value),
          ) ??
          const <String, dynamic>{},
      queuedAt:
          DateTime.tryParse(json['queued_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'action': action,
      'site_id': siteId,
      'data': data,
      'queued_at': queuedAt.toIso8601String(),
    };
  }
}

class PendingSiteSubmissionSyncResult {
  final int synced;
  final int discarded;
  final int remaining;

  const PendingSiteSubmissionSyncResult({
    required this.synced,
    required this.discarded,
    required this.remaining,
  });
}

class PendingSiteSubmissionService {
  static const String _storageKey = 'pending_site_submissions_queue';
  static bool _isSyncing = false;

  Future<List<PendingSiteSubmissionPayload>> getPendingSubmissions() async {
    final raw = StorageService().getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return <PendingSiteSubmissionPayload>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <PendingSiteSubmissionPayload>[];
      }

      return decoded
          .whereType<Map>()
          .map(
            (item) => PendingSiteSubmissionPayload.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList();
    } catch (error) {
      debugPrint('Erreur lecture queue lieux pro: $error');
      return <PendingSiteSubmissionPayload>[];
    }
  }

  Future<int> getPendingCount() async {
    final items = await getPendingSubmissions();
    return items.length;
  }

  Future<void> enqueue(PendingSiteSubmissionPayload payload) async {
    final items = await getPendingSubmissions();
    items.insert(0, payload);
    await _save(items.take(20).toList());
  }

  Future<PendingSiteSubmissionSyncResult> syncPendingSubmissions({
    ApiService? apiService,
  }) async {
    if (_isSyncing) {
      final remaining = await getPendingCount();
      return PendingSiteSubmissionSyncResult(
        synced: 0,
        discarded: 0,
        remaining: remaining,
      );
    }

    _isSyncing = true;
    final service = apiService ?? ApiService();
    final queue = await getPendingSubmissions();
    final remainingQueue = <PendingSiteSubmissionPayload>[];
    var synced = 0;
    var discarded = 0;

    try {
      for (final item in queue.reversed) {
        try {
          if (item.action == 'update' && item.siteId != null) {
            await service.updateSite(
              siteId: item.siteId!,
              name: '${item.data['name'] ?? ''}',
              categoryId: _readInt(item.data['category_id']),
              latitude: _readDouble(item.data['latitude']),
              longitude: _readDouble(item.data['longitude']),
              nameAr: item.data['name_ar'] as String?,
              description: item.data['description'] as String?,
              descriptionAr: item.data['description_ar'] as String?,
              subcategory: item.data['subcategory'] as String?,
              address: item.data['address'] as String?,
              city: item.data['city'] as String?,
              region: item.data['region'] as String?,
              postalCode: item.data['postal_code'] as String?,
              phoneNumber: item.data['phone_number'] as String?,
              email: item.data['email'] as String?,
              website: item.data['website'] as String?,
              priceRange: item.data['price_range'] as String?,
              amenities: _readStringList(item.data['amenities']),
              coverPhoto: item.data['cover_photo'] as String?,
              acceptsCardPayment:
                  item.data['accepts_card_payment'] == true,
              hasWifi: item.data['has_wifi'] == true,
              hasParking: item.data['has_parking'] == true,
              isAccessible: item.data['is_accessible'] == true,
            );
          } else {
            await service.createSite(
              name: '${item.data['name'] ?? ''}',
              categoryId: _readInt(item.data['category_id']),
              latitude: _readDouble(item.data['latitude']),
              longitude: _readDouble(item.data['longitude']),
              nameAr: item.data['name_ar'] as String?,
              description: item.data['description'] as String?,
              descriptionAr: item.data['description_ar'] as String?,
              subcategory: item.data['subcategory'] as String?,
              address: item.data['address'] as String?,
              city: item.data['city'] as String?,
              region: item.data['region'] as String?,
              postalCode: item.data['postal_code'] as String?,
              phoneNumber: item.data['phone_number'] as String?,
              email: item.data['email'] as String?,
              website: item.data['website'] as String?,
              priceRange: item.data['price_range'] as String?,
              amenities: _readStringList(item.data['amenities']),
              coverPhoto: item.data['cover_photo'] as String?,
              acceptsCardPayment:
                  item.data['accepts_card_payment'] == true,
              hasWifi: item.data['has_wifi'] == true,
              hasParking: item.data['has_parking'] == true,
              isAccessible: item.data['is_accessible'] == true,
            );
          }
          synced += 1;
        } on ApiException catch (error) {
          final isRetryable =
              error.type == DioExceptionType.connectionError ||
              error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.sendTimeout;

          if (isRetryable) {
            remainingQueue.insert(0, item);
            continue;
          }

          discarded += 1;
        } catch (_) {
          remainingQueue.insert(0, item);
        }
      }

      await _save(remainingQueue);
      return PendingSiteSubmissionSyncResult(
        synced: synced,
        discarded: discarded,
        remaining: remainingQueue.length,
      );
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _save(List<PendingSiteSubmissionPayload> items) async {
    final serialized = jsonEncode(items.map((item) => item.toJson()).toList());
    await StorageService().saveString(_storageKey, serialized);
  }

  static int _readInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse('$value') ?? 0;
  }

  static double _readDouble(dynamic value) {
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    return double.tryParse('$value') ?? 0;
  }

  static List<String>? _readStringList(dynamic value) {
    if (value is! List) {
      return null;
    }
    return value
        .map((item) => '$item')
        .where((item) => item.trim().isNotEmpty)
        .toList();
  }
}
