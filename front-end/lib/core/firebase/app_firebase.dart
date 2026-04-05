import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';

class AppFirebase {
  static bool get isConfigured => AppFirebaseOptions.currentPlatform != null;

  static Future<void> initialize() async {
    if (Firebase.apps.isNotEmpty || !isConfigured) {
      return;
    }

    await Firebase.initializeApp(options: AppFirebaseOptions.currentPlatform);
  }
}

class AppFirebaseOptions {
  static FirebaseOptions? get currentPlatform {
    if (!AppConstants.hasFirebaseCoreConfig) {
      return null;
    }

    if (kIsWeb) {
      return FirebaseOptions(
        apiKey: AppConstants.firebaseApiKey,
        appId: AppConstants.firebaseWebAppId,
        messagingSenderId: AppConstants.firebaseMessagingSenderId,
        projectId: AppConstants.firebaseProjectId,
        authDomain: AppConstants.firebaseWebAuthDomainOrNull,
        storageBucket: AppConstants.firebaseStorageBucketOrNull,
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        if (AppConstants.firebaseAndroidAppId.isEmpty) {
          return null;
        }

        return FirebaseOptions(
          apiKey: AppConstants.firebaseApiKey,
          appId: AppConstants.firebaseAndroidAppId,
          messagingSenderId: AppConstants.firebaseMessagingSenderId,
          projectId: AppConstants.firebaseProjectId,
          storageBucket: AppConstants.firebaseStorageBucketOrNull,
        );
      case TargetPlatform.iOS:
        if (AppConstants.firebaseIosAppId.isEmpty) {
          return null;
        }

        return FirebaseOptions(
          apiKey: AppConstants.firebaseApiKey,
          appId: AppConstants.firebaseIosAppId,
          messagingSenderId: AppConstants.firebaseMessagingSenderId,
          projectId: AppConstants.firebaseProjectId,
          storageBucket: AppConstants.firebaseStorageBucketOrNull,
          iosBundleId: AppConstants.firebaseIosBundleIdOrNull,
          iosClientId: AppConstants.googleIosClientIdOrNull,
        );
      default:
        return null;
    }
  }
}
