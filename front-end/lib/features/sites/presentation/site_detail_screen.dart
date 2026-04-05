import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/api_service.dart';
import '../../../shared/models/user.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../auth/presentation/auth_provider.dart';
import 'models/site_photo.dart';
import 'reviews_list.dart';
import 'sites/site.dart';
import 'sites_provider.dart';
import 'widgets/site_detail_sections.dart';

class SiteDetailScreen extends StatefulWidget {
  final String? siteId;
  final ApiService? apiService;

  const SiteDetailScreen({super.key, this.siteId, this.apiService});

  @override
  State<SiteDetailScreen> createState() => _SiteDetailScreenState();
}

class _SiteDetailScreenState extends State<SiteDetailScreen>
    with SingleTickerProviderStateMixin {
  static const Set<String> _checkinAllowedRoles = <String>{
    'CONTRIBUTOR',
    'PROFESSIONAL',
    'ADMIN',
  };

  late final ApiService _apiService;
  late TabController _tabController;

  Site? _site;
  List<SitePhoto> _photos = <SitePhoto>[];
  bool _isLoading = true;
  bool _isPhotosLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
    _tabController = TabController(length: 3, vsync: this);
    _loadSite();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSite() async {
    if (widget.siteId == null) {
      setState(() {
        _isLoading = false;
        _error = 'Site introuvable';
      });
      return;
    }

    final sitesProvider = context.read<SitesProvider>();
    final cachedSite = sitesProvider.getSiteById(widget.siteId!);

    if (cachedSite != null) {
      setState(() {
        _site = cachedSite;
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<SitesProvider>().recordSiteVisit(cachedSite);
      });
    }

    try {
      final site = await _apiService.fetchSiteDetail(widget.siteId!);
      if (!mounted) return;

      setState(() {
        _site = site;
        _error = null;
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<SitesProvider>().recordSiteVisit(site);
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = _site == null ? e.toString() : null;
      });
    }

    await _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    if (widget.siteId == null) return;

    setState(() {
      _isPhotosLoading = true;
    });

    try {
      final photos = await _apiService.fetchSitePhotos(widget.siteId!);
      if (!mounted) return;

      setState(() {
        _photos = photos;
        _isPhotosLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _photos = <SitePhoto>[];
        _isPhotosLoading = false;
      });
    }
  }

  Future<void> _refreshSite() async {
    await _loadSite();
  }

  void _handleCheckIn() {
    if (_site != null) {
      context.push('/checkin/${_site!.id}');
    }
  }

  Future<void> _handleAddReview() async {
    if (_site == null) return;

    await context.push('/review/${_site!.id}');
    if (!mounted) return;
    await _loadSite();
  }

  Future<void> _openItinerary(Site site) async {
    final destinationLabel = [
      site.name,
      if (site.city.isNotEmpty) site.city,
    ].join(', ');
    final mapsUri = Uri.https('www.google.com', '/maps/dir/', <String, String>{
      'api': '1',
      'destination': '${site.latitude},${site.longitude}',
      'travelmode': 'driving',
      'dir_action': 'navigate',
    });

    final fallbackUri = Uri.https(
      'www.openstreetmap.org',
      '/directions',
      <String, String>{
        'engine': 'fossgis_osrm_car',
        'route': '${site.latitude},${site.longitude}',
      },
    );

    final launched = await launchUrl(
      mapsUri,
      mode: LaunchMode.externalApplication,
    );

    if (launched || !mounted) return;

    final fallbackLaunched = await launchUrl(
      fallbackUri,
      mode: LaunchMode.externalApplication,
    );

    if (fallbackLaunched || !mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Impossible d ouvrir un itineraire pour $destinationLabel.',
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }

  bool _canUserSubmitCheckin(User? user) {
    return user != null && _checkinAllowedRoles.contains(user.role);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final sitesProvider = context.watch<SitesProvider>();
    final currentUser = authProvider.user;
    final isAuthenticated = authProvider.isAuthenticated;
    final canSubmitCheckin = _canUserSubmitCheckin(currentUser);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading && _site == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Details du site')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_site == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Details du site')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'Impossible de charger ce site.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadSite,
                  child: const Text('Reessayer'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final site = _site!;
    final freshnessColor = AppColors.getMarkerColor(site.freshnessScore);
    final relatedSites = sitesProvider.recommendSites(
      excludeSiteId: site.id,
      limit: 4,
    );

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshSite,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 320,
              pinned: true,
              actions: [
                IconButton(
                  tooltip: sitesProvider.isFavorite(site.id)
                      ? 'Retirer des favoris'
                      : 'Ajouter aux favoris',
                  onPressed: () => sitesProvider.toggleFavorite(site.id),
                  icon: Icon(
                    sitesProvider.isFavorite(site.id)
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                  ),
                ),
                IconButton(
                  tooltip: 'Rafraichir',
                  onPressed: _refreshSite,
                  icon: const Icon(Icons.refresh),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                    children: [
                      site.imageUrl.isNotEmpty
                        ? AppNetworkImage(
                            imageUrl: site.imageUrl,
                            fit: BoxFit.cover,
                            fallback: const SiteDetailPlaceholderImage(),
                          )
                        : const SiteDetailPlaceholderImage(),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.15),
                            Colors.black.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 22,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              SiteDetailHeroChip(
                                icon: Icons.category_outlined,
                                label: site.category,
                              ),
                              SiteDetailHeroChip(
                                icon: Icons.place_outlined,
                                label: site.city.isNotEmpty
                                    ? site.city
                                    : (site.region.isNotEmpty
                                          ? site.region
                                          : 'Lieu'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            site.name,
                            style: AppTextStyles.heading1.copyWith(
                              fontSize: 30,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              ),
            ),
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SiteDetailMetricCard(
                          icon: Icons.star_rounded,
                          label: 'Note',
                          value: site.rating.toStringAsFixed(1),
                          accentColor: colorScheme.secondary,
                        ),
                        SiteDetailMetricCard(
                          icon: Icons.verified_outlined,
                          label: 'Fraicheur',
                          value: '${site.freshnessScore}%',
                          accentColor: freshnessColor,
                        ),
                        SiteDetailMetricCard(
                          icon: Icons.photo_library_outlined,
                          label: 'Photos',
                          value: '${_photos.length}',
                          accentColor: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: canSubmitCheckin ? _handleCheckIn : null,
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Faire un check-in'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: OutlinedButton.icon(
                            onPressed: isAuthenticated
                                ? _handleAddReview
                                : null,
                            icon: const Icon(Icons.rate_review),
                            label: const Text('Ajouter un avis'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 20,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => sitesProvider.toggleFavorite(site.id),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  sitesProvider.isFavorite(site.id)
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: sitesProvider.isFavorite(site.id)
                                      ? AppColors.error
                                      : AppColors.primaryDeep,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        sitesProvider.isFavorite(site.id)
                                            ? 'Dans vos favoris'
                                            : 'Ajouter a vos favoris',
                                        style: AppTextStyles.body.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Retrouvez ce lieu plus vite et influencez vos recommandations.',
                                        style: AppTextStyles.caption.copyWith(
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${site.favoritesCount + (sitesProvider.isFavorite(site.id) ? 1 : 0)}',
                                  style: AppTextStyles.bodyStrong.copyWith(
                                    color: AppColors.primaryDeep,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isAuthenticated)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.lock_outline,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Connectez-vous pour contribuer',
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Le check-in et la publication d avis sont reserves aux utilisateurs connectes.',
                                    style: AppTextStyles.caption.copyWith(
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton(
                                      onPressed: () => context.push('/login'),
                                      child: const Text('Se connecter'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (isAuthenticated && !canSubmitCheckin)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Le check-in est reserve aux comptes contributeur, professionnel, moderateur ou admin. Vous pouvez quand meme publier un avis.',
                                style: AppTextStyles.caption.copyWith(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _error!,
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: colorScheme.onSurface.withValues(
                      alpha: 0.65,
                    ),
                    indicatorColor: AppColors.primary,
                    tabs: const [
                      Tab(text: 'Info'),
                      Tab(text: 'Avis'),
                      Tab(text: 'Photos'),
                    ],
                  ),
                  AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, child) {
                      switch (_tabController.index) {
                        case 1:
                          return ReviewsList(siteId: site.id);
                        case 2:
                          return SiteDetailPhotosTab(
                            isLoading: _isPhotosLoading,
                            photos: _photos,
                          );
                        case 0:
                        default:
                          return SiteDetailInfoTab(
                            site: site,
                            relatedSites: relatedSites,
                            onViewMap: () => context.push('/map'),
                            onOpenItinerary: () => _openItinerary(site),
                            onRelatedSiteTap: (relatedSite) =>
                                context.push('/sites/${relatedSite.id}'),
                          );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
