import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../core/network/api_service.dart';
import '../../../core/storage/storage_service.dart';
import '../../../shared/models/site_category.dart';
import 'sites/site.dart';

class SitesProvider extends ChangeNotifier {
  static const String _favoriteSiteIdsKey = 'sites_favorite_ids';
  static const String _recentViewedSiteIdsKey = 'sites_recent_viewed_ids';
  static const String _recentActivityKey = 'sites_recent_activity';

  final ApiService _apiService;
  Timer? _searchDebounce;
  List<Site> _allSites = [];
  List<SiteCategory> _availableCategories = [];
  final Set<String> _checkedInSiteIds = <String>{};
  Set<String> _favoriteSiteIds = <String>{};
  List<String> _recentViewedSiteIds = <String>[];
  List<SiteActivityEntry> _recentActivity = <SiteActivityEntry>[];
  List<Site> get sites => _allSites;
  List<SiteCategory> get availableCategories => _availableCategories;
  Set<String> get favoriteSiteIds => _favoriteSiteIds;
  int get favoritesCount => _favoriteSiteIds.length;
  List<String> get recentViewedSiteIds =>
      List<String>.unmodifiable(_recentViewedSiteIds);
  List<SiteActivityEntry> get localRecentActivity =>
      List<SiteActivityEntry>.unmodifiable(_recentActivity);

  List<Site> _filteredSites = [];
  List<Site> get filteredSites => _filteredSites;

  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  int? _selectedCategoryId;
  int? get selectedCategoryId => _selectedCategoryId;
  int? _selectedSubcategoryId;
  int? get selectedSubcategoryId => _selectedSubcategoryId;
  String? _selectedSubcategory;
  String? get selectedSubcategory => _selectedSubcategory;
  String? _selectedCurationKey;
  String? get selectedCurationKey => _selectedCurationKey;
  bool _showFavoritesOnly = false;
  bool get showFavoritesOnly => _showFavoritesOnly;
  String? _selectedCity;
  String? get selectedCity => _selectedCity;
  double _minimumRating = 0;
  double get minimumRating => _minimumRating;
  SiteSortOption _selectedSort = SiteSortOption.recommended;
  SiteSortOption get selectedSort => _selectedSort;
  bool _isNearbyModeEnabled = false;
  bool get isNearbyModeEnabled => _isNearbyModeEnabled;
  double? _nearbyLatitude;
  double? _nearbyLongitude;
  bool get hasServerDistanceData => _allSites.any((site) => site.hasDistance);
  int get nearbyResultsCount =>
      _filteredSites.where((site) => site.hasDistance).length;
  bool get canUseProximitySort =>
      _isNearbyModeEnabled || hasServerDistanceData;

  String? get selectedCategoryName {
    if (_selectedCategoryId == null) {
      return null;
    }

    for (final category in _availableCategories) {
      if (category.id == _selectedCategoryId) {
        return category.name;
      }
    }

    for (final site in _allSites) {
      if (site.categoryId == _selectedCategoryId) {
        return site.category;
      }
    }

    return null;
  }

