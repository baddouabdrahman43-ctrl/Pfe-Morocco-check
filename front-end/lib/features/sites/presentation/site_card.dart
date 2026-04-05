import 'package:flutter/material.dart';

import '../../../shared/widgets/site_preview_card.dart';
import 'sites/site.dart';

class SiteCard extends StatelessWidget {
  final Site site;
  final VoidCallback? onTap;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;

  const SiteCard({
    super.key,
    required this.site,
    this.onTap,
    this.isFavorite = false,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return SitePreviewCard(
      site: site,
      onTap: onTap,
      isFavorite: isFavorite,
      onToggleFavorite: onToggleFavorite,
    );
  }
}
