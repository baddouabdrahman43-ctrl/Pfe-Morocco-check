import 'dart:math' as math;

/// Calculate the distance between two geographic points using the Haversine formula.
///
/// The Haversine formula calculates the great-circle distance between two points
/// on a sphere given their longitudes and latitudes.
///
/// [lat1] - Latitude of the first point in degrees
/// [lon1] - Longitude of the first point in degrees
/// [lat2] - Latitude of the second point in degrees
/// [lon2] - Longitude of the second point in degrees
///
/// Returns the distance in meters.
double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  // Earth's radius in meters
  const double earthRadius = 6371000.0;

  // Convert degrees to radians
  final double lat1Rad = lat1 * (math.pi / 180.0);
  final double lon1Rad = lon1 * (math.pi / 180.0);
  final double lat2Rad = lat2 * (math.pi / 180.0);
  final double lon2Rad = lon2 * (math.pi / 180.0);

  // Calculate differences
  final double deltaLat = lat2Rad - lat1Rad;
  final double deltaLon = lon2Rad - lon1Rad;

  // Haversine formula
  final double a =
      math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
      math.cos(lat1Rad) *
          math.cos(lat2Rad) *
          math.sin(deltaLon / 2) *
          math.sin(deltaLon / 2);

  final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

  // Distance in meters
  final double distance = earthRadius * c;

  return distance;
}

/// Format distance in meters to a human-readable string.
///
/// Returns:
/// - Distance in meters if < 1000m
/// - Distance in kilometers if >= 1000m
String formatDistance(double distanceInMeters) {
  if (distanceInMeters < 1000) {
    return '${distanceInMeters.toStringAsFixed(0)} m';
  } else {
    return '${(distanceInMeters / 1000).toStringAsFixed(2)} km';
  }
}