  String? get selectedSubcategoryName {
    for (final option in availableSubcategoryOptions) {
      final matchesId =
          _selectedSubcategoryId != null && option.id == _selectedSubcategoryId;
      final matchesLegacy =
          _selectedSubcategoryId == null &&
          _selectedSubcategory != null &&
          option.legacyValue?.toLowerCase() ==
              _selectedSubcategory!.toLowerCase();

      if (matchesId || matchesLegacy) {
        return option.label;
      }
    }

    return _selectedSubcategory;
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;
  Set<String> get checkedInSiteIds => _checkedInSiteIds;

  SitesProvider({
    ApiService? apiService,
    List<Site> initialSites = const <Site>[],
  }) : _apiService = apiService ?? ApiService() {
    _allSites = List<Site>.from(initialSites);
    _filteredSites = List<Site>.from(initialSites);
    _hydrateLocalState();
  }

  List<String> get categories {
    final backendCategories =
        _availableCategories
            .where((category) => category.isTopLevel)
            .map((category) => category.name.trim())
            .where((category) => category.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    if (backendCategories.isNotEmpty) {
      return backendCategories;
    }

    final Set<String> categoriesSet = _allSites
        .map((site) => site.category)
        .where((category) => category.trim().isNotEmpty)
        .toSet();
    return categoriesSet.toList()..sort();
  }

  List<SiteCategory> get topLevelCategories =>
      _availableCategories.where((category) => category.isTopLevel).toList();

  List<SiteCategory> get availableSubcategories =>
      getSubcategoriesFor(_selectedCategoryId);

  List<SiteSubcategoryOption> get availableSubcategoryOptions =>
      getSubcategoryOptionsFor(_selectedCategoryId);

  List<String> get availableCities {
    final cities =
        _allSites
            .map((site) => site.city.trim())
            .where((city) => city.isNotEmpty)
            .toSet()
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return cities;
  }

  List<Site> get favoriteSites {
    final byId = <String, Site>{for (final site in _allSites) site.id: site};
    return _favoriteSiteIds.map((id) => byId[id]).whereType<Site>().toList()
      ..sort(_compareSites);
  }

  List<Site> get recentViewedSites {
    final byId = <String, Site>{for (final site in _allSites) site.id: site};
    return _recentViewedSiteIds
        .map((id) => byId[id])
        .whereType<Site>()
        .toList();
  }

  List<Site> get recommendedSites => recommendSites();

  String get primaryLocationLabel {
    final cities = _allSites
        .map((site) => site.city.trim())
        .where((city) => city.isNotEmpty)
        .toSet();

    if (cities.length == 1) {
      return cities.first;
    }
    if (cities.length > 1) {
      return 'Maroc';
    }
    return 'Maroc';
  }

  String get secondaryLocationLabel {
    final regions = _allSites
        .map((site) => site.region.trim())
        .where((region) => region.isNotEmpty)
        .toSet();

    if (regions.length == 1) {
      return regions.first;
    }
    if (regions.length > 1) {
      return '${regions.length} regions';
    }
    return 'Donnees backend';
  }

  Future<void> getSites({
    String? city,
    int? categoryId,
    int? subcategoryId,
    String? subcategory,
    String? searchQuery,
    double? minimumRating,
    double? latitude,
    double? longitude,
    bool? useNearbyMode,
  }) async {
    try {
      _setLoading(true);
      _setError(null);

      final effectiveCategoryId = categoryId ?? _selectedCategoryId;
      final effectiveSubcategoryId = subcategoryId ?? _selectedSubcategoryId;
      final effectiveSubcategory =
          subcategory ??
          (effectiveSubcategoryId == null ? _selectedSubcategory : null);
      final effectiveSearchQuery = searchQuery ?? _searchQuery;
      final effectiveMinimumRating = minimumRating ?? _minimumRating;
      final effectiveUseNearbyMode = useNearbyMode ?? _isNearbyModeEnabled;
      final effectiveLatitude =
          latitude ?? (effectiveUseNearbyMode ? _nearbyLatitude : null);
      final effectiveLongitude =
          longitude ?? (effectiveUseNearbyMode ? _nearbyLongitude : null);
      final trimmedCity = city?.trim();
      final trimmedSubcategory = effectiveSubcategory?.trim();
      final trimmedSearchQuery = effectiveSearchQuery.trim();

      if (useNearbyMode != null) {
        _isNearbyModeEnabled = useNearbyMode;
      }

      if (effectiveUseNearbyMode &&
          effectiveLatitude != null &&
          effectiveLongitude != null) {
        _nearbyLatitude = effectiveLatitude;
        _nearbyLongitude = effectiveLongitude;
      } else if (!effectiveUseNearbyMode) {
        _nearbyLatitude = null;
        _nearbyLongitude = null;
      }

      final queryParameters = <String, dynamic>{
        if (trimmedCity?.isNotEmpty ?? false) 'city': trimmedCity,
        if (trimmedSearchQuery.isNotEmpty) 'q': trimmedSearchQuery,
        ...?effectiveCategoryId != null
            ? <String, dynamic>{'category_id': effectiveCategoryId}
            : null,
        ...?effectiveSubcategoryId != null
            ? <String, dynamic>{'subcategory_id': effectiveSubcategoryId}
            : null,
        ...?trimmedSubcategory?.isNotEmpty == true
            ? <String, dynamic>{'subcategory': trimmedSubcategory}
            : null,
        if (effectiveMinimumRating > 0)
          'min_rating': effectiveMinimumRating.toStringAsFixed(0),
        if (effectiveLatitude != null) 'lat': effectiveLatitude.toString(),
        if (effectiveLongitude != null) 'lng': effectiveLongitude.toString(),
      };

      _allSites = await _apiService.fetchSites(
        queryParameters: queryParameters,
      );
      await _ensureCategoriesLoaded();
      _applyFilters();

      _setLoading(false);
    } catch (e) {
      _setLoading(false);
      _setError(e.toString());
    }
  }

  void searchSites(String query) {
    _searchQuery = query.trim();
    _applyFilters();
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      getSites(searchQuery: _searchQuery);
    });
  }

