import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../network/api_service.dart';
import '../storage/storage_service.dart';

class PendingCheckinPayload {
  final String siteId;
  final double latitude;
  final double longitude;
  final double accuracy;
  final String? status;
  final String? comment;
  final List<String> photoPaths;
  final Map<String, dynamic> deviceInfo;
  final DateTime queuedAt;

  const PendingCheckinPayload({
    required this.siteId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.status,
    required this.comment,
    required this.photoPaths,
    required this.deviceInfo,
    required this.queuedAt,
  });

  factory PendingCheckinPayload.fromJson(Map<String, dynamic> json) {
    return PendingCheckinPayload(
      siteId: '${json['site_id']}',
      latitude: double.tryParse('${json['latitude']}') ?? 0,
      longitude: double.tryParse('${json['longitude']}') ?? 0,
      accuracy: double.tryParse('${json['accuracy']}') ?? 20,
      status: json['status'] as String?,
      comment: json['comment'] as String?,
      photoPaths: (json['photo_paths'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => '$item')
          .where((item) => item.trim().isNotEmpty)
          .toList(),
      deviceInfo:
          (json['device_info'] as Map?)?.map(
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
      'site_id': siteId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'status': status,
      'comment': comment,
      'photo_paths': photoPaths,
      'device_info': deviceInfo,
      'queued_at': queuedAt.toIso8601String(),
    };
  }
}

class PendingCheckinSyncResult {
  final int synced;
  final int discarded;
  final int remaining;

  const PendingCheckinSyncResult({
    required this.synced,
    required this.discarded,
    required this.remaining,
  });
}

class PendingCheckinService {
  static const String _storageKey = 'pending_checkins_queue';
  static bool _isSyncing = false;

  Future<List<PendingCheckinPayload>> getPendingCheckins() async {
    final raw = StorageService().getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return <PendingCheckinPayload>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <PendingCheckinPayload>[];
      }

      return decoded
          .whereType<Map>()
          .map(
            (item) => PendingCheckinPayload.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList();
    } catch (error) {
      debugPrint('Erreur lecture queue check-ins: $error');
      return <PendingCheckinPayload>[];
    }
  }

  Future<int> getPendingCount() async {
    final items = await getPendingCheckins();
    return items.length;
  }

  Future<void> enqueue(PendingCheckinPayload payload) async {
    final items = await getPendingCheckins();
    items.insert(0, payload);
    await _save(items.take(20).toList());
  }

  Future<PendingCheckinSyncResult> syncPendingCheckins({
    ApiService? apiService,
  }) async {
    if (_isSyncing) {
      final remaining = await getPendingCount();
      return PendingCheckinSyncResult(
        synced: 0,
        discarded: 0,
        remaining: remaining,
      );
    }

    _isSyncing = true;
    final service = apiService ?? ApiService();
    final queue = await getPendingCheckins();
    final remainingQueue = <PendingCheckinPayload>[];
    var synced = 0;
    var discarded = 0;

    try {
      for (final item in queue.reversed) {
        try {
          final photos = <XFile>[];
          for (final path in item.photoPaths) {
            if (await File(path).exists()) {
              photos.add(XFile(path));
            }
          }

          await service.submitCheckin(
            siteId: item.siteId,
            latitude: item.latitude,
            longitude: item.longitude,
            accuracy: item.accuracy,
            status: item.status,
            comment: item.comment,
            hasPhoto: photos.isNotEmpty,
            photos: photos,
            deviceInfo: <String, dynamic>{
              ...item.deviceInfo,
              'collected_offline': true,
              'queued_at': item.queuedAt.toIso8601String(),
              'synced_at': DateTime.now().toIso8601String(),
            },
          );
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
      return PendingCheckinSyncResult(
        synced: synced,
        discarded: discarded,
        remaining: remainingQueue.length,
      );
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _save(List<PendingCheckinPayload> items) async {
    final serialized = jsonEncode(items.map((item) => item.toJson()).toList());
    await StorageService().saveString(_storageKey, serialized);
  }
}
