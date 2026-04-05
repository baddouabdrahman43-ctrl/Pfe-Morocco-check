import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/models/site_category.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../sites/presentation/sites/site.dart';
import '../../sites/presentation/sites_provider.dart';
import 'map_provider.dart';

enum _FreshnessFilter { all, fresh, moderate, stale }

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const LatLng _defaultCenter = LatLng(
    AppConstants.focusLatitude,
    AppConstants.focusLongitude,
  );
  static const double _agadirZoom = 11.8;
  final MapController _mapController = MapController();

  int? _selectedCategoryId;
  int? _selectedSubcategoryId;
  String? _selectedLegacySubcategory;
  String? _selectedSiteFilterId;
  _FreshnessFilter _freshnessFilter = _FreshnessFilter.all;
  Site? _selectedSite;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final mapProvider = context.read<MapProvider>();
      final sitesProvider = context.read<SitesProvider>();

      await mapProvider.getUserLocation();
      await sitesProvider.getSites(
        city: AppConstants.focusCity,
        useNearbyMode: false,
      );
    });
  }

  Color _markerColorForScore(int score) {
    if (score >= 70) return AppColors.freshnessGreen;
    if (score >= 40) return AppColors.freshnessOrange;
    return AppColors.freshnessRed;
  }

  bool _isAgadirSite(Site site) {
    final city = site.city.trim().toLowerCase();
    final region = site.region.trim().toLowerCase();
    return city == AppConstants.focusCity.toLowerCase() ||
        region == AppConstants.focusRegion.toLowerCase();
  }

  bool _matchesCategoryFilters(Site site) {
    final matchesCategory =
        _selectedCategoryId == null || site.categoryId == _selectedCategoryId;
    final matchesSubcategory =
        (_selectedSubcategoryId == null &&
            (_selectedLegacySubcategory == null ||
                _selectedLegacySubcategory!.isEmpty)) ||
        (_selectedSubcategoryId != null &&
            site.subcategoryId == _selectedSubcategoryId) ||
        (_selectedSubcategoryId == null &&
            _selectedLegacySubcategory != null &&
            (site.subcategory ?? '').toLowerCase() ==
                _selectedLegacySubcategory!.toLowerCase());

    return matchesCategory && matchesSubcategory;
  }

  bool _matchesFreshnessFilter(Site site) {
    return switch (_freshnessFilter) {
      _FreshnessFilter.all => true,
      _FreshnessFilter.fresh => site.freshnessScore >= 70,
      _FreshnessFilter.moderate =>
        site.freshnessScore >= 40 && site.freshnessScore < 70,
      _FreshnessFilter.stale => site.freshnessScore < 40,
    };
  }

  List<Site> _visibleSites(List<Site> sites) {
    return sites.where((site) {
      if (!_isAgadirSite(site)) {
        return false;
      }

      final matchesSiteFilter =
          _selectedSiteFilterId == null || site.id == _selectedSiteFilterId;

      return _matchesCategoryFilters(site) &&
          _matchesFreshnessFilter(site) &&
          matchesSiteFilter;
    }).toList();
  }

  List<Site> _sitesForFilterPicker(List<Site> sites, String query) {
    final normalizedQuery = query.trim().toLowerCase();

    return sites.where((site) {
      if (!_isAgadirSite(site) ||
          !_matchesCategoryFilters(site) ||
          !_matchesFreshnessFilter(site)) {
        return false;
      }

      if (normalizedQuery.isEmpty) {
        return true;
      }

      final haystack = [
        site.name,
        site.category,
        site.subcategory ?? '',
        site.city,
        site.address,
      ].join(' ').toLowerCase();

      return haystack.contains(normalizedQuery);
    }).toList();
  }

  List<Marker> _buildMarkers(MapProvider mapProvider, List<Site> sites) {
    final List<Marker> markers = sites.map((site) {
      final isSelected = _selectedSite?.id == site.id;
      return Marker(
        point: LatLng(site.latitude, site.longitude),
        width: isSelected ? 92 : 74,
        height: isSelected ? 98 : 82,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedSite = site;
            });
          },
          child: _MapSiteMarker(
            color: _markerColorForScore(site.freshnessScore),
            score: site.freshnessScore,
            isSelected: isSelected,
          ),
        ),
      );
    }).toList();

    if (mapProvider.currentPosition != null) {
      markers.add(
        Marker(
          point: LatLng(
            mapProvider.currentPosition!.latitude,
            mapProvider.currentPosition!.longitude,
          ),
          width: 52,
          height: 52,
          child: const _CurrentLocationMarker(),
        ),
      );
    }

    return markers;
  }

  void _clearSelectedSite() {
    if (_selectedSite == null) return;
    setState(() {
      _selectedSite = null;
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedCategoryId = null;
      _selectedSubcategoryId = null;
      _selectedLegacySubcategory = null;
      _selectedSiteFilterId = null;
      _freshnessFilter = _FreshnessFilter.all;
      _selectedSite = null;
    });
  }

  void _focusOnSite(Site site, {double zoom = 15.2}) {
    _mapController.move(LatLng(site.latitude, site.longitude), zoom);
    setState(() {
      _selectedSite = site;
    });
  }

  void _focusOnAgadir() {
    _mapController.move(_defaultCenter, _agadirZoom);
    setState(() {
      _selectedSite = null;
    });
  }

  int get _activeFilterCount {
    var count = 0;
    if (_selectedCategoryId != null) count++;
    if (_selectedSubcategoryId != null ||
        (_selectedLegacySubcategory != null &&
            _selectedLegacySubcategory!.isNotEmpty)) {
      count++;
    }
    if (_selectedSiteFilterId != null) count++;
    if (_freshnessFilter != _FreshnessFilter.all) count++;
    return count;
  }

  Future<void> _openFiltersSheet(SitesProvider sitesProvider) async {
    final colorScheme = Theme.of(context).colorScheme;
    var siteSearchQuery = '';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      showDragHandle: true,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void refreshFilters(VoidCallback update) {
              setState(update);
              setSheetState(() {});
            }

            return SafeArea(
              child: FractionallySizedBox(
                heightFactor: 0.88,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  child: _buildFilterSheetContent(
                    sitesProvider,
                    refreshFilters,
                    siteSearchQuery,
                    (value) => setSheetState(() => siteSearchQuery = value),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<MapProvider, SitesProvider>(
      builder: (context, mapProvider, sitesProvider, child) {
        final agadirSites = sitesProvider.sites
            .where(_isAgadirSite)
            .toList(growable: false);
        final visibleSites = _visibleSites(agadirSites);
        final selectedVisibleSite =
            _selectedSite != null &&
                visibleSites.any((site) => site.id == _selectedSite!.id)
            ? _selectedSite
            : null;

        return Scaffold(
          backgroundColor: AppColors.primaryDeep,
          body: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _defaultCenter,
                  initialZoom: _agadirZoom,
                  onTap: (_, point) => _clearSelectedSite(),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    fallbackUrl:
                        'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                    subdomains: const ['a', 'b', 'c'],
                    userAgentPackageName: 'com.moroccocheck.app',
                    tileProvider: NetworkTileProvider(),
                    errorTileCallback: (tile, error, stackTrace) {
                      debugPrint(
                        'Map tile error (${tile.coordinates}): $error',
                      );
                    },
                  ),
                  MarkerLayer(
                    markers: _buildMarkers(mapProvider, visibleSites),
                  ),
                ],
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    children: [
                      _buildFloatingActionChip(
                        icon: Icons.map_rounded,
                        label: 'Agadir',
                        onTap: _focusOnAgadir,
                      ),
                      const Spacer(),
                      _buildFloatingActionChip(
                        icon: Icons.tune,
                        label: _activeFilterCount > 0
                            ? 'Filtres ($_activeFilterCount)'
                            : 'Filtres',
                        highlighted: true,
                        onTap: () => _openFiltersSheet(sitesProvider),
                      ),
                    ],
                  ),
                ),
              ),
              if (selectedVisibleSite != null)
                SafeArea(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      child: _buildSelectedSiteCard(selectedVisibleSite),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterSheetContent(
    SitesProvider sitesProvider,
    void Function(VoidCallback update) refreshFilters,
    String siteSearchQuery,
    ValueChanged<String> onSiteSearchChanged,
  ) {
    final agadirSites = sitesProvider.sites
        .where(_isAgadirSite)
        .toList(growable: false);
    final subcategoryOptions = sitesProvider.getSubcategoryOptionsFor(
      _selectedCategoryId,
    );
    final filterableSites = _sitesForFilterPicker(agadirSites, siteSearchQuery);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.tune, color: AppColors.primary, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Filtres de voyage', style: AppTextStyles.bodyStrong),
            ),
            if (_activeFilterCount > 0)
              TextButton(
                onPressed: () => refreshFilters(_resetFilters),
                child: const Text('Effacer'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Sites',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: onSiteSearchChanged,
          decoration: InputDecoration(
            hintText: 'Rechercher un site...',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildCategoryChip('Tous les sites', _selectedSiteFilterId == null, () {
          refreshFilters(() {
            _selectedSiteFilterId = null;
          });
        }),
        const SizedBox(height: 10),
        if (filterableSites.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              siteSearchQuery.trim().isEmpty
                  ? 'Aucun site ne correspond aux filtres actuels.'
                  : 'Aucun site trouvé pour cette recherche.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: filterableSites.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final site = filterableSites[index];
                final isSelected = _selectedSiteFilterId == site.id;
                return _buildSiteFilterTile(
                  site: site,
                  isSelected: isSelected,
                  onTap: () {
                    refreshFilters(() {
                      _selectedSiteFilterId = isSelected ? null : site.id;
                      _selectedSite = site;
                    });
                    _focusOnSite(site);
                  },
                );
              },
            ),
          ),
        const SizedBox(height: 18),
        Text(
          'Catégories',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildCategoryChip('Toutes', _selectedCategoryId == null, () {
              refreshFilters(() {
                _selectedCategoryId = null;
                _selectedSubcategoryId = null;
                _selectedLegacySubcategory = null;
                _selectedSiteFilterId = null;
              });
            }),
            ...sitesProvider.topLevelCategories.map(
              (SiteCategory category) => _buildCategoryChip(
                category.name,
                _selectedCategoryId == category.id,
                () {
                  refreshFilters(() {
                    _selectedCategoryId = category.id;
                    _selectedSubcategoryId = null;
                    _selectedLegacySubcategory = null;
                    if (_selectedSiteFilterId != null &&
                        !agadirSites.any(
                          (site) =>
                              site.id == _selectedSiteFilterId &&
                              site.categoryId == category.id,
                        )) {
                      _selectedSiteFilterId = null;
                    }
                  });
                },
              ),
            ),
          ],
        ),
        if (_selectedCategoryId != null && subcategoryOptions.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            'Sous-categories',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildCategoryChip(
                'Toutes sous-categories',
                _selectedSubcategoryId == null &&
                    (_selectedLegacySubcategory == null ||
                        _selectedLegacySubcategory!.isEmpty),
                () {
                  refreshFilters(() {
                    _selectedSubcategoryId = null;
                    _selectedLegacySubcategory = null;
                  });
                },
              ),
              ...subcategoryOptions.map(
                (SiteSubcategoryOption option) => _buildCategoryChip(
                  option.label,
                  option.id != null
                      ? _selectedSubcategoryId == option.id
                      : _selectedSubcategoryId == null &&
                            _selectedLegacySubcategory?.toLowerCase() ==
                                option.legacyValue?.toLowerCase(),
                  () {
                    refreshFilters(() {
                      _selectedSubcategoryId = option.id;
                      _selectedLegacySubcategory = option.legacyValue;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
        if (sitesProvider.availableCategories.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Categories backend indisponibles pour le moment.',
              style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
            ),
          ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildFreshnessChip(
              label: 'Tous',
              color: Colors.grey,
              selected: _freshnessFilter == _FreshnessFilter.all,
              onTap: () {
                refreshFilters(() {
                  _freshnessFilter = _FreshnessFilter.all;
                });
              },
            ),
            _buildFreshnessChip(
              label: 'Frais',
              color: AppColors.freshnessGreen,
              selected: _freshnessFilter == _FreshnessFilter.fresh,
              onTap: () {
                refreshFilters(() {
                  _freshnessFilter = _FreshnessFilter.fresh;
                });
              },
            ),
            _buildFreshnessChip(
              label: 'Moyen',
              color: AppColors.freshnessOrange,
              selected: _freshnessFilter == _FreshnessFilter.moderate,
              onTap: () {
                refreshFilters(() {
                  _freshnessFilter = _FreshnessFilter.moderate;
                });
              },
            ),
            _buildFreshnessChip(
              label: 'A verifier',
              color: AppColors.freshnessRed,
              selected: _freshnessFilter == _FreshnessFilter.stale,
              onTap: () {
                refreshFilters(() {
                  _freshnessFilter = _FreshnessFilter.stale;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          'Sites',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          onChanged: onSiteSearchChanged,
          decoration: InputDecoration(
            hintText: 'Rechercher un site...',
            prefixIcon: const Icon(Icons.search_rounded),
            filled: true,
            fillColor: AppColors.background,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildCategoryChip('Tous les sites', _selectedSiteFilterId == null, () {
          refreshFilters(() {
            _selectedSiteFilterId = null;
          });
        }),
        const SizedBox(height: 10),
        if (filterableSites.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              siteSearchQuery.trim().isEmpty
                  ? 'Aucun site ne correspond aux filtres actuels.'
                  : 'Aucun site trouvé pour cette recherche.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          )
        else
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: filterableSites.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final site = filterableSites[index];
                final isSelected = _selectedSiteFilterId == site.id;
                return _buildSiteFilterTile(
                  site: site,
                  isSelected: isSelected,
                  onTap: () {
                    refreshFilters(() {
                      _selectedSiteFilterId = isSelected ? null : site.id;
                      _selectedSite = site;
                    });
                    _focusOnSite(site);
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primaryDeep,
      checkmarkColor: Colors.white,
      labelStyle: AppTextStyles.caption.copyWith(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primaryDeep : AppColors.border,
      ),
    );
  }

  Widget _buildFreshnessChip({
    required String label,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: selected ? Colors.white : color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool highlighted = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: highlighted
                ? const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryDeep, AppColors.primary],
                  )
                : null,
            color: highlighted
                ? null
                : AppColors.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: highlighted
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: 0.72),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: highlighted ? Colors.white : AppColors.primaryDeep,
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: AppTextStyles.body.copyWith(
                  color: highlighted ? Colors.white : AppColors.primaryDeep,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedSiteCard(Site site) {
    final imageUrl = site.previewPhotos.isNotEmpty
        ? site.previewPhotos.first
        : site.imageUrl;
    final subtitle = [
      if (site.category.isNotEmpty) site.category,
      if (site.subcategory?.isNotEmpty ?? false) site.subcategory!,
    ].join(' • ');
    final locationLine = [
      if (site.address.isNotEmpty) site.address,
      if (site.city.isNotEmpty) site.city,
    ].join(', ');

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Material(
        key: ValueKey(site.id),
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => context.push('/sites/${site.id}'),
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      width: 88,
                      height: 88,
                      child: imageUrl.isNotEmpty
                          ? AppNetworkImage(
                              imageUrl: imageUrl,
                              fallback: _SelectedSiteImagePlaceholder(
                                color: _markerColorForScore(
                                  site.freshnessScore,
                                ),
                              ),
                            )
                          : _SelectedSiteImagePlaceholder(
                              color: _markerColorForScore(site.freshnessScore),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                site.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodyStrong.copyWith(
                                  fontSize: 17,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: _clearSelectedSite,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primaryDeep,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildSiteInfoPill(
                              Icons.star_rounded,
                              site.rating.toStringAsFixed(1),
                              AppColors.accentGold,
                            ),
                            _buildSiteInfoPill(
                              Icons.verified_rounded,
                              '${site.freshnessScore}%',
                              _markerColorForScore(site.freshnessScore),
                            ),
                            if (site.hasDistance)
                              _buildSiteInfoPill(
                                Icons.near_me_rounded,
                                site.formattedDistance,
                                AppColors.primary,
                              ),
                          ],
                        ),
                        if (locationLine.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.place_outlined,
                                size: 14,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  locationLine,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption.copyWith(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSiteInfoPill(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSiteFilterTile({
    required Site site,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final imageUrl = site.previewPhotos.isNotEmpty
        ? site.previewPhotos.first
        : site.imageUrl;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: imageUrl.isNotEmpty
                      ? AppNetworkImage(
                          imageUrl: imageUrl,
                          fallback: _SelectedSiteImagePlaceholder(
                            color: _markerColorForScore(site.freshnessScore),
                          ),
                        )
                      : _SelectedSiteImagePlaceholder(
                          color: _markerColorForScore(site.freshnessScore),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      site.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodyStrong.copyWith(fontSize: 15),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (site.category.isNotEmpty) site.category,
                        if (site.city.isNotEmpty) site.city,
                      ].join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: isSelected ? AppColors.primary : AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MapSiteMarker extends StatelessWidget {
  final Color color;
  final int score;
  final bool isSelected;

  const _MapSiteMarker({
    required this.color,
    required this.score,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      scale: isSelected ? 1.1 : 1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryDeep,
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Text(
                '$score%',
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Stack(
            alignment: Alignment.center,
            children: [
              if (isSelected)
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.16),
                  ),
                ),
              Icon(
                Icons.place_rounded,
                size: isSelected ? 40 : 34,
                color: color,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CurrentLocationMarker extends StatelessWidget {
  const _CurrentLocationMarker();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: 18,
              spreadRadius: 6,
            ),
          ],
        ),
      ),
    );
  }
}

class _SelectedSiteImagePlaceholder extends StatelessWidget {
  final Color color;

  const _SelectedSiteImagePlaceholder({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.22), AppColors.surfaceAlt],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.place_rounded, size: 34, color: color),
    );
  }
}
