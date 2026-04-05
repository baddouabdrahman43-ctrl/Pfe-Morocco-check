import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/site_preview_card.dart';
import '../../../shared/models/site_category.dart';
import '../../map/presentation/map_provider.dart';
import 'sites/site.dart';
import 'sites_provider.dart';

class SitesListScreen extends StatefulWidget {
  const SitesListScreen({super.key});

  @override
  State<SitesListScreen> createState() => _SitesListScreenState();
}

class _SitesListScreenState extends State<SitesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isApplyingNearbyMode = false;
  bool _showAdvancedFilters = false;
  static const List<SiteCurationOption> _curationOptions = [
    SiteCurationOption(
      key: 'famille',
      label: 'Famille',
      icon: Icons.family_restroom_outlined,
    ),
    SiteCurationOption(
      key: 'romantique',
      label: 'Romantique',
      icon: Icons.nightlight_round,
    ),
    SiteCurationOption(
      key: 'culture',
      label: 'Culture',
      icon: Icons.museum_outlined,
    ),
    SiteCurationOption(
      key: 'luxe',
      label: 'Luxe',
      icon: Icons.diamond_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SitesProvider>().getSites();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    context.read<SitesProvider>().searchSites(query);
    setState(() {});
  }

  void _onCategorySelected(int? categoryId) {
    context.read<SitesProvider>().filterByCategory(categoryId);
  }

  void _onSubcategorySelected({int? subcategoryId, String? subcategory}) {
    context.read<SitesProvider>().filterBySubcategory(
      subcategoryId: subcategoryId,
      subcategory: subcategory,
    );
  }

  void _onSiteTap(String siteId) {
    context.push('/sites/$siteId');
  }

  void _toggleFavorite(String siteId) {
    context.read<SitesProvider>().toggleFavorite(siteId);
  }

  Future<void> _refreshSites() async {
    await context.read<SitesProvider>().getSites();
  }

  Future<void> _toggleNearbyMode(SitesProvider sitesProvider) async {
    if (_isApplyingNearbyMode) return;

    if (sitesProvider.isNearbyModeEnabled) {
      await _disableNearbyMode(sitesProvider);
      return;
    }

    await _enableNearbyMode(sitesProvider);
  }

  Future<void> _enableNearbyMode(
    SitesProvider sitesProvider, {
    bool showSuccessMessage = true,
  }) async {
    setState(() {
      _isApplyingNearbyMode = true;
    });

    try {
      final mapProvider = context.read<MapProvider>();
      await mapProvider.getUserLocation();
      if (!mounted) return;

      final position = mapProvider.currentPosition;
      if (position == null) {
        throw Exception(
          mapProvider.error ??
              'Impossible de recuperer votre position pour le moment.',
        );
      }

      await sitesProvider.enableNearbyMode(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!mounted || !showSuccessMessage) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tri Proximite active par defaut. Les distances serveur sont maintenant visibles.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_normalizeErrorMessage(error.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isApplyingNearbyMode = false;
        });
      }
    }
  }

  Future<void> _disableNearbyMode(SitesProvider sitesProvider) async {
    setState(() {
      _isApplyingNearbyMode = true;
    });

    try {
      await sitesProvider.disableNearbyMode();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mode autour de moi retire.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isApplyingNearbyMode = false;
        });
      }
    }
  }

  Future<void> _onSortChanged(
    SiteSortOption option,
    SitesProvider sitesProvider,
  ) async {
    if (option == SiteSortOption.proximity &&
        !sitesProvider.isNearbyModeEnabled) {
      await _enableNearbyMode(sitesProvider, showSuccessMessage: false);
      return;
    }

    sitesProvider.setSortOption(option);
  }

  bool _shouldHideDiscoveryRail(SitesProvider sitesProvider) {
    return sitesProvider.searchQuery.isNotEmpty ||
        sitesProvider.selectedCategoryId != null ||
        sitesProvider.selectedSubcategoryId != null ||
        (sitesProvider.selectedSubcategory?.isNotEmpty ?? false);
  }

  List<Site> _discoveryRailSites(SitesProvider sitesProvider) {
    final seenIds = <String>{};
    final merged = <Site>[
      ...sitesProvider.recommendedSites,
      ...sitesProvider.recentViewedSites,
    ];

    return merged.where((site) => seenIds.add(site.id)).take(6).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Explorer les lieux')),
      floatingActionButton: Consumer<SitesProvider>(
        builder: (context, sitesProvider, child) {
          return FloatingActionButton.extended(
            onPressed: _isApplyingNearbyMode
                ? null
                : () => _toggleNearbyMode(sitesProvider),
            backgroundColor: sitesProvider.isNearbyModeEnabled
                ? AppColors.primaryDeep
                : AppColors.primary,
            foregroundColor: Colors.white,
            icon: _isApplyingNearbyMode
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(
                    sitesProvider.isNearbyModeEnabled
                        ? Icons.near_me_rounded
                        : Icons.my_location_rounded,
                  ),
            label: Text(
              sitesProvider.isNearbyModeEnabled
                  ? 'Proximite active'
                  : 'Autour de moi',
            ),
          );
        },
      ),
      body: Consumer<SitesProvider>(
        builder: (context, sitesProvider, child) {
          final nearestSite = _nearestSite(sitesProvider.filteredSites);
          final discoveryRailSites = _discoveryRailSites(sitesProvider);
          final showDiscoveryRail =
              discoveryRailSites.isNotEmpty &&
              !_shouldHideDiscoveryRail(sitesProvider);

          if (sitesProvider.isLoading && sitesProvider.sites.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (sitesProvider.error != null && sitesProvider.sites.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off_outlined,
                      size: 64,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      sitesProvider.error!,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _refreshSites,
                      child: const Text('Reessayer'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshSites,
            child: ListView(
              padding: const EdgeInsets.only(bottom: 108),
              children: [
                _buildHeroCard(sitesProvider),
                _buildSearchSection(),
                _buildAdvancedFiltersSection(sitesProvider),
                if (showDiscoveryRail)
                  _buildSiteRail(
                    title: 'A reprendre',
                    subtitle:
                        'Suggestions et lieux recemment consultes dans une meme section.',
                    sites: discoveryRailSites,
                    sitesProvider: sitesProvider,
                  ),
                _buildSectionHeading(
                  title: 'Categories',
                  subtitle: 'Affinez rapidement la liste par famille de lieux.',
                ),
                SizedBox(
                  height: 54,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildCategoryChip(
                        label: 'Tous',
                        isSelected: sitesProvider.selectedCategoryId == null,
                        onTap: () => _onCategorySelected(null),
                      ),
                      const SizedBox(width: 8),
                      ...sitesProvider.topLevelCategories.map(
                        (SiteCategory category) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildCategoryChip(
                            label: category.name,
                            isSelected:
                                sitesProvider.selectedCategoryId == category.id,
                            onTap: () => _onCategorySelected(category.id),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (sitesProvider.availableCategories.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    child: Text(
                      'Les categories backend ne sont pas disponibles pour le moment.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                if (sitesProvider.selectedCategoryId != null &&
                    sitesProvider.availableSubcategoryOptions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: SizedBox(
                      height: 54,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildCategoryChip(
                            label: 'Toutes sous-categories',
                            isSelected:
                                sitesProvider.selectedSubcategoryId == null &&
                                (sitesProvider.selectedSubcategory == null ||
                                    sitesProvider.selectedSubcategory!.isEmpty),
                            onTap: () =>
                                _onSubcategorySelected(subcategoryId: null),
                          ),
                          const SizedBox(width: 8),
                          ...sitesProvider.availableSubcategoryOptions.map(
                            (SiteSubcategoryOption option) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _buildCategoryChip(
                                label: option.label,
                                isSelected: option.id != null
                                    ? sitesProvider.selectedSubcategoryId ==
                                          option.id
                                    : sitesProvider.selectedSubcategoryId ==
                                              null &&
                                          sitesProvider.selectedSubcategory
                                                  ?.toLowerCase() ==
                                              option.legacyValue?.toLowerCase(),
                                onTap: () => _onSubcategorySelected(
                                  subcategoryId: option.id,
                                  subcategory: option.legacyValue,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                _buildSectionHeading(
                  title: 'Selections',
                  subtitle: 'Raccourcis utiles pour retrouver vos preferences.',
                ),
                SizedBox(
                  height: 54,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _buildCategoryChip(
                        label: 'Tout voir',
                        isSelected: sitesProvider.selectedCurationKey == null,
                        onTap: () => sitesProvider.setCuration(null),
                      ),
                      const SizedBox(width: 8),
                      _buildCategoryChip(
                        label: 'Mes favoris',
                        icon: Icons.favorite_border_rounded,
                        isSelected: sitesProvider.showFavoritesOnly,
                        onTap: () => sitesProvider.setFavoritesOnly(
                          !sitesProvider.showFavoritesOnly,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ..._curationOptions.map(
                        (option) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildCategoryChip(
                            label: option.label,
                            icon: option.icon,
                            isSelected:
                                sitesProvider.selectedCurationKey == option.key,
                            onTap: () => sitesProvider.setCuration(option.key),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                  child: Row(
                    children: [
                      Text(
                        '${sitesProvider.filteredSites.length} resultat${sitesProvider.filteredSites.length > 1 ? 's' : ''}',
                        style: AppTextStyles.bodyStrong.copyWith(fontSize: 18),
                      ),
                      const Spacer(),
                      if (sitesProvider.searchQuery.isNotEmpty ||
                          sitesProvider.selectedCategoryId != null ||
                          sitesProvider.selectedSubcategoryId != null ||
                          sitesProvider.selectedCurationKey != null ||
                          sitesProvider.selectedCity != null ||
                          sitesProvider.minimumRating > 0 ||
                          sitesProvider.isNearbyModeEnabled ||
                          sitesProvider.selectedSort !=
                              SiteSortOption.recommended ||
                          sitesProvider.showFavoritesOnly ||
                          (sitesProvider.selectedSubcategory != null &&
                              sitesProvider.selectedSubcategory!.isNotEmpty))
                        TextButton.icon(
                          onPressed: () {
                            _searchController.clear();
                            sitesProvider.clearFilters();
                            setState(() {});
                          },
                          icon: const Icon(Icons.restart_alt, size: 18),
                          label: const Text('Reinitialiser'),
                        ),
                    ],
                  ),
                ),
                if (sitesProvider.isNearbyModeEnabled && nearestSite != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _buildNearbySummaryCard(
                      sitesProvider: sitesProvider,
                      nearestSite: nearestSite,
                    ),
                  ),
                if (sitesProvider.filteredSites.isEmpty)
                  _buildEmptyState()
                else
                  ...sitesProvider.filteredSites.map(
                    (site) => SitePreviewCard(
                      site: site,
                      onTap: () => _onSiteTap(site.id),
                      isFavorite: sitesProvider.isFavorite(site.id),
                      onToggleFavorite: () => _toggleFavorite(site.id),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdvancedFiltersSection(SitesProvider sitesProvider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () {
              setState(() {
                _showAdvancedFilters = !_showAdvancedFilters;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune, color: AppColors.primaryDeep),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filtres avances',
                          style: AppTextStyles.bodyStrong.copyWith(
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _showAdvancedFilters
                              ? 'Masquer les options de tri et de localisation'
                              : 'Afficher les options de tri, de note et de localisation',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _showAdvancedFilters
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primaryDeep,
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _buildAdvancedFilters(sitesProvider),
            crossFadeState: _showAdvancedFilters
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 180),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(SitesProvider sitesProvider) {
    final nearestSite = _nearestSite(sitesProvider.filteredSites);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF8FFFB), Color(0xFFE8F7F0)],
        ),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryDeep,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.travel_explore,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  sitesProvider.isNearbyModeEnabled
                      ? 'Lieux proches de vous a ${sitesProvider.primaryLocationLabel}'
                      : 'Lieux a consulter a ${sitesProvider.primaryLocationLabel}',
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 24,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            sitesProvider.isNearbyModeEnabled
                ? 'Le tri par proximite est actif et les distances sont visibles dans chaque fiche.'
                : 'Consultez les lieux verifies, filtrez la liste et accedez rapidement aux fiches les plus utiles.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _summaryPill(
                icon: Icons.layers_outlined,
                label: '${sitesProvider.categories.length} categories',
              ),
              _summaryPill(
                icon: Icons.verified_outlined,
                label: '${sitesProvider.sites.length} lieux recommandes',
              ),
              _summaryPill(
                icon: Icons.favorite_outline,
                label: '${sitesProvider.favoritesCount} favoris sauvegardes',
              ),
              _summaryPill(
                icon: Icons.route_outlined,
                label: sitesProvider.isNearbyModeEnabled && nearestSite != null
                    ? 'Plus proche ${nearestSite.formattedDistance}'
                    : sitesProvider.selectedCurationKey == null
                    ? sitesProvider.secondaryLocationLabel
                    : 'Tri ${_curationLabelFor(sitesProvider.selectedCurationKey!)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedFilters(SitesProvider sitesProvider) {
    final nearestSite = _nearestSite(sitesProvider.filteredSites);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filtres avances',
              style: AppTextStyles.bodyStrong.copyWith(fontSize: 17),
            ),
            const SizedBox(height: 6),
            Text(
              sitesProvider.isNearbyModeEnabled
                  ? 'La proximite serveur est active. Vous pouvez continuer a filtrer sans perdre les distances.'
                  : 'Affinez la liste par ville, note minimum et mode de tri.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF4FBF8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sitesProvider.isNearbyModeEnabled
                      ? AppColors.primary
                      : AppColors.border,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: sitesProvider.isNearbyModeEnabled
                              ? AppColors.primaryDeep
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          sitesProvider.isNearbyModeEnabled
                              ? Icons.near_me_rounded
                              : Icons.my_location_outlined,
                          color: sitesProvider.isNearbyModeEnabled
                              ? Colors.white
                              : AppColors.primaryDeep,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Autour de moi',
                              style: AppTextStyles.bodyStrong.copyWith(
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              sitesProvider.isNearbyModeEnabled
                                  ? 'Le backend renvoie maintenant les distances serveur pour chaque site.'
                                  : 'Activez votre position pour voir les lieux a proximite et debloquer le tri Proximite.',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_isApplyingNearbyMode)
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      else if (sitesProvider.isNearbyModeEnabled)
                        OutlinedButton.icon(
                          onPressed: () => _toggleNearbyMode(sitesProvider),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          label: const Text('Retirer'),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: () => _toggleNearbyMode(sitesProvider),
                          icon: const Icon(Icons.my_location, size: 16),
                          label: const Text('Activer'),
                        ),
                    ],
                  ),
                  if (sitesProvider.isNearbyModeEnabled ||
                      sitesProvider.hasServerDistanceData) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (sitesProvider.selectedSort ==
                            SiteSortOption.proximity)
                          _buildModePill(
                            icon: Icons.swap_vert_rounded,
                            label: 'Tri Proximite par defaut',
                            highlighted: true,
                          ),
                        if (sitesProvider.nearbyResultsCount > 0)
                          _buildModePill(
                            icon: Icons.route_outlined,
                            label:
                                '${sitesProvider.nearbyResultsCount} distances visibles',
                          ),
                        if (nearestSite != null)
                          _buildModePill(
                            icon: Icons.near_me_outlined,
                            label:
                                'Plus proche ${nearestSite.formattedDistance}',
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    initialValue: sitesProvider.selectedCity,
                    decoration: const InputDecoration(
                      labelText: 'Ville',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    items: <DropdownMenuItem<String?>>[
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('Toutes les villes'),
                      ),
                      ...sitesProvider.availableCities.map(
                        (city) => DropdownMenuItem<String?>(
                          value: city,
                          child: Text(city),
                        ),
                      ),
                    ],
                    onChanged: (value) => sitesProvider.setCityFilter(value),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<SiteSortOption>(
                    initialValue: sitesProvider.selectedSort,
                    decoration: const InputDecoration(
                      labelText: 'Tri',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: SiteSortOption.recommended,
                        child: Text('Recommande'),
                      ),
                      DropdownMenuItem(
                        value: SiteSortOption.proximity,
                        child: Text(
                          sitesProvider.isNearbyModeEnabled
                              ? 'Proximite - par defaut'
                              : 'Proximite',
                        ),
                      ),
                      DropdownMenuItem(
                        value: SiteSortOption.rating,
                        child: Text('Meilleure note'),
                      ),
                      DropdownMenuItem(
                        value: SiteSortOption.popularity,
                        child: Text('Popularite'),
                      ),
                      DropdownMenuItem(
                        value: SiteSortOption.freshness,
                        child: Text('Fraicheur'),
                      ),
                      DropdownMenuItem(
                        value: SiteSortOption.alphabetical,
                        child: Text('Alphabetique'),
                      ),
                    ],
                    onChanged: (value) async {
                      if (value != null) {
                        await _onSortChanged(value, sitesProvider);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Note minimum',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primaryDeep,
                fontWeight: FontWeight.w700,
              ),
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.border,
                thumbColor: AppColors.primaryDeep,
                overlayColor: AppColors.primary.withValues(alpha: 0.12),
              ),
              child: Slider(
                min: 0,
                max: 5,
                divisions: 5,
                value: sitesProvider.minimumRating,
                label: sitesProvider.minimumRating == 0
                    ? 'Toutes'
                    : '${sitesProvider.minimumRating.toStringAsFixed(0)}+',
                onChanged: sitesProvider.setMinimumRating,
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  const [
                    _RatingChip(value: 0, label: 'Toutes'),
                    _RatingChip(value: 3, label: '3+'),
                    _RatingChip(value: 4, label: '4+'),
                    _RatingChip(value: 5, label: '5'),
                  ].map((chip) {
                    final isSelected =
                        sitesProvider.minimumRating == chip.value;
                    return FilterChip(
                      label: Text(chip.label),
                      selected: isSelected,
                      onSelected: (_) =>
                          sitesProvider.setMinimumRating(chip.value),
                      backgroundColor: AppColors.surfaceAlt,
                      selectedColor: AppColors.primaryDeep,
                      labelStyle: AppTextStyles.caption.copyWith(
                        color: isSelected
                            ? Colors.white
                            : AppColors.primaryDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiteRail({
    required String title,
    required String subtitle,
    required List<Site> sites,
    required SitesProvider sitesProvider,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          child: Text(
            title,
            style: AppTextStyles.bodyStrong.copyWith(fontSize: 18),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ),
        SizedBox(
          height: 228,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sites.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final site = sites[index];
              return SitePreviewCard.compact(
                site: site,
                onTap: () => _onSiteTap(site.id),
                isFavorite: sitesProvider.isFavorite(site.id),
                onToggleFavorite: () => _toggleFavorite(site.id),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  Widget _summaryPill({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryDeep),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recherche',
              style: AppTextStyles.bodyStrong.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Recherchez un lieu, une ambiance ou un quartier.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Exemple: plage, cafe, marina...',
                prefixIcon: const Icon(
                  Icons.search,
                  color: AppColors.primaryDeep,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeading({
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyStrong.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucun lieu ne correspond pour l\'instant',
            style: AppTextStyles.heading2.copyWith(color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Essaie une autre recherche, retire un filtre ou recharge la liste pour recuperer les derniers sites du backend.',
            style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 420;
    final maxLabelWidth = isSmallScreen
        ? (icon == null ? 148.0 : 128.0)
        : (icon == null ? 190.0 : 168.0);

    return FilterChip(
      avatar: icon == null
          ? null
          : Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.primaryDeep,
            ),
      label: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxLabelWidth),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primaryDeep,
      checkmarkColor: Colors.white,
      labelStyle: AppTextStyles.caption.copyWith(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 10 : 12,
        vertical: 8,
      ),
      labelPadding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 2 : 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(
          color: isSelected ? AppColors.primaryDeep : AppColors.border,
          width: isSelected ? 0 : 1,
        ),
      ),
    );
  }

  String _curationLabelFor(String key) {
    for (final option in _curationOptions) {
      if (option.key == key) {
        return option.label.toLowerCase();
      }
    }
    return key;
  }

  Widget _buildNearbySummaryCard({
    required SitesProvider sitesProvider,
    required Site nearestSite,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD6EAFD)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryDeep,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.near_me_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tri Proximite actif par defaut',
                  style: AppTextStyles.bodyStrong.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  '${sitesProvider.nearbyResultsCount} lieu${sitesProvider.nearbyResultsCount > 1 ? 'x' : ''} avec distance. Le plus proche est ${nearestSite.name} a ${nearestSite.formattedDistance}.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModePill({
    required IconData icon,
    required String label,
    bool highlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.primaryDeep : AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlighted ? AppColors.primaryDeep : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 15,
            color: highlighted ? Colors.white : AppColors.primaryDeep,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: highlighted ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Site? _nearestSite(List<Site> sites) {
    final distanceAwareSites = sites.where((site) => site.hasDistance).toList()
      ..sort(
        (a, b) => (a.distanceMeters ?? double.infinity).compareTo(
          b.distanceMeters ?? double.infinity,
        ),
      );

    if (distanceAwareSites.isEmpty) {
      return null;
    }

    return distanceAwareSites.first;
  }

  String _normalizeErrorMessage(String message) {
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message;
  }
}

class _RatingChip {
  final double value;
  final String label;

  const _RatingChip({required this.value, required this.label});
}
