import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/api_service.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/status_chip.dart';
import '../models/professional_site.dart';
import 'professional_site_status.dart';

class ProfessionalSitesScreen extends StatefulWidget {
  const ProfessionalSitesScreen({super.key});

  @override
  State<ProfessionalSitesScreen> createState() =>
      _ProfessionalSitesScreenState();
}

class _ProfessionalSitesScreenState extends State<ProfessionalSitesScreen> {
  final ApiService _apiService = ApiService();
  List<ProfessionalSite> _sites = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedStatus;

  static const List<String> _statusFilters = [
    'PUBLISHED',
    'PENDING_REVIEW',
    'ARCHIVED',
  ];

  int get _publishedCount =>
      _sites.where((site) => site.status == 'PUBLISHED').length;
  int get _pendingCount =>
      _sites.where((site) => site.status == 'PENDING_REVIEW').length;
  int get _attentionCount => _sites
      .where(
        (site) =>
            site.verificationStatus == 'REJECTED' ||
            site.moderationNotes.trim().isNotEmpty,
      )
      .length;
  int get _totalViews =>
      _sites.fold(0, (sum, site) => sum + site.viewsCount);
  int get _totalFavorites =>
      _sites.fold(0, (sum, site) => sum + site.favoritesCount);
  int get _totalReviews =>
      _sites.fold(0, (sum, site) => sum + site.totalReviews);
  int get _averageFreshness => _sites.isEmpty
      ? 0
      : (_sites.fold(0, (sum, site) => sum + site.freshnessScore) /
                _sites.length)
            .round();
  double get _averageRating {
    final ratedSites = _sites.where((site) => site.rating > 0).toList();
    if (ratedSites.isEmpty) {
      return 0;
    }
    final total = ratedSites.fold<double>(0, (sum, site) => sum + site.rating);
    return total / ratedSites.length;
  }
  ProfessionalSite? get _topPerformer {
    if (_sites.isEmpty) {
      return null;
    }

    ProfessionalSite scoreSite(ProfessionalSite current, ProfessionalSite next) {
      double score(ProfessionalSite site) {
        return (site.viewsCount * 0.35) +
            (site.favoritesCount * 1.5) +
            (site.totalReviews * 4) +
            (site.rating * 12) +
            (site.freshnessScore * 0.6);
      }

      return score(next) > score(current) ? next : current;
    }

    return _sites.reduce(scoreSite);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSites();
    });
  }

  Future<void> _loadSites() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sites = await _apiService.fetchProfessionalSites(
        queryParameters: <String, dynamic>{
          'limit': 50,
          if (_selectedStatus != null) 'status': _selectedStatus,
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
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _openCreateScreen() async {
    final created = await context.push<bool>('/professional/sites/new');
    if (created == true && mounted) {
      await _loadSites();
    }
  }

  Future<void> _openDetailScreen(ProfessionalSite site) async {
    await context.push('/professional/sites/${site.id}');
    if (mounted) {
      await _loadSites();
    }
  }

  Future<void> _openEditScreen(ProfessionalSite site) async {
    final updated = await context.push<bool>(
      '/professional/sites/${site.id}/edit',
      extra: site,
    );
    if (updated == true && mounted) {
      await _loadSites();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes etablissements')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateScreen,
        label: const Text('Ajouter'),
        icon: const Icon(Icons.add_business),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSites,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _OverviewHeader(
                    totalSites: _sites.length,
                    publishedCount: _publishedCount,
                    pendingCount: _pendingCount,
                    attentionCount: _attentionCount,
                    totalViews: _totalViews,
                    totalFavorites: _totalFavorites,
                    totalReviews: _totalReviews,
                    averageFreshness: _averageFreshness,
                    averageRating: _averageRating,
                    topPerformer: _topPerformer,
                    onAdd: _openCreateScreen,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildFilterChip('Tous', _selectedStatus == null, () {
                          setState(() {
                            _selectedStatus = null;
                          });
                          _loadSites();
                        }),
                        const SizedBox(width: 8),
                        ..._statusFilters.map(
                          (status) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildFilterChip(
                              _statusFilterLabel(status),
                              _selectedStatus == status,
                              () {
                                setState(() {
                                  _selectedStatus = status;
                                });
                                _loadSites();
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        _error!,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  if (_sites.isEmpty && _error == null)
                    EmptyStateWidget(
                      icon: Icons.storefront_outlined,
                      title: 'Aucun lieu pour le moment',
                      message:
                          'Commencez par soumettre votre premier lieu. Les statuts de publication et de validation apparaitront ici.',
                      primaryAction: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _openCreateScreen,
                          icon: const Icon(Icons.add_business),
                          label: const Text('Ajouter un etablissement'),
                        ),
                      ),
                    )
                  else
                    ..._sites.map((site) {
                      final publication = publicationStatusInfo(site.status);
                      final verification = verificationStatusInfo(
                        site.verificationStatus,
                      );

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _openDetailScreen(site),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            site.name,
                                            style: AppTextStyles.body.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${site.categoryName} - ${site.city}',
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      site.rating > 0
                                          ? site.rating.toStringAsFixed(1)
                                          : 'N/A',
                                      style: AppTextStyles.heading2.copyWith(
                                        fontSize: 18,
                                        color: Colors.amber.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    StatusChip(
                                      icon: publication.icon,
                                      label: publication.label,
                                      tone: _publicationTone(site.status),
                                      size: StatusChipSize.small,
                                    ),
                                    StatusChip(
                                      icon: verification.icon,
                                      label: verification.label,
                                      tone: _verificationTone(
                                        site.verificationStatus,
                                      ),
                                      size: StatusChipSize.small,
                                    ),
                                    _StatusPill(
                                      label:
                                          'Fraicheur ${site.freshnessScore}%',
                                      color: AppColors.secondary,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _CompactMetricPill(
                                      icon: Icons.star_outline,
                                      label: site.rating > 0
                                          ? site.rating.toStringAsFixed(1)
                                          : 'N/A',
                                    ),
                                    _CompactMetricPill(
                                      icon: Icons.reviews_outlined,
                                      label: '${site.totalReviews} avis',
                                    ),
                                    _CompactMetricPill(
                                      icon: Icons.visibility_outlined,
                                      label: '${site.viewsCount} vues',
                                    ),
                                    _CompactMetricPill(
                                      icon: Icons.favorite_border,
                                      label:
                                          '${site.favoritesCount} favoris',
                                    ),
                                    _CompactMetricPill(
                                      icon: Icons.trending_up_outlined,
                                      label:
                                          '${_favoriteRate(site).toStringAsFixed(0)}% engagement',
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (site.address.isNotEmpty)
                                  Text(
                                    site.address,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.caption.copyWith(
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                if (site.moderationNotes.trim().isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(alpha: 0.10),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Colors.orange.shade800,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            site.moderationNotes,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.caption.copyWith(
                                              color: Colors.orange.shade900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => _openDetailScreen(site),
                                        icon: const Icon(Icons.visibility_outlined),
                                        label: const Text('Ouvrir'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    OutlinedButton.icon(
                                      onPressed: () => _openEditScreen(site),
                                      icon: const Icon(Icons.edit_outlined),
                                      label: const Text('Modifier'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }

  String _statusFilterLabel(String status) {
    switch (status) {
      case 'PUBLISHED':
        return 'Publies';
      case 'PENDING_REVIEW':
        return 'En attente';
      case 'ARCHIVED':
        return 'Archives';
      default:
        return status;
    }
  }

  StatusChipTone _publicationTone(String status) {
    switch (status) {
      case 'PUBLISHED':
        return StatusChipTone.success;
      case 'PENDING_REVIEW':
        return StatusChipTone.warning;
      default:
        return StatusChipTone.defaultTone;
    }
  }

  StatusChipTone _verificationTone(String status) {
    switch (status) {
      case 'VERIFIED':
        return StatusChipTone.success;
      case 'PENDING':
        return StatusChipTone.warning;
      case 'REJECTED':
        return StatusChipTone.danger;
      default:
        return StatusChipTone.defaultTone;
    }
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      labelStyle: AppTextStyles.caption.copyWith(
        color: isSelected ? Colors.white : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.primary : Colors.grey.shade300,
      ),
    );
  }
}

class _OverviewHeader extends StatelessWidget {
  final int totalSites;
  final int publishedCount;
  final int pendingCount;
  final int attentionCount;
  final int totalViews;
  final int totalFavorites;
  final int totalReviews;
  final int averageFreshness;
  final double averageRating;
  final ProfessionalSite? topPerformer;
  final VoidCallback onAdd;

  const _OverviewHeader({
    required this.totalSites,
    required this.publishedCount,
    required this.pendingCount,
    required this.attentionCount,
    required this.totalViews,
    required this.totalFavorites,
    required this.totalReviews,
    required this.averageFreshness,
    required this.averageRating,
    required this.topPerformer,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF3FBF8), Color(0xFFE7F6F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 220, maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tableau de bord pro',
                      style: AppTextStyles.heading2.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$totalSites lieu${totalSites > 1 ? 'x' : ''} dans votre portefeuille. Suivez leur performance, leur validation et les signaux de confiance.',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_business),
                label: const Text('Ajouter'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _BusinessKpiCard(
                title: 'Visibilite',
                value: '$totalViews',
                subtitle: 'vues cumulees',
                tone: AppColors.primary,
              ),
              _BusinessKpiCard(
                title: 'Engagement',
                value: '$totalFavorites',
                subtitle: 'favoris enregistres',
                tone: Colors.pink.shade700,
              ),
              _BusinessKpiCard(
                title: 'Reputation',
                value: averageRating > 0
                    ? averageRating.toStringAsFixed(1)
                    : 'N/A',
                subtitle: '$totalReviews avis publies',
                tone: Colors.amber.shade700,
              ),
              _BusinessKpiCard(
                title: 'Fraicheur',
                value: '$averageFreshness%',
                subtitle: 'moyenne portefeuille',
                tone: AppColors.secondary,
              ),
            ],
          ),
          if (topPerformer != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meilleure traction actuelle',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          topPerformer!.name,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${topPerformer!.viewsCount} vues, ${topPerformer!.favoritesCount} favoris, ${topPerformer!.totalReviews} avis et ${topPerformer!.freshnessScore}% de fraicheur.',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SummaryStatCard(
                title: 'Publies',
                value: '$publishedCount',
                tone: AppColors.secondary,
              ),
              _SummaryStatCard(
                title: 'En attente',
                value: '$pendingCount',
                tone: Colors.orange,
              ),
              _SummaryStatCard(
                title: 'A traiter',
                value: '$attentionCount',
                tone: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BusinessKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color tone;

  const _BusinessKpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 145),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: Colors.grey[700],
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTextStyles.heading2.copyWith(fontSize: 24, color: tone),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}

class _SummaryStatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color tone;

  const _SummaryStatCard({
    required this.title,
    required this.value,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tone.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppTextStyles.heading2.copyWith(fontSize: 22, color: tone),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.caption.copyWith(
              color: Colors.grey[700],
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactMetricPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _CompactMetricPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
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

double _favoriteRate(ProfessionalSite site) {
  if (site.viewsCount <= 0) {
    return 0;
  }
  return (site.favoritesCount / site.viewsCount) * 100;
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