  void filterByCategory(int? categoryId) {
    _selectedCategoryId = categoryId;
    _selectedSubcategoryId = null;
    _selectedSubcategory = null;
    _applyFilters();
    getSites(categoryId: _selectedCategoryId);
  }

  void filterBySubcategory({int? subcategoryId, String? subcategory}) {
    _selectedSubcategoryId = subcategoryId;
    _selectedSubcategory = subcategory?.trim().isEmpty == true
        ? null
        : subcategory?.trim();
    _applyFilters();
    getSites(
      categoryId: _selectedCategoryId,
      subcategoryId: _selectedSubcategoryId,
      subcategory: _selectedSubcategory,
    );
  }

  void clearFilters() {
    _searchDebounce?.cancel();
    _searchQuery = '';
    _selectedCategoryId = null;
    _selectedSubcategoryId = null;
    _selectedSubcategory = null;
    _selectedCurationKey = null;
    _showFavoritesOnly = false;
    _selectedCity = null;
    _minimumRating = 0;
    _selectedSort = SiteSortOption.recommended;
    _isNearbyModeEnabled = false;
    _nearbyLatitude = null;
    _nearbyLongitude = null;
    _applyFilters();
    getSites(useNearbyMode: false);
  }

  bool isFavorite(String siteId) => _favoriteSiteIds.contains(siteId);

  void toggleFavorite(String siteId) {
    if (_favoriteSiteIds.contains(siteId)) {
      _favoriteSiteIds.remove(siteId);
    } else {
      _favoriteSiteIds.add(siteId);
    }

    _persistFavoriteSiteIds();
    _applyFilters();
  }

  void setFavoritesOnly(bool value) {
    if (_showFavoritesOnly == value) return;
    _showFavoritesOnly = value;
    _applyFilters();
  }

  void setCityFilter(String? value) {
    final normalized = value?.trim();
    final nextValue = normalized == null || normalized.isEmpty
        ? null
        : normalized;
    if (_selectedCity == nextValue) return;
    _selectedCity = nextValue;
    _applyFilters();
    getSites(city: _selectedCity);
  }

  void setMinimumRating(double value) {
    if (_minimumRating == value) return;
    _minimumRating = value;
    _applyFilters();
    getSites(minimumRating: _minimumRating);
  }

  void setSortOption(SiteSortOption option) {
    if (_selectedSort == option) return;
    _selectedSort = option;
    _applyFilters();
  }

  Future<void> enableNearbyMode({
    required double latitude,
    required double longitude,
  }) async {
    _isNearbyModeEnabled = true;
    _nearbyLatitude = latitude;
    _nearbyLongitude = longitude;
    _selectedSort = SiteSortOption.proximity;
    notifyListeners();
    await getSites(
      latitude: latitude,
      longitude: longitude,
      useNearbyMode: true,
    );
  }

