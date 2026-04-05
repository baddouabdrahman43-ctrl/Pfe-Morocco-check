import 'package:geolocator/geolocator.dart';

class LocationService {
  // Singleton instance
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Request location permission
  /// Returns true if permission is granted, false otherwise
  Future<bool> requestPermission() async {
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException(
        'Les services de localisation sont désactivés. Veuillez les activer dans les paramètres.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        throw LocationPermissionDeniedException(
          'La permission de localisation a été refusée. Veuillez l\'autoriser pour utiliser cette fonctionnalité.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationPermissionDeniedForeverException(
        'La permission de localisation a été refusée de manière permanente. Veuillez l\'activer dans les paramètres de l\'application.',
      );
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Get current position
  /// Throws LocationException if there's an error
  Future<Position> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    bool forceAndroidLocationManager = false,
    Duration? timeLimit,
  }) async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw LocationException(
          'Les services de localisation sont désactivés. Veuillez les activer dans les paramètres.',
        );
      }

      // Check and request permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // Handle permission states
      if (permission == LocationPermission.denied) {
        throw LocationPermissionDeniedException(
          'La permission de localisation a été refusée. Veuillez l\'autoriser pour utiliser cette fonctionnalité.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        throw LocationPermissionDeniedForeverException(
          'La permission de localisation a été refusée de manière permanente. Veuillez l\'activer dans les paramètres de l\'application.',
        );
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: accuracy,
        forceAndroidLocationManager: forceAndroidLocationManager,
        timeLimit: timeLimit,
      );
    } on LocationPermissionDeniedException {
      rethrow;
    } on LocationPermissionDeniedForeverException {
      rethrow;
    } on LocationException {
      rethrow;
    } catch (e) {
      throw LocationException(
        'Erreur lors de la récupération de la position: ${e.toString()}',
      );
    }
  }

  /// Check current permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Check if permission is granted
  Future<bool> hasPermission() async {
    LocationPermission permission = await checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Open app settings to allow user to enable location permission
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Open location settings
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
}

// Custom exceptions for better error handling
class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => message;
}

class LocationPermissionDeniedException extends LocationException {
  LocationPermissionDeniedException(super.message);
}

class LocationPermissionDeniedForeverException extends LocationException {
  LocationPermissionDeniedForeverException(super.message);
}
