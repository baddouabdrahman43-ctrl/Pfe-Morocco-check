import 'package:flutter/foundation.dart';
import '../storage/storage_service.dart';

class AppConstants {
  static const String androidEmulatorBaseUrl = 'http://10.0.2.2:5001/api';
  static const String androidUsbDebugBaseUrl = 'http://127.0.0.1:5001/api';
  static const String _appEnvironment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );
  static const String _flutterAppFlavor = String.fromEnvironment(
    'FLUTTER_APP_FLAVOR',
  );
  static const String _apiBaseUrlOverride = String.fromEnvironment(
    'API_BASE_URL',
  );
  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'AIzaSyBVlobhg7j6G0I53FotEHQqc8NxaNicedA',
  );
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'apptouriste',
  );
  static const String firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '212182583004',
  );
  static const String _firebaseAndroidAppIdProduction =
      '1:212182583004:android:87093e234f8f33c7bf5619';
  static const String _firebaseAndroidAppIdStaging =
      '1:212182583004:android:62f6e68db38c5c50bf5619';
  static const String firebaseIosAppId = String.fromEnvironment(
    'FIREBASE_IOS_APP_ID',
  );
  static const String firebaseIosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
  );
  static const String firebaseWebAppId = String.fromEnvironment(
    'FIREBASE_WEB_APP_ID',
  );
  static const String firebaseWebAuthDomain = String.fromEnvironment(
    'FIREBASE_WEB_AUTH_DOMAIN',
  );
  static const String firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'apptouriste.firebasestorage.app',
  );
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '212182583004-0j83u3stotugoodfhf6avhepb8teui1k.apps.googleusercontent.com',
  );
  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
  );
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
  );
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');
  static const String _sentryTracesSampleRate = String.fromEnvironment(
    'SENTRY_TRACES_SAMPLE_RATE',
    defaultValue: '0',
  );

  static String get appEnvironment => _appEnvironment;
  static double get sentryTracesSampleRate =>
      double.tryParse(_sentryTracesSampleRate) ?? 0;

  static bool get isStagingFlavor => _flutterAppFlavor == 'staging';

  static String get firebaseAndroidAppId {
    final override = const String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
    if (override.isNotEmpty) {
      return override;
    }

    return isStagingFlavor
        ? _firebaseAndroidAppIdStaging
        : _firebaseAndroidAppIdProduction;
  }

  static String normalizeApiBaseUrl(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }

    final normalized = trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
    return normalized.endsWith('/api') ? normalized : '$normalized/api';
  }

  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://127.0.0.1:5001/api';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return androidEmulatorBaseUrl;
      default:
        return 'http://127.0.0.1:5001/api';
    }
  }

  static List<String> get androidConnectionFallbackBaseUrls {
    return const <String>[androidUsbDebugBaseUrl, androidEmulatorBaseUrl];
  }

  static String get baseUrl {
    final storedOverride = StorageService().getApiBaseUrl();
    if (storedOverride != null && storedOverride.isNotEmpty) {
      return normalizeApiBaseUrl(storedOverride);
    }

    if (_apiBaseUrlOverride.isNotEmpty) {
      return normalizeApiBaseUrl(_apiBaseUrlOverride);
    }

    return defaultBaseUrl;
  }

  static bool get supportsGoogleAuth {
    if (kIsWeb) {
      return true;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  static bool get showGoogleAuthEntryPoint {
    return isGoogleSignInConfigured;
  }

  static bool get hasFirebaseCoreConfig {
    final hasSharedFields =
        firebaseApiKey.isNotEmpty &&
        firebaseProjectId.isNotEmpty &&
        firebaseMessagingSenderId.isNotEmpty;

    if (!hasSharedFields) {
      return false;
    }

    if (kIsWeb) {
      return firebaseWebAppId.isNotEmpty && firebaseWebAuthDomain.isNotEmpty;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return firebaseAndroidAppId.isNotEmpty;
      case TargetPlatform.iOS:
        return firebaseIosAppId.isNotEmpty;
      default:
        return false;
    }
  }

  static bool get isGoogleSignInConfigured {
    if (!supportsGoogleAuth || !hasFirebaseCoreConfig) {
      return false;
    }

    if (kIsWeb) {
      return googleWebClientId.isNotEmpty;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return googleServerClientId.isNotEmpty && googleIosClientId.isNotEmpty;
    }

    return googleServerClientId.isNotEmpty;
  }

  static String? get firebaseStorageBucketOrNull {
    return firebaseStorageBucket.isEmpty ? null : firebaseStorageBucket;
  }

  static String? get firebaseIosBundleIdOrNull {
    return firebaseIosBundleId.isEmpty ? null : firebaseIosBundleId;
  }

  static String? get firebaseWebAuthDomainOrNull {
    return firebaseWebAuthDomain.isEmpty ? null : firebaseWebAuthDomain;
  }

  static String? get googleIosClientIdOrNull {
    return googleIosClientId.isEmpty ? null : googleIosClientId;
  }

  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  static const String authBasePath = '/auth';
  static const String appVersion = '1.0.0+1';
  static const String supportEmail = '';
  static const String deepLinkScheme = 'moroccocheck';
  static const String focusCity = 'Agadir';
  static const String focusRegion = 'Souss-Massa';
  static const double focusLatitude = 30.4278;
  static const double focusLongitude = -9.5981;

  static bool get hasOperationalSupportContact {
    return supportEmail.trim().isNotEmpty &&
        !supportEmail.trim().toLowerCase().endsWith('.local');
  }

  AppConstants._();
}
