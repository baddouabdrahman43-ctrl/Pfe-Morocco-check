import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../constants/app_constants.dart';

class AppDeepLinkService {
  AppDeepLinkService._();

  static final AppLinks _appLinks = AppLinks();
  static StreamSubscription<Uri>? _subscription;

  static Future<String?> resolveInitialLocation() async {
    if (kIsWeb) {
      return null;
    }

    try {
      final uri = await _appLinks.getInitialLink();
      return normalizeIncomingUri(uri);
    } catch (_) {
      return null;
    }
  }

  static void attach(GoRouter router) {
    if (kIsWeb || _subscription != null) {
      return;
    }

    _subscription = _appLinks.uriLinkStream.listen((uri) {
      final location = normalizeIncomingUri(uri);
      if (location == null || location.isEmpty) {
        return;
      }
      router.go(location);
    });
  }

  static Future<void> detach() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  static String? normalizeIncomingUri(Uri? uri) {
    if (uri == null) {
      return null;
    }

    final normalizedSegments = _normalizeSegments(uri);
    if (normalizedSegments.isEmpty) {
      return '/home';
    }

    const allowedRoots = <String>{
      'home',
      'map',
      'sites',
      'site',
      'users',
      'leaderboard',
      'profile',
      'professional',
      'checkin',
      'checkins',
      'review',
      'welcome',
      'login',
      'register',
    };

    if (!allowedRoots.contains(normalizedSegments.first)) {
      return null;
    }

    final path = '/${normalizedSegments.join('/')}';
    final query = uri.query;
    return query.isEmpty ? path : '$path?$query';
  }

  static List<String> _normalizeSegments(Uri uri) {
    final isAppScheme = uri.scheme == AppConstants.deepLinkScheme;

    if (isAppScheme) {
      return <String>[
        if (uri.host.isNotEmpty) uri.host,
        ...uri.pathSegments.where((segment) => segment.isNotEmpty),
      ];
    }

    if (uri.scheme == 'http' || uri.scheme == 'https' || uri.scheme.isEmpty) {
      return uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
    }

    return const <String>[];
  }
}
