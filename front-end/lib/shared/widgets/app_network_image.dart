import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/utils/media_url.dart';

class AppNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final Widget fallback;
  final double? width;
  final double? height;
  final Alignment alignment;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    required this.fallback,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = buildMediaUrl(imageUrl);
    if (resolvedUrl.isEmpty) {
      return fallback;
    }

    return Image.network(
      resolvedUrl,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      errorBuilder: (context, error, stackTrace) => fallback,
      webHtmlElementStrategy: kIsWeb
          ? WebHtmlElementStrategy.prefer
          : WebHtmlElementStrategy.never,
    );
  }
}
