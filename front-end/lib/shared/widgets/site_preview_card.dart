import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/theme/spacing_tokens.dart';
import '../../features/sites/presentation/sites/site.dart';
import 'app_network_image.dart';

class SitePreviewCard extends StatelessWidget {
  final Site site;
  final VoidCallback? onTap;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;
  final bool compact;
  final double? width;

  const SitePreviewCard({
    super.key,
    required this.site,
    this.onTap,
    this.isFavorite = false,
    this.onToggleFavorite,
    this.compact = false,
    this.width,
  });

  const SitePreviewCard.compact({
    super.key,
    required this.site,
    this.onTap,
    this.isFavorite = false,
    this.onToggleFavorite,
    this.width = 220,
  }) : compact = true;

  @override
  Widget build(BuildContext context) {
    final child = compact
        ? _buildCompactCard(context)
        : _buildLargeCard(context);

    if (width == null) {
      return child;
    }

    return SizedBox(width: width, child: child);
  }

  Widget _buildLargeCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.l,
        vertical: SpacingTokens.m,
      ),
      child: _SurfaceCard(
        onTap: onTap,
        borderRadius: RadiusTokens.card,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroImage(
              site: site,
              isFavorite: isFavorite,
              onToggleFavorite: onToggleFavorite,
              compact: false,
            ),
            Padding(
              padding: const EdgeInsets.all(RadiusTokens.form),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TitleRow(site: site),
                  const SizedBox(height: SpacingTokens.m),
                  Wrap(
                    spacing: SpacingTokens.s,
                    runSpacing: SpacingTokens.s,
                    children: [
                      _MetaPill(
                        icon: Icons.category_outlined,
                        label: site.category,
                      ),
                      if (site.hasDistance)
                        _MetaPill(
                          icon: Icons.route_outlined,
                          label: site.formattedDistance,
                          highlighted: true,
                        ),
                      _MetaPill(
                        icon: Icons.verified_outlined,
                        label: '${site.freshnessScore}% fiable',
                      ),
                    ],
                  ),
                  const SizedBox(height: SpacingTokens.m),
                  Text(
                    site.description.isEmpty
                        ? 'Une adresse a garder dans votre itineraire avec une fiche rapide a consulter.'
                        : site.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCard(BuildContext context) {
    return _SurfaceCard(
      onTap: onTap,
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeroImage(
            site: site,
            isFavorite: isFavorite,
            onToggleFavorite: onToggleFavorite,
            compact: true,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
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
                const SizedBox(height: 6),
                Text(
                  [
                    if (site.city.isNotEmpty) site.city,
                    if (site.category.isNotEmpty) site.category,
                  ].join(' - '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: AppColors.accentGold,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      site.rating.toStringAsFixed(1),
                      style: AppTextStyles.caption.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      site.hasDistance
                          ? site.formattedDistance
                          : '${site.freshnessScore}% fiable',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primaryDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;

  const _SurfaceCard({
    required this.child,
    required this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  final Site site;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;
  final bool compact;

  const _HeroImage({
    required this.site,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final height = compact ? 110.0 : 220.0;
    final radius = compact ? 22.0 : RadiusTokens.card;
    final imageUrl = site.previewPhotos.isNotEmpty
        ? site.previewPhotos.first
        : site.imageUrl;

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: imageUrl.isNotEmpty
                ? AppNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.cover,
                    fallback: _ImagePlaceholder(compact: compact),
                  )
                : _ImagePlaceholder(compact: compact),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Material(
            color: Colors.white.withValues(alpha: 0.92),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onToggleFavorite,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: compact ? 18 : 20,
                  color: isFavorite ? AppColors.error : AppColors.primaryDeep,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 8,
          bottom: 8,
          child: Wrap(
            spacing: 8,
            children: [
              if (site.hasDistance)
                _OverlayPill(
                  icon: Icons.near_me_outlined,
                  label: site.formattedDistance,
                ),
              _OverlayPill(
                icon: Icons.place_outlined,
                label: site.city.isNotEmpty ? site.city : 'Maroc',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final bool compact;

  const _ImagePlaceholder({required this.compact});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB8F2D9), Color(0xFFDCF9EC)],
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        compact ? Icons.place_outlined : Icons.travel_explore,
        size: compact ? 28 : 52,
        color: AppColors.primaryDeep,
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  final Site site;

  const _TitleRow({required this.site});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            site.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.heading2.copyWith(fontSize: 22),
          ),
        ),
        const SizedBox(width: SpacingTokens.m),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: SpacingTokens.m,
            vertical: SpacingTokens.s,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(RadiusTokens.form),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star_rounded,
                size: 16,
                color: AppColors.accentGold,
              ),
              const SizedBox(width: 4),
              Text(
                site.rating.toStringAsFixed(1),
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.primaryDeep,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlighted;

  const _MetaPill({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFE8F3FF) : AppColors.background,
        borderRadius: BorderRadius.circular(RadiusTokens.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primaryDeep),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: highlighted
                  ? AppColors.primaryDeep
                  : AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _OverlayPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(RadiusTokens.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
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
