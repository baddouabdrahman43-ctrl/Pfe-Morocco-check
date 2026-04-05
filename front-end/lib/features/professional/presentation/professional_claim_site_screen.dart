import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/api_service.dart';
import '../../sites/presentation/sites/site.dart';

class ProfessionalClaimSiteScreen extends StatefulWidget {
  const ProfessionalClaimSiteScreen({super.key});

  @override
  State<ProfessionalClaimSiteScreen> createState() =>
      _ProfessionalClaimSiteScreenState();
}

class _ProfessionalClaimSiteScreenState
    extends State<ProfessionalClaimSiteScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isClaiming = false;
  String? _claimingSiteId;
  String? _error;
  List<Site> _sites = const <Site>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSites();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sites = await _apiService.fetchSites(
        queryParameters: <String, dynamic>{
          'claimable': 'true',
          'limit': 30,
          if (_searchController.text.trim().isNotEmpty)
            'q': _searchController.text.trim(),
        },
      );

      if (!mounted) return;
      setState(() {
        _sites = sites;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _claimSite(Site site) async {
    setState(() {
      _isClaiming = true;
      _claimingSiteId = site.id;
    });

    try {
      final detail = await _apiService.claimProfessionalSite(site.id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${detail.site.name} est maintenant rattache a votre espace professionnel.',
          ),
          backgroundColor: AppColors.secondary,
        ),
      );

      context.pushReplacement('/professional/sites/${detail.site.id}');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isClaiming = false;
          _claimingSiteId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Revendiquer un site')),
      body: RefreshIndicator(
        onRefresh: _loadSites,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF3FBF8), Color(0xFFE8F5EE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revendiquer un lieu existant',
                    style: AppTextStyles.heading2.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selectionnez une fiche encore non rattachee pour l integrer a votre espace professionnel. Vous pourrez ensuite la suivre, la mettre a jour et repondre aux avis.',
                    style: AppTextStyles.body.copyWith(color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 14),
                  const Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ClaimKpiChip(
                        icon: Icons.verified_user_outlined,
                        label: 'rattachement officiel',
                      ),
                      _ClaimKpiChip(
                        icon: Icons.edit_outlined,
                        label: 'edition rapide',
                      ),
                      _ClaimKpiChip(
                        icon: Icons.reviews_outlined,
                        label: 'reponse aux avis',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recherche',
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Cherchez par nom, ville ou adresse pour retrouver plus vite une fiche a rattacher.',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _loadSites(),
                      decoration: InputDecoration(
                        hintText: 'Rechercher un site par nom, ville ou adresse',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          tooltip: 'Rechercher',
                          onPressed: _loadSites,
                          icon: const Icon(Icons.search),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _error!,
                  style: AppTextStyles.body.copyWith(color: AppColors.error),
                ),
              )
            else if (_sites.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 36),
                child: Column(
                  children: [
                    Icon(
                      Icons.storefront_outlined,
                      size: 56,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Aucun site disponible',
                      style: AppTextStyles.heading2.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toutes les fiches visibles sont deja rattachees ou aucun resultat ne correspond a votre recherche.',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ..._sites.map((site) {
                final isBusy = _isClaiming && _claimingSiteId == site.id;
                final infoPills = <Widget>[
                  if (site.viewsCount > 0)
                    _MiniInfo(
                      icon: Icons.visibility_outlined,
                      label: '${site.viewsCount} vues',
                    ),
                  if (site.favoritesCount > 0)
                    _MiniInfo(
                      icon: Icons.favorite_outline,
                      label: '${site.favoritesCount} favoris',
                    ),
                  if (site.totalReviews > 0)
                    _MiniInfo(
                      icon: Icons.reviews_outlined,
                      label: '${site.totalReviews} avis',
                    ),
                ];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    site.name,
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    [
                                      if (site.category.isNotEmpty)
                                        site.category,
                                      if (site.city.isNotEmpty) site.city,
                                      if (site.region.isNotEmpty) site.region,
                                    ].join(' - '),
                                    style: AppTextStyles.caption.copyWith(
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (site.rating > 0)
                              Text(
                                site.rating.toStringAsFixed(1),
                                style: AppTextStyles.heading2.copyWith(
                                  fontSize: 18,
                                  color: Colors.amber.shade700,
                                ),
                              ),
                          ],
                        ),
                        if (site.address.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            site.address,
                            style: AppTextStyles.body.copyWith(
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                        if (infoPills.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: infoPills,
                          ),
                          const SizedBox(height: 14),
                        ] else
                          const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 18,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Une fois rattachee, la fiche apparaitra dans votre espace pro avec ses statuts, ses avis et ses indicateurs.',
                                  style: AppTextStyles.caption.copyWith(
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isBusy ? null : () => _claimSite(site),
                            icon: isBusy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.verified_user_outlined),
                            label: Text(
                              isBusy
                                  ? 'Revendication...'
                                  : 'Revendiquer ce site',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _ClaimKpiChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ClaimKpiChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.grey[800],
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniInfo({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.grey[800],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
