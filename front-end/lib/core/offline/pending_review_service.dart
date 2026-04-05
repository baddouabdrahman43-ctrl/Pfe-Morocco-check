import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../network/api_service.dart';
import '../storage/storage_service.dart';

class PendingReviewPayload {
  final String siteId;
  final int rating;
  final String content;
  final String? title;
  final List<String> photoPaths;
  final DateTime queuedAt;

  const PendingReviewPayload({
    required this.siteId,
    required this.rating,
    required this.content,
    required this.title,
    required this.photoPaths,
    required this.queuedAt,
  });

  factory PendingReviewPayload.fromJson(Map<String, dynamic> json) {
    return PendingReviewPayload(
      siteId: '${json['site_id']}',
      rating: int.tryParse('${json['rating']}') ?? 0,
      content: '${json['content'] ?? ''}',
      title: json['title'] as String?,
      photoPaths: (json['photo_paths'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => '$item')
          .where((item) => item.trim().isNotEmpty)
          .toList(),
      queuedAt:
          DateTime.tryParse(json['queued_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'site_id': siteId,
      'rating': rating,
      'content': content,
      'title': title,
      'photo_paths': photoPaths,
      'queued_at': queuedAt.toIso8601String(),
    };
  }
}

class PendingReviewSyncResult {
  final int synced;
  final int discarded;
  final int remaining;

  const PendingReviewSyncResult({
    required this.synced,
    required this.discarded,
    required this.remaining,
  });
}

class PendingReviewService {
  static const String _storageKey = 'pending_reviews_queue';
  static bool _isSyncing = false;

  Future<List<PendingReviewPayload>> getPendingReviews() async {
    final raw = StorageService().getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return <PendingReviewPayload>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <PendingReviewPayload>[];
      }

      return decoded
          .whereType<Map>()
          .map(
            (item) => PendingReviewPayload.fromJson(
              item.map((key, value) => MapEntry(key.toString(), value)),
            ),
          )
          .toList();
    } catch (error) {
      debugPrint('Erreur lecture queue avis: $error');
      return <PendingReviewPayload>[];
    }
  }

  Future<int> getPendingCount() async {
    final items = await getPendingReviews();
    return items.length;
  }

  Future<void> enqueue(PendingReviewPayload payload) async {
    final items = await getPendingReviews();
    items.insert(0, payload);
    await _save(items.take(20).toList());
  }

  Future<PendingReviewSyncResult> syncPendingReviews({
    ApiService? apiService,
  }) async {
    if (_isSyncing) {
      final remaining = await getPendingCount();
      return PendingReviewSyncResult(
        synced: 0,
        discarded: 0,
        remaining: remaining,
      );
    }

    _isSyncing = true;
    final service = apiService ?? ApiService();
    final queue = await getPendingReviews();
    final remainingQueue = <PendingReviewPayload>[];
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

          await service.submitReview(
            siteId: item.siteId,
            rating: item.rating,
            content: item.content,
            title: item.title,
            photos: photos,
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
      return PendingReviewSyncResult(
        synced: synced,
        discarded: discarded,
        remaining: remainingQueue.length,
      );
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _save(List<PendingReviewPayload> items) async {
    final serialized = jsonEncode(items.map((item) => item.toJson()).toList());
    await StorageService().saveString(_storageKey, serialized);
  }
}
