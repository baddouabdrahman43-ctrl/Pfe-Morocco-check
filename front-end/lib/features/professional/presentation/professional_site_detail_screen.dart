import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/api_service.dart';
import '../../sites/presentation/models/review.dart';
import '../models/professional_site.dart';
import '../models/professional_site_detail.dart';
import 'professional_site_status.dart';

class ProfessionalSiteDetailScreen extends StatefulWidget {
  final String siteId;

  const ProfessionalSiteDetailScreen({super.key, required this.siteId});

  @override
  State<ProfessionalSiteDetailScreen> createState() =>
      _ProfessionalSiteDetailScreenState();
}

class _ProfessionalSiteDetailScreenState
    extends State<ProfessionalSiteDetailScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _error;
  ProfessionalSiteDetail? _detail;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDetail();
    });
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final detail = await _apiService.fetchProfessionalSiteDetail(
        widget.siteId,
      );
      if (!mounted) return;

      setState(() {
        _detail = detail;
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

  Future<void> _openEditScreen(ProfessionalSite site) async {
    final updated = await context.push<bool>(
      '/professional/sites/${site.id}/edit',
      extra: site,
    );
    if (updated == true && mounted) {
      await _loadDetail();
    }
  }

  Future<void> _replyToReview(Review review) async {
    final controller = TextEditingController(text: review.ownerResponse ?? '');
    final nextResponse = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            review.hasOwnerResponse
                ? 'Modifier la reponse professionnelle'
                : 'Repondre a cet avis',
          ),
          content: TextField(
            controller: controller,
            maxLines: 6,
            minLines: 4,
            decoration: const InputDecoration(
              hintText:
                  'Saisissez une reponse claire, professionnelle et utile.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(controller.text.trim());
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (nextResponse == null || nextResponse.trim().isEmpty) {
      return;
    }

    try {
      await _apiService.respondToReview(
        reviewId: review.id,
        responseText: nextResponse.trim(),
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reponse professionnelle enregistree.'),
          backgroundColor: AppColors.secondary,
        ),
      );
      await _loadDetail();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fiche proprietaire'),
        actions: [
          if (_detail != null)
            IconButton(
              tooltip: 'Modifier',
              onPressed: () => _openEditScreen(_detail!.site),
              icon: const Icon(Icons.edit_outlined),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorState(message: _error!, onRetry: _loadDetail)
          : RefreshIndicator(
              onRefresh: _loadDetail,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _HeroSection(
                    site: _detail!.site,
                    analytics: _detail!.analytics,
                    onEdit: () => _openEditScreen(_detail!.site),
                  ),
                  const SizedBox(height: 16),
                  _BusinessPulseSection(
                    site: _detail!.site,
                    analytics: _detail!.analytics,
                  ),
                  const SizedBox(height: 16),
                  _ValidationSection(site: _detail!.site),
                  const SizedBox(height: 16),
                  _PrioritySection(
                    site: _detail!.site,
                    analytics: _detail!.analytics,
                    onEdit: () => _openEditScreen(_detail!.site),
                    onRefresh: _loadDetail,
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Visibilite et engagement',
                    icon: Icons.insights_outlined,
                    child: _AnalyticsSection(
                      site: _detail!.site,
                      analytics: _detail!.analytics,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Contact et localisation',
                    icon: Icons.place_outlined,
                    child: _ContactSection(site: _detail!.site),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Services declares',
                    icon: Icons.fact_check_outlined,
                    child: _ServicesSection(site: _detail!.site),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Horaires',
                    icon: Icons.schedule_outlined,
                    child: _OpeningHoursSection(
                      openingHours: _detail!.openingHours,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Suivi et activite',
                    icon: Icons.timeline_rounded,
                    child: _ActivitySection(site: _detail!.site),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Avis recents',
                    icon: Icons.reviews_outlined,
                    child: _RecentReviewsSection(
                      reviews: _detail!.recentReviews,
                      onReply: _replyToReview,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _PrioritySection extends StatelessWidget {
  final ProfessionalSite site;
  final ProfessionalSiteAnalytics analytics;
  final VoidCallback onEdit;
  final Future<void> Function() onRefresh;

  const _PrioritySection({
    required this.site,
    required this.analytics,
    required this.onEdit,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final priorities = <_PriorityItem>[
      if (site.status == 'PENDING_REVIEW')
        const _PriorityItem(
          icon: Icons.hourglass_top_rounded,
          title: 'Validation en cours',
          message:
              'La fiche attend encore une revue. Evitez les modifications inutiles et surveillez le retour de moderation.',
          tone: Colors.orange,
        ),
      if (site.verificationStatus == 'REJECTED')
        _PriorityItem(
          icon: Icons.gpp_bad_outlined,
          title: 'Correction necessaire',
          message: site.moderationNotes.trim().isNotEmpty
              ? site.moderationNotes
              : 'La validation a ete refusee. Ouvrez la fiche pour corriger les informations demandees.',
          tone: AppColors.error,
        ),
      if (site.phoneNumber.trim().isEmpty && site.email.trim().isEmpty)
        const _PriorityItem(
          icon: Icons.contact_phone_outlined,
          title: 'Contact incomplet',
          message:
              'Ajoutez au moins un moyen de contact public pour rendre la fiche plus exploitable.',
          tone: AppColors.primary,
        ),
      if (site.freshnessScore < 70)
        const _PriorityItem(
          icon: Icons.update_outlined,
          title: 'Fraicheur a renforcer',
          message:
              'Une mise a jour rapide des informations aidera a garder la fiche fiable.',
          tone: Colors.orange,
        ),
      if (site.totalReviews > 0 && analytics.responseRate < 60)
        const _PriorityItem(
          icon: Icons.rate_review_outlined,
          title: 'Reponses a accelerer',
          message:
              'Les avis sont deja presents. Repondre plus souvent renforce la confiance.',
          tone: AppColors.secondary,
        ),
    ];

    final effectivePriorities = priorities.isEmpty
        ? const <_PriorityItem>[
            _PriorityItem(
              icon: Icons.check_circle_outline,
              title: 'Fiche en bon etat',
              message:
                  'Les informations essentielles sont en place. Vous pouvez surtout suivre les avis et la visibilite.',
              tone: AppColors.secondary,
            ),
          ]
        : priorities;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt_outlined, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Actions conseillees',
                    style: AppTextStyles.heading2.copyWith(fontSize: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...effectivePriorities.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PriorityTile(item: item),
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Modifier la fiche'),
                ),
                OutlinedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Actualiser'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final ProfessionalSite site;
  final ProfessionalSiteAnalytics analytics;
  final VoidCallback onEdit;

  const _HeroSection({
    required this.site,
    required this.analytics,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final publication = publicationStatusInfo(site.status);
    final verification = verificationStatusInfo(site.verificationStatus);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.86),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroChip(
                icon: publication.icon,
                label: publication.label,
                backgroundColor: Colors.white.withValues(alpha: 0.16),
              ),
              _HeroChip(
                icon: verification.icon,
                label: verification.label,
                backgroundColor: Colors.white.withValues(alpha: 0.16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            site.name,
            style: AppTextStyles.heading1.copyWith(
              color: Colors.white,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${site.categoryName} - ${site.city}',
            style: AppTextStyles.body.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetricBadge(label: 'Vues', value: '${site.viewsCount}'),
              _MetricBadge(
                label: 'Note',
                value: site.rating > 0 ? site.rating.toStringAsFixed(1) : 'N/A',
              ),
              _MetricBadge(label: 'Avis', value: '${site.totalReviews}'),
              _MetricBadge(
                label: 'Reponses',
                value: '${analytics.responseRate}%',
              ),
              _MetricBadge(
                label: 'Fraicheur',
                value: '${site.freshnessScore}%',
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Modifier'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessPulseSection extends StatelessWidget {
  final ProfessionalSite site;
  final ProfessionalSiteAnalytics analytics;

  const _BusinessPulseSection({
    required this.site,
    required this.analytics,
  });

  @override
  Widget build(BuildContext context) {
    final favoriteRate = site.viewsCount > 0
        ? (site.favoritesCount / site.viewsCount) * 100
        : 0.0;
    final businessCards = <_BusinessPulseCardData>[
      _BusinessPulseCardData(
        title: 'Acquisition',
        value: '${site.viewsCount}',
        subtitle: 'vues fiche',
        helper: '${site.favoritesCount} favoris',
        tone: AppColors.primary,
      ),
      _BusinessPulseCardData(
        title: 'Conversion',
        value: '${favoriteRate.toStringAsFixed(0)}%',
        subtitle: 'favoris / vues',
        helper: '${site.favoritesCount} intentions',
        tone: Colors.pink.shade700,
      ),
      _BusinessPulseCardData(
        title: 'Confiance',
        value: site.rating > 0 ? site.rating.toStringAsFixed(1) : 'N/A',
        subtitle: 'note moyenne',
        helper: '${analytics.publishedReviews} avis publies',
        tone: Colors.amber.shade700,
      ),
      _BusinessPulseCardData(
        title: 'Reactivite',
        value: '${analytics.responseRate}%',
        subtitle: 'reponses aux avis',
        helper: '${analytics.ownerRepliesCount} reponses',
        tone: AppColors.secondary,
      ),
    ];

    final headline = analytics.responseRate >= 70 && site.freshnessScore >= 70
        ? 'La fiche est bien tenue: la reactivite et la fraicheur soutiennent deja la confiance.'
        : analytics.pendingReviews > 0
        ? 'Des avis attendent encore un traitement ou une reponse. Une action rapide peut renforcer la perception de la fiche.'
        : site.freshnessScore < 70
        ? 'La visibilite existe, mais une mise a jour des informations aidera a mieux convertir et rassurer.'
        : 'Le lieu gagne a etre pilote comme une vitrine active: avis, favoris et fraicheur doivent avancer ensemble.';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lecture business',
              style: AppTextStyles.heading2.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              headline,
              style: AppTextStyles.body.copyWith(color: Colors.grey[800]),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: businessCards
                  .map((item) => _BusinessPulseCard(item: item))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _BusinessPulseCardData {
  final String title;
  final String value;
  final String subtitle;
  final String helper;
  final Color tone;

  const _BusinessPulseCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.helper,
    required this.tone,
  });
}

class _BusinessPulseCard extends StatelessWidget {
  final _BusinessPulseCardData item;

  const _BusinessPulseCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 145),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: AppTextStyles.caption.copyWith(
              color: Colors.grey[700],
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.value,
            style: AppTextStyles.heading2.copyWith(
              fontSize: 24,
              color: item.tone,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.subtitle,
            style: AppTextStyles.caption.copyWith(color: Colors.grey[800]),
          ),
          const SizedBox(height: 6),
          Text(
            item.helper,
            style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class _PriorityItem {
  final IconData icon;
  final String title;
  final String message;
  final Color tone;

  const _PriorityItem({
    required this.icon,
    required this.title,
    required this.message,
    required this.tone,
  });
}

class _PriorityTile extends StatelessWidget {
  final _PriorityItem item;

  const _PriorityTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: item.tone.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: item.tone),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: item.tone,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.message,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.grey[900],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsSection extends StatefulWidget {
  final ProfessionalSite site;
  final ProfessionalSiteAnalytics analytics;

  const _AnalyticsSection({required this.site, required this.analytics});

  @override
  State<_AnalyticsSection> createState() => _AnalyticsSectionState();
}

class _AnalyticsSectionState extends State<_AnalyticsSection> {
  bool _showNarration = false;

  @override
  Widget build(BuildContext context) {
    final site = widget.site;
    final analytics = widget.analytics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _AnalyticsTile(
              title: 'Audience',
              value: '${site.viewsCount}',
              subtitle: 'Visibilite totale',
              color: AppColors.primary,
            ),
            _AnalyticsTile(
              title: 'Intentions',
              value: '${site.favoritesCount}',
              subtitle: 'Favoris enregistres',
              color: Colors.pink.shade700,
            ),
            _AnalyticsTile(
              title: 'Terrain',
              value: '${analytics.totalCheckins}',
              subtitle: '${analytics.recentCheckins30d} sur 30 jours',
              color: AppColors.secondary,
            ),
            _AnalyticsTile(
              title: 'Service client',
              value: '${analytics.responseRate}%',
              subtitle: '${analytics.ownerRepliesCount} reponses publiees',
              color: Colors.orange.shade700,
            ),
          ],
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _showNarration = !_showNarration;
            });
          },
          icon: Icon(
            _showNarration
                ? Icons.visibility_off_outlined
                : Icons.insights_outlined,
          ),
          label: Text(_showNarration ? 'Masquer l analyse' : 'Voir l analyse'),
        ),
        if (_showNarration) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lecture rapide',
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Le lieu totalise ${analytics.publishedReviews} avis publies, ${analytics.pendingReviews} en attente, et une note moyenne recente de ${analytics.averageRating30d.toStringAsFixed(1)} sur les 30 derniers jours.',
                  style: AppTextStyles.body.copyWith(color: Colors.grey[800]),
                ),
                const SizedBox(height: 6),
                Text(
                  'Sur la meme periode, ${analytics.recentReviews30d} nouvel${analytics.recentReviews30d > 1 ? 's avis' : ' avis'} et ${analytics.recentCheckins30d} check-in${analytics.recentCheckins30d > 1 ? 's' : ''} ont renforce la fiabilite et la visibilite de la fiche.',
                  style: AppTextStyles.body.copyWith(color: Colors.grey[800]),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ValidationSection extends StatelessWidget {
  final ProfessionalSite site;

  const _ValidationSection({required this.site});

  @override
  Widget build(BuildContext context) {
    final publication = publicationStatusInfo(site.status);
    final verification = verificationStatusInfo(site.verificationStatus);

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520) {
          return Column(
            children: [
              _StatusCard(title: 'Diffusion', info: publication),
              const SizedBox(height: 12),
              _StatusCard(title: 'Validation', info: verification),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _StatusCard(title: 'Diffusion', info: publication),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatusCard(title: 'Validation', info: verification),
            ),
          ],
        );
      },
    );
  }
}

class _ContactSection extends StatelessWidget {
  final ProfessionalSite site;

  const _ContactSection({required this.site});

  @override
  Widget build(BuildContext context) {
    final rows = <MapEntry<String, String>>[
      MapEntry(
        'Adresse',
        site.address.isNotEmpty ? site.address : 'Non renseignee',
      ),
      MapEntry('Ville', site.city.isNotEmpty ? site.city : 'Non renseignee'),
      MapEntry(
        'Region',
        site.region.isNotEmpty ? site.region : 'Non renseignee',
      ),
      MapEntry(
        'Telephone',
        site.phoneNumber.isNotEmpty ? site.phoneNumber : 'Non renseigne',
      ),
      MapEntry('Email', site.email.isNotEmpty ? site.email : 'Non renseigne'),
      MapEntry(
        'Site web',
        site.website.isNotEmpty ? site.website : 'Non renseigne',
      ),
      MapEntry(
        'Coordonnees',
        '${site.latitude.toStringAsFixed(5)}, ${site.longitude.toStringAsFixed(5)}',
      ),
      MapEntry('Pays', site.country),
      MapEntry('Gamme de prix', _priceLabel(site.priceRange)),
    ];

    return Column(
      children: rows
          .map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      row.key,
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      row.value,
                      style: AppTextStyles.body.copyWith(
                        color: Colors.grey[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ServicesSection extends StatelessWidget {
  final ProfessionalSite site;

  const _ServicesSection({required this.site});

  @override
  Widget build(BuildContext context) {
    final items = <_ServiceFlag>[
      _ServiceFlag(
        label: 'Carte bancaire',
        enabled: site.acceptsCardPayment,
        icon: Icons.credit_card,
      ),
      _ServiceFlag(label: 'Wi-Fi', enabled: site.hasWifi, icon: Icons.wifi),
      _ServiceFlag(
        label: 'Parking',
        enabled: site.hasParking,
        icon: Icons.local_parking_outlined,
      ),
      _ServiceFlag(
        label: 'Accessible',
        enabled: site.isAccessible,
        icon: Icons.accessible_outlined,
      ),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map(
            (item) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: item.enabled
                    ? AppColors.secondary.withValues(alpha: 0.12)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    size: 18,
                    color: item.enabled
                        ? AppColors.secondary
                        : Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.label,
                    style: AppTextStyles.caption.copyWith(
                      color: item.enabled
                          ? AppColors.secondary
                          : Colors.grey.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _OpeningHoursSection extends StatelessWidget {
  final List<ProfessionalOpeningHour> openingHours;

  const _OpeningHoursSection({required this.openingHours});

  @override
  Widget build(BuildContext context) {
    if (openingHours.isEmpty) {
      return Text(
        'Aucun horaire n a encore ete renseigne pour ce lieu.',
        style: AppTextStyles.body.copyWith(color: Colors.grey[700]),
      );
    }

    return Column(
      children: openingHours
          .map(
            (slot) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 92,
                    child: Text(
                      _dayLabel(slot.dayOfWeek),
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _openingText(slot),
                      style: AppTextStyles.body.copyWith(
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ActivitySection extends StatelessWidget {
  final ProfessionalSite site;

  const _ActivitySection({required this.site});

  @override
  Widget build(BuildContext context) {
    final verification = verificationStatusInfo(site.verificationStatus);
    final events = <_ActivityEvent>[
      if (site.createdAt != null)
        _ActivityEvent(
          title: 'Soumission initiale',
          timestamp: site.createdAt!,
          description:
              'La fiche a ete enregistree dans votre espace professionnel.',
          icon: Icons.flag_outlined,
          color: AppColors.primary,
        ),
      if (site.updatedAt != null)
        _ActivityEvent(
          title: 'Derniere modification',
          timestamp: site.updatedAt!,
          description:
              'Des changements ont ete enregistres sur la fiche du lieu.',
          icon: Icons.edit_outlined,
          color: Colors.orange.shade700,
        ),
      if (site.moderatedAt != null)
        _ActivityEvent(
          title: 'Decision de moderation',
          timestamp: site.moderatedAt!,
          description: site.moderatedByName.isNotEmpty
              ? 'Decision enregistree par ${site.moderatedByName}.'
              : 'Decision de moderation enregistree sur la fiche.',
          icon: Icons.verified_user_outlined,
          color: verification.color,
        ),
      if (site.lastVerifiedAt != null)
        _ActivityEvent(
          title: 'Verification terrain',
          timestamp: site.lastVerifiedAt!,
          description:
              'Une verification recente a alimente la fraicheur du lieu.',
          icon: Icons.location_searching_outlined,
          color: AppColors.secondary,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: verification.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(verification.icon, color: verification.color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      verification.label,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                        color: verification.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _moderationFeedback(site, verification.description),
                      style: AppTextStyles.body.copyWith(
                        color: Colors.grey[800],
                      ),
                    ),
                    if (site.moderationNotes.trim().isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          site.moderationNotes.trim(),
                          style: AppTextStyles.body.copyWith(
                            color: Colors.grey[900],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (events.isEmpty)
          Text(
            'Aucun evenement significatif n a encore ete enregistre pour cette fiche.',
            style: AppTextStyles.body.copyWith(color: Colors.grey[700]),
          )
        else
          ...events.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: event.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(event.icon, color: event.color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatDateTime(event.timestamp),
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.description,
                          style: AppTextStyles.body.copyWith(
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _RecentReviewsSection extends StatelessWidget {
  final List<Review> reviews;
  final ValueChanged<Review> onReply;

  const _RecentReviewsSection({required this.reviews, required this.onReply});

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) {
      return Text(
        'Aucun avis recent n est encore visible sur ce lieu.',
        style: AppTextStyles.body.copyWith(color: Colors.grey[700]),
      );
    }

    return Column(
      children: reviews
          .map(
            (review) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            review.author,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${review.rating}/5',
                          style: AppTextStyles.body.copyWith(
                            color: Colors.amber.shade800,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (review.title != null && review.title!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        review.title!,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      review.comment,
                      style: AppTextStyles.body.copyWith(
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      review.formattedDate,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _InlineMetric(
                          icon: Icons.thumb_up_alt_outlined,
                          label:
                              '${review.helpfulCount} utile${review.helpfulCount > 1 ? 's' : ''}',
                        ),
                        TextButton.icon(
                          onPressed: () => onReply(review),
                          icon: Icon(
                            review.hasOwnerResponse
                                ? Icons.edit_outlined
                                : Icons.reply_outlined,
                          ),
                          label: Text(
                            review.hasOwnerResponse
                                ? 'Modifier la reponse'
                                : 'Repondre',
                          ),
                        ),
                      ],
                    ),
                    if (review.hasOwnerResponse &&
                        (review.ownerResponse ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Votre reponse professionnelle',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              review.ownerResponse!.trim(),
                              style: AppTextStyles.body.copyWith(
                                color: Colors.grey[900],
                              ),
                            ),
                            if (review.ownerResponseDate != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                _formatDateTime(review.ownerResponseDate!),
                                style: AppTextStyles.caption.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _AnalyticsTile extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _AnalyticsTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
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
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.heading2.copyWith(fontSize: 24, color: color),
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

class _InlineMetric extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InlineMetric({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[700]),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: Colors.grey[700]),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(title, style: AppTextStyles.heading2.copyWith(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final ProfessionalStatusInfo info;

  const _StatusCard({required this.title, required this.info});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: info.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
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
          Icon(info.icon, color: info.color),
          const SizedBox(height: 10),
          Text(
            info.label,
            style: AppTextStyles.body.copyWith(
              color: info.color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            info.description,
            style: AppTextStyles.caption.copyWith(color: Colors.grey[800]),
          ),
        ],
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  final String label;
  final String value;

  const _MetricBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.76),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;

  const _HeroChip({
    required this.icon,
    required this.label,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 52),
            const SizedBox(height: 12),
            Text(
              'Impossible de charger cette fiche',
              style: AppTextStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: AppTextStyles.body.copyWith(color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceFlag {
  final String label;
  final bool enabled;
  final IconData icon;

  const _ServiceFlag({
    required this.label,
    required this.enabled,
    required this.icon,
  });
}

class _ActivityEvent {
  final String title;
  final DateTime timestamp;
  final String description;
  final IconData icon;
  final Color color;

  const _ActivityEvent({
    required this.title,
    required this.timestamp,
    required this.description,
    required this.icon,
    required this.color,
  });
}

String _priceLabel(String? priceRange) {
  switch (priceRange) {
    case 'BUDGET':
      return 'Economique';
    case 'MODERATE':
      return 'Modere';
    case 'EXPENSIVE':
      return 'Eleve';
    case 'LUXURY':
      return 'Luxe';
    default:
      return 'Non renseignee';
  }
}

String _dayLabel(String day) {
  const labels = <String, String>{
    'MONDAY': 'Lundi',
    'TUESDAY': 'Mardi',
    'WEDNESDAY': 'Mercredi',
    'THURSDAY': 'Jeudi',
    'FRIDAY': 'Vendredi',
    'SATURDAY': 'Samedi',
    'SUNDAY': 'Dimanche',
  };

  return labels[day] ?? day;
}

String _openingText(ProfessionalOpeningHour slot) {
  if (slot.isClosed) return 'Ferme';
  if (slot.is24Hours) return 'Ouvert 24h/24';

  final opens = _formatHour(slot.opensAt);
  final closes = _formatHour(slot.closesAt);
  final notes = slot.notes.trim();

  final base = (opens != null && closes != null)
      ? '$opens - $closes'
      : 'Horaire non precise';
  if (notes.isEmpty) {
    return base;
  }
  return '$base - $notes';
}

String? _formatHour(String? value) {
  if (value == null || value.isEmpty) return null;
  final parts = value.split(':');
  if (parts.length < 2) return value;
  return '${parts[0]}:${parts[1]}';
}

String _formatDateTime(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/$year a $hour:$minute';
}

String _moderationFeedback(ProfessionalSite site, String fallbackDescription) {
  final actor = site.moderatedByName.isNotEmpty
      ? ' par ${site.moderatedByName}'
      : '';

  switch (site.verificationStatus) {
    case 'VERIFIED':
      return site.moderationNotes.trim().isNotEmpty
          ? 'Validation confirmee$actor. Voici le dernier retour enregistre.'
          : 'Votre lieu est valide. Les visiteurs peuvent consulter une fiche confirmee et le suivi terrain alimente sa fraicheur.';
    case 'REJECTED':
      return site.moderationNotes.trim().isNotEmpty
          ? 'La fiche a ete refusee$actor. Corrigez les points indiques ci-dessous avant une nouvelle soumission.'
          : 'La fiche a ete refusee, mais aucun commentaire detaille n a encore ete fourni.';
    case 'PENDING':
      return 'La revue est toujours en attente. Aucun retour de moderation detaille n est encore disponible.';
    default:
      return fallbackDescription;
  }
}