  Future<void> disableNearbyMode() async {
    final shouldResetSort = _selectedSort == SiteSortOption.proximity;
    _isNearbyModeEnabled = false;
    _nearbyLatitude = null;
    _nearbyLongitude = null;
    if (shouldResetSort) {
      _selectedSort = SiteSortOption.recommended;
    }
    notifyListeners();
    await getSites(useNearbyMode: false);
  }

  void setCuration(String? key) {
    final normalized = key?.trim().isEmpty == true ? null : key?.trim();
    if (_selectedCurationKey == normalized) return;
    _selectedCurationKey = normalized;
    _applyFilters();
  }

  void recordSiteVisit(Site site) {
    _recentViewedSiteIds.remove(site.id);
    _recentViewedSiteIds.insert(0, site.id);
    if (_recentViewedSiteIds.length > 12) {
      _recentViewedSiteIds = _recentViewedSiteIds.take(12).toList();
    }
    _persistRecentViewedSiteIds();
    notifyListeners();
  }

  void recordReviewSubmission(Site site, {required int rating}) {
    _pushActivity(
      SiteActivityEntry(
        type: SiteActivityType.review,
        siteId: site.id,
        siteName: site.name,
        city: site.city,
        metadata: <String, dynamic>{'rating': rating},
        happenedAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  List<Site> recommendSites({String? excludeSiteId, int limit = 6}) {
    final preferredCategoryIds = <int>{};
    final preferredCities = <String>{};

    for (final site in favoriteSites.take(6)) {
      if (site.categoryId != null) {
        preferredCategoryIds.add(site.categoryId!);
      }
      if (site.city.trim().isNotEmpty) {
        preferredCities.add(site.city.trim().toLowerCase());
      }
    }

    for (final site in recentViewedSites.take(6)) {
      if (site.categoryId != null) {
        preferredCategoryIds.add(site.categoryId!);
      }
      if (site.city.trim().isNotEmpty) {
        preferredCities.add(site.city.trim().toLowerCase());
      }
    }

    final candidates = _allSites.where((site) => site.id != excludeSiteId);
    final scored =
        candidates.map((site) {
          var score = 0;

          if (isFavorite(site.id)) {
            score += 5;
          }
          if (preferredCategoryIds.isNotEmpty &&
              site.categoryId != null &&
              preferredCategoryIds.contains(site.categoryId)) {
            score += 6;
          }
          if (preferredCities.contains(site.city.trim().toLowerCase())) {
            score += 4;
          }

          score += site.freshnessScore ~/ 20;
          score += site.rating.round();
          score += site.totalReviews > 0 ? 2 : 0;
          score += site.favoritesCount > 3 ? 1 : 0;

          return (site: site, score: score);
        }).toList()..sort((a, b) {
          final byScore = b.score.compareTo(a.score);
          if (byScore != 0) return byScore;
          return _compareSites(a.site, b.site);
        });

    return scored.map((item) => item.site).take(limit).toList();
  }

  Site? getSiteById(String id) {
    try {
      return _allSites.firstWhere((site) => site.id == id);
    } catch (e) {
      return null;
    }
  }

  List<SiteCategory> getSubcategoriesFor(int? categoryId) {
    if (categoryId == null) {
      return const <SiteCategory>[];
    }

    for (final category in _availableCategories) {
      if (category.id == categoryId) {
        return category.children;
      }
    }

    return const <SiteCategory>[];
  }

  List<SiteSubcategoryOption> getSubcategoryOptionsFor(int? categoryId) {
    if (categoryId == null) {
      return const <SiteSubcategoryOption>[];
    }

    final structured = getSubcategoriesFor(categoryId)
        .map(
          (category) =>
              SiteSubcategoryOption(id: category.id, label: category.name),
        )
        .toList();

    final knownLabels = structured
        .map((option) => option.label.trim().toLowerCase())
        .where((label) => label.isNotEmpty)
        .toSet();

    final legacy =
        _allSites
            .where((site) => site.categoryId == categoryId)
            .map((site) => site.subcategory?.trim())
            .whereType<String>()
            .where((value) => value.isNotEmpty)
            .map((value) => value)
            .toSet()
            .where((value) => !knownLabels.contains(value.toLowerCase()))
            .toList()
          ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return <SiteSubcategoryOption>[
      ...structured,
      ...legacy.map(
        (value) => SiteSubcategoryOption(label: value, legacyValue: value),
      ),
    ];
  }

  void _applyFilters() {
    _filteredSites = _allSites.where((site) {
      final normalizedSearchQuery = _searchQuery.toLowerCase();
      final description = site.description.toLowerCase();
      final category = site.category.toLowerCase();
      final subcategory = (site.subcategory ?? '').toLowerCase();
      final city = site.city.toLowerCase();
      final region = site.region.toLowerCase();
      final amenities = site.amenities
          .map((item) => item.toLowerCase())
          .join(' ');
      final bool matchesSearch =
          normalizedSearchQuery.isEmpty ||
          site.name.toLowerCase().contains(normalizedSearchQuery) ||
          description.contains(normalizedSearchQuery) ||
          category.contains(normalizedSearchQuery) ||
          subcategory.contains(normalizedSearchQuery) ||
          city.contains(normalizedSearchQuery) ||
          region.contains(normalizedSearchQuery) ||
          amenities.contains(normalizedSearchQuery);

      final bool matchesCategory =
          _selectedCategoryId == null || site.categoryId == _selectedCategoryId;
      final bool matchesSubcategory =
          (_selectedSubcategoryId == null &&
              (_selectedSubcategory == null ||
                  _selectedSubcategory!.isEmpty)) ||
          (_selectedSubcategoryId != null &&
              site.subcategoryId == _selectedSubcategoryId) ||
          (_selectedSubcategoryId == null &&
              _selectedSubcategory != null &&
              (site.subcategory ?? '').toLowerCase() ==
                  _selectedSubcategory!.toLowerCase());
      final bool matchesFavorites = !_showFavoritesOnly || isFavorite(site.id);
      final bool matchesCity =
          _selectedCity == null ||
          site.city.trim().toLowerCase() == _selectedCity!.toLowerCase();
      final bool matchesRating = site.rating >= _minimumRating;

      return matchesSearch &&
          matchesCategory &&
          matchesSubcategory &&
          matchesFavorites &&
          matchesCity &&
          matchesRating;
    }).toList();

    _filteredSites.sort(_compareSites);

    notifyListeners();
  }

  int _compareSites(Site a, Site b) {
    switch (_selectedSort) {
      case SiteSortOption.rating:
        final ratingCompare = b.rating.compareTo(a.rating);
        if (ratingCompare != 0) return ratingCompare;
        final reviewsCompare = b.totalReviews.compareTo(a.totalReviews);
        if (reviewsCompare != 0) return reviewsCompare;
        return b.freshnessScore.compareTo(a.freshnessScore);
      case SiteSortOption.popularity:
        final popularityCompare = b.totalReviews.compareTo(a.totalReviews);
        if (popularityCompare != 0) return popularityCompare;
        final favoritesCompare = b.favoritesCount.compareTo(a.favoritesCount);
        if (favoritesCompare != 0) return favoritesCompare;
        return b.rating.compareTo(a.rating);
      case SiteSortOption.freshness:
        final freshnessCompare = b.freshnessScore.compareTo(a.freshnessScore);
        if (freshnessCompare != 0) return freshnessCompare;
        return b.rating.compareTo(a.rating);
      case SiteSortOption.alphabetical:
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      case SiteSortOption.proximity:
        final proximityCompare = _compareByDistance(a, b);
        if (proximityCompare != 0) return proximityCompare;
        final ratingCompare = b.rating.compareTo(a.rating);
        if (ratingCompare != 0) return ratingCompare;
        return b.totalReviews.compareTo(a.totalReviews);
      case SiteSortOption.recommended:
        break;
    }

    if (_selectedCurationKey != null) {
      final curationCompare = _curationScore(
        b,
        _selectedCurationKey!,
      ).compareTo(_curationScore(a, _selectedCurationKey!));

      if (curationCompare != 0) {
        return curationCompare;
      }
    }

    final favoriteCompare = _favoriteWeight(b).compareTo(_favoriteWeight(a));
    if (favoriteCompare != 0) {
      return favoriteCompare;
    }

    final reviewCompare = b.totalReviews.compareTo(a.totalReviews);
    if (reviewCompare != 0) {
      return reviewCompare;
    }

    final followersCompare = b.favoritesCount.compareTo(a.favoritesCount);
    if (followersCompare != 0) {
      return followersCompare;
    }

    final ratingCompare = b.rating.compareTo(a.rating);
    if (ratingCompare != 0) {
      return ratingCompare;
    }

    return b.freshnessScore.compareTo(a.freshnessScore);
  }

  int _favoriteWeight(Site site) => isFavorite(site.id) ? 1 : 0;

  int _compareByDistance(Site a, Site b) {
    final aDistance = a.distanceMeters;
    final bDistance = b.distanceMeters;

    if (aDistance == null && bDistance == null) {
      return 0;
    }
    if (aDistance == null) {
      return 1;
    }
    if (bDistance == null) {
      return -1;
    }

    return aDistance.compareTo(bDistance);
  }

  int _curationScore(Site site, String key) {
    final category = site.category.toLowerCase();
    final subcategory = (site.subcategory ?? '').toLowerCase();
    final amenityText = site.amenities
        .map((item) => item.toLowerCase())
        .join(' ');

    bool matches(List<String> keywords) {
      return keywords.any(
        (keyword) =>
            category.contains(keyword) ||
            subcategory.contains(keyword) ||
            amenityText.contains(keyword),
      );
    }

    switch (key) {
      case 'famille':
        return [
          matches(['famille', 'family', 'parc']) ? 3 : 0,
          matches(['plage', 'promenade', 'pause']) ? 2 : 0,
          site.hasParking ? 1 : 0,
          site.isAccessible ? 1 : 0,
          category.contains('park') || category.contains('beach') ? 2 : 0,
        ].fold(0, (sum, value) => sum + value);
      case 'romantique':
        return [
          matches(['couple', 'coucher de soleil', 'vue marina']) ? 3 : 0,
          matches(['terrasse', 'spa', 'thalasso']) ? 2 : 0,
          category.contains('restaurant') || category.contains('hotel') ? 2 : 0,
          site.priceRange == 'EXPENSIVE' || site.priceRange == 'LUXURY' ? 2 : 0,
        ].fold(0, (sum, value) => sum + value);
      case 'culture':
        return [
          matches(['culture', 'artisanat', 'architecture', 'medina']) ? 3 : 0,
          matches(['museum', 'historical', 'religious', 'site historique'])
              ? 3
              : 0,
          category.contains('museum') ||
                  category.contains('historical') ||
                  category.contains('religious')
              ? 2
              : 0,
        ].fold(0, (sum, value) => sum + value);
      case 'luxe':
        return [
          site.priceRange == 'LUXURY' ? 4 : 0,
          site.priceRange == 'EXPENSIVE' ? 3 : 0,
          matches(['spa', 'thalasso', 'all inclusive', 'marina']) ? 2 : 0,
          category.contains('hotel') ? 2 : 0,
          site.acceptsCardPayment ? 1 : 0,
        ].fold(0, (sum, value) => sum + value);
      default:
        return 0;
    }
  }

  void _hydrateLocalState() {
    _favoriteSiteIds = _decodeStringSet(_favoriteSiteIdsKey);
    _recentViewedSiteIds = _decodeStringList(_recentViewedSiteIdsKey);

    final rawActivity = StorageService().getString(_recentActivityKey);
    if (rawActivity == null || rawActivity.trim().isEmpty) {
      return;
    }

    try {
      final decoded = jsonDecode(rawActivity);
      if (decoded is List) {
        _recentActivity = decoded
            .whereType<Map>()
            .map(
              (item) => SiteActivityEntry.fromJson(
                item.map((key, value) => MapEntry(key.toString(), value)),
              ),
            )
            .toList();
      }
    } catch (_) {
      _recentActivity = <SiteActivityEntry>[];
    }
  }

  Future<void> _ensureCategoriesLoaded() async {
    if (_availableCategories.isNotEmpty) {
      return;
    }

    try {
      _availableCategories = await _apiService.fetchCategories(
        topLevelOnly: true,
      );
    } catch (_) {
      _availableCategories = const <SiteCategory>[];
    }
  }

  Future<void> _persistFavoriteSiteIds() async {
    final serialized = jsonEncode(_favoriteSiteIds.toList()..sort());
    await StorageService().saveString(_favoriteSiteIdsKey, serialized);
  }

  Future<void> _persistRecentViewedSiteIds() async {
    final serialized = jsonEncode(_recentViewedSiteIds);
    await StorageService().saveString(_recentViewedSiteIdsKey, serialized);
  }

  Future<void> _persistRecentActivity() async {
    final serialized = jsonEncode(
      _recentActivity.map((entry) => entry.toJson()).toList(),
    );
    await StorageService().saveString(_recentActivityKey, serialized);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void markSiteCheckedIn(String siteId, {String? siteName}) {
    _checkedInSiteIds.add(siteId);
    final site =
        getSiteById(siteId) ??
        Site(
          id: siteId,
          name: siteName ?? 'Site',
          description: '',
          category: '',
          imageUrl: '',
          address: '',
          city: '',
          region: '',
          latitude: 0,
          longitude: 0,
          freshnessScore: 0,
          rating: 0,
        );
    _pushActivity(
      SiteActivityEntry(
        type: SiteActivityType.checkin,
        siteId: site.id,
        siteName: site.name,
        city: site.city,
        happenedAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  Set<String> _decodeStringSet(String key) {
    return _decodeStringList(key).toSet();
  }

  List<String> _decodeStringList(String key) {
    final raw = StorageService().getString(key);
    if (raw == null || raw.trim().isEmpty) {
      return <String>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map((item) => '$item'.trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
    } catch (_) {
      return <String>[];
    }

    return <String>[];
  }

  void _pushActivity(SiteActivityEntry entry) {
    _recentActivity.insert(0, entry);
    if (_recentActivity.length > 20) {
      _recentActivity = _recentActivity.take(20).toList();
    }
    _persistRecentActivity();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}

class SiteSubcategoryOption {
  final int? id;
  final String label;
  final String? legacyValue;

  const SiteSubcategoryOption({this.id, required this.label, this.legacyValue});
}

class SiteCurationOption {
  final String key;
  final String label;
  final IconData icon;

  const SiteCurationOption({
    required this.key,
    required this.label,
    required this.icon,
  });
}

enum SiteSortOption {
  recommended,
  proximity,
  rating,
  popularity,
  freshness,
  alphabetical,
}

enum SiteActivityType { checkin, review }

class SiteActivityEntry {
  final SiteActivityType type;
  final String siteId;
  final String siteName;
  final String city;
  final DateTime happenedAt;
  final Map<String, dynamic> metadata;

  const SiteActivityEntry({
    required this.type,
    required this.siteId,
    required this.siteName,
    required this.city,
    required this.happenedAt,
    this.metadata = const <String, dynamic>{},
  });

  factory SiteActivityEntry.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String? ?? 'checkin';
    return SiteActivityEntry(
      type: typeName == 'review'
          ? SiteActivityType.review
          : SiteActivityType.checkin,
      siteId: json['site_id'] as String? ?? '',
      siteName: json['site_name'] as String? ?? 'Site',
      city: json['city'] as String? ?? '',
      happenedAt:
          DateTime.tryParse(json['happened_at'] as String? ?? '') ??
          DateTime.now(),
      metadata:
          (json['metadata'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value),
          ) ??
          const <String, dynamic>{},
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type.name,
      'site_id': siteId,
      'site_name': siteName,
      'city': city,
      'happened_at': happenedAt.toIso8601String(),
      'metadata': metadata,
    };
  }
}
