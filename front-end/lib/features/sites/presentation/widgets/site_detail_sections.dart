import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../shared/widgets/app_network_image.dart';
import '../models/site_photo.dart';
import '../sites/site.dart';

class SiteDetailPlaceholderImage extends StatelessWidget {
  final double height;

  const SiteDetailPlaceholderImage({super.key, this.height = 300});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      color: Colors.grey[300],
      child: Icon(Icons.place, size: 64, color: Colors.grey[600]),
    );
  }
}

class SiteDetailHeroChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const SiteDetailHeroChip({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.white),
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

class SiteDetailMetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  const SiteDetailMetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(height: 12),
          Text(value, style: AppTextStyles.heading2.copyWith(fontSize: 22)),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

class SiteDetailInfoSection extends StatelessWidget {
  final String title;
  final Widget child;

  const SiteDetailInfoSection({
    super.key,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.heading2.copyWith(fontSize: 20)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class SiteDetailInfoTab extends StatelessWidget {
  final Site site;
  final List<Site> relatedSites;
  final VoidCallback onViewMap;
  final VoidCallback onOpenItinerary;
  final ValueChanged<Site> onRelatedSiteTap;

  const SiteDetailInfoTab({
    super.key,
    required this.site,
    required this.relatedSites,
    required this.onViewMap,
    required this.onOpenItinerary,
    required this.onRelatedSiteTap,
  });

  @override
  Widget build(BuildContext context) {
    final location = [
      site.address,
      site.city,
      site.region,
    ].where((item) => item.isNotEmpty).join(', ');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SiteDetailInfoSection(
            title: 'Description',
            child: Text(
              site.description.isNotEmpty
                  ? site.description
                  : 'Aucune description disponible pour ce lieu.',
              style: AppTextStyles.body.copyWith(
                color: Colors.grey[700],
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SiteDetailInfoSection(
            title: 'Localisation',
            child: Column(
              children: [
                SiteDetailRow(
                  icon: Icons.pin_drop_outlined,
                  label: 'Adresse',
                  value: location.isNotEmpty ? location : 'Non renseignee',
                ),
                SiteDetailRow(
                  icon: Icons.my_location_outlined,
                  label: 'Coordonnees',
                  value:
                      '${site.latitude.toStringAsFixed(4)}, ${site.longitude.toStringAsFixed(4)}',
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: onViewMap,
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Voir sur la carte'),
                      ),
                      TextButton.icon(
                        onPressed: onOpenItinerary,
                        icon: const Icon(Icons.alt_route_outlined),
                        label: const Text('Itineraire reel'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SiteDetailInfoSection(
            title: 'Resume',
            child: Column(
              children: [
                SiteDetailRow(
                  icon: Icons.category_outlined,
                  label: 'Categorie',
                  value: site.category,
                ),
                SiteDetailRow(
                  icon: Icons.star_outline,
                  label: 'Note moyenne',
                  value: site.rating.toStringAsFixed(1),
                ),
                SiteDetailRow(
                  icon: Icons.reviews_outlined,
                  label: 'Avis',
                  value: '${site.totalReviews}',
                ),
                SiteDetailRow(
                  icon: Icons.verified_outlined,
                  label: 'Verification',
                  value: site.verificationStatus == 'VERIFIED'
                      ? 'Lieu verifie'
                      : 'Verification en attente',
                ),
                SiteDetailRow(
                  icon: Icons.bolt_outlined,
                  label: 'Score de fraicheur',
                  value: '${site.freshnessScore}%',
                ),
              ],
            ),
          ),
          if (_shouldShowPracticalInfo(site)) const SizedBox(height: 16),
          if (_shouldShowPracticalInfo(site))
            SiteDetailInfoSection(
              title: 'Infos pratiques',
              child: Column(
                children: [
                  if (site.phoneNumber.isNotEmpty)
                    SiteDetailRow(
                      icon: Icons.phone_outlined,
                      label: 'Telephone',
                      value: site.phoneNumber,
                    ),
                  if (site.website.isNotEmpty)
                    SiteDetailRow(
                      icon: Icons.language_outlined,
                      label: 'Site web',
                      value: site.website,
                    ),
                  if (site.priceRange != null)
                    SiteDetailRow(
                      icon: Icons.payments_outlined,
                      label: 'Budget',
                      value: formatSitePriceRange(site.priceRange),
                    ),
                  if (site.hasWifi)
                    const SiteDetailRow(
                      icon: Icons.wifi_outlined,
                      label: 'Wi-Fi',
                      value: 'Disponible',
                    ),
                  if (site.hasParking)
                    const SiteDetailRow(
                      icon: Icons.local_parking_outlined,
                      label: 'Parking',
                      value: 'Disponible',
                    ),
                  if (site.acceptsCardPayment)
                    const SiteDetailRow(
                      icon: Icons.credit_card_outlined,
                      label: 'Paiement',
                      value: 'Carte acceptee',
                    ),
                  if (site.isAccessible)
                    const SiteDetailRow(
                      icon: Icons.accessible_outlined,
                      label: 'Accessibilite',
                      value: 'Acces facilite',
                    ),
                ],
              ),
            ),
          if (site.amenities.isNotEmpty) const SizedBox(height: 16),
          if (site.amenities.isNotEmpty)
            SiteDetailInfoSection(
              title: 'Points forts',
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: site.amenities
                    .map(
                      (amenity) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          amenity,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.primaryDeep,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          const SizedBox(height: 16),
          SiteDetailInfoSection(
            title: 'Horaires',
            child: OpeningHoursSection(site: site),
          ),
          if (relatedSites.isNotEmpty) const SizedBox(height: 16),
          if (relatedSites.isNotEmpty)
            SiteDetailInfoSection(
              title: 'Suggestions pour vous',
              child: Column(
                children: relatedSites
                    .map(
                      (relatedSite) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: RelatedSiteCard(
                          site: relatedSite,
                          onTap: () => onRelatedSiteTap(relatedSite),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  bool _shouldShowPracticalInfo(Site site) {
    return site.phoneNumber.isNotEmpty ||
        site.website.isNotEmpty ||
        site.priceRange != null ||
        site.hasWifi ||
        site.hasParking ||
        site.acceptsCardPayment ||
        site.isAccessible;
  }
}

class SiteDetailPhotosTab extends StatelessWidget {
  final bool isLoading;
  final List<SitePhoto> photos;

  const SiteDetailPhotosTab({
    super.key,
    required this.isLoading,
    required this.photos,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (photos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 56,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 12),
              Text(
                'Aucune photo disponible',
                style: AppTextStyles.body.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 6),
              Text(
                'Le lieu est deja accessible, mais la galerie sera plus riche quand la communaute ajoutera davantage de contenus.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        final imageUrl = photo.thumbnailUrl?.isNotEmpty == true
            ? photo.thumbnailUrl!
            : photo.imageUrl;

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                fallback: const _SitePhotoPlaceholder(),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.center,
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              if (photo.isPrimary)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Principale',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class SiteDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const SiteDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class OpeningHoursSection extends StatelessWidget {
  final Site site;

  const OpeningHoursSection({super.key, required this.site});

  @override
  Widget build(BuildContext context) {
    if (site.openingHours.isEmpty) {
      return Text(
        'Horaires non renseignes pour le moment.',
        style: AppTextStyles.body.copyWith(color: Colors.grey[700]),
      );
    }

    return Column(
      children: site.openingHours.map((hours) {
        final value = hours.is24Hours
            ? 'Ouvert 24h/24'
            : hours.isClosed
            ? 'Ferme'
            : '${formatSiteTime(hours.opensAt)} - ${formatSiteTime(hours.closesAt)}';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 95,
                    child: Text(
                      formatSiteDayLabel(hours.dayOfWeek),
                      style: AppTextStyles.body.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      value,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (hours.notes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      hours.notes,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class RelatedSiteCard extends StatelessWidget {
  final Site site;
  final VoidCallback onTap;

  const RelatedSiteCard({super.key, required this.site, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 68,
                height: 68,
                child: site.imageUrl.isNotEmpty
                    ? AppNetworkImage(
                        imageUrl: site.imageUrl,
                        fit: BoxFit.cover,
                        fallback: const _CompactSitePlaceholder(),
                      )
                    : const _CompactSitePlaceholder(),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    site.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      site.category,
                      if (site.city.isNotEmpty) site.city,
                    ].join(' - '),
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 15,
                      color: AppColors.accentGold,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      site.rating.toStringAsFixed(1),
                      style: AppTextStyles.bodyStrong,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '${site.freshnessScore}% fiable',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primaryDeep,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String formatSitePriceRange(String? priceRange) {
  switch (priceRange) {
    case 'BUDGET':
      return 'Economique';
    case 'MODERATE':
      return 'Moyen';
    case 'EXPENSIVE':
      return 'Haut de gamme';
    case 'LUXURY':
      return 'Luxe';
    default:
      return priceRange ?? 'Non renseigne';
  }
}

String formatSiteDayLabel(String dayOfWeek) {
  switch (dayOfWeek) {
    case 'MONDAY':
      return 'Lundi';
    case 'TUESDAY':
      return 'Mardi';
    case 'WEDNESDAY':
      return 'Mercredi';
    case 'THURSDAY':
      return 'Jeudi';
    case 'FRIDAY':
      return 'Vendredi';
    case 'SATURDAY':
      return 'Samedi';
    case 'SUNDAY':
      return 'Dimanche';
    default:
      return dayOfWeek;
  }
}

String formatSiteTime(String? value) {
  if (value == null || value.isEmpty) {
    return '--:--';
  }

  if (value.length >= 5) {
    return value.substring(0, 5);
  }

  return value;
}

class _CompactSitePlaceholder extends StatelessWidget {
  const _CompactSitePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: Icon(Icons.place_outlined, color: Colors.grey[500]),
    );
  }
}

class _SitePhotoPlaceholder extends StatelessWidget {
  const _SitePhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[300],
      child: Icon(Icons.image, size: 48, color: Colors.grey[600]),
    );
  }
}
