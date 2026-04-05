import 'sites/site.dart';

class CheckinPolicy {
  final int allowedDistanceMeters;
  final int maxAccuracyMeters;
  final int minimumVisitDurationSeconds;
  final String strategyLabel;

  const CheckinPolicy({
    required this.allowedDistanceMeters,
    required this.maxAccuracyMeters,
    required this.minimumVisitDurationSeconds,
    required this.strategyLabel,
  });
}

CheckinPolicy resolveCheckinPolicyForSite(Site site) {
  final category = site.category.toLowerCase();
  final subcategory = (site.subcategory ?? '').toLowerCase();
  final name = site.name.toLowerCase();

  bool matches(List<String> keywords) {
    return keywords.any(
      (keyword) =>
          category.contains(keyword) ||
          subcategory.contains(keyword) ||
          name.contains(keyword),
    );
  }

  if (matches([
    'museum',
    'musee',
    'histor',
    'heritage',
    'monument',
    'medina',
    'relig',
    'mosquee',
    'kasbah',
  ])) {
    return const CheckinPolicy(
      allowedDistanceMeters: 60,
      maxAccuracyMeters: 35,
      minimumVisitDurationSeconds: 30,
      strategyLabel: 'Verification stricte',
    );
  }

  if (matches([
    'beach',
    'plage',
    'park',
    'parc',
    'garden',
    'jardin',
    'marina',
    'corniche',
  ])) {
    return const CheckinPolicy(
      allowedDistanceMeters: 140,
      maxAccuracyMeters: 50,
      minimumVisitDurationSeconds: 10,
      strategyLabel: 'Verification terrain large',
    );
  }

  return const CheckinPolicy(
    allowedDistanceMeters: 100,
    maxAccuracyMeters: 50,
    minimumVisitDurationSeconds: 15,
    strategyLabel: 'Verification standard',
  );
}
