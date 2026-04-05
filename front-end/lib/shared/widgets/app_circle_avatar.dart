import 'package:flutter/material.dart';

import 'app_network_image.dart';

class AppCircleAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Color? backgroundColor;
  final Widget fallback;

  const AppCircleAvatar({
    super.key,
    required this.imageUrl,
    required this.radius,
    required this.fallback,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final diameter = radius * 2;

    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: ClipOval(
        child: SizedBox(
          width: diameter,
          height: diameter,
          child: AppNetworkImage(
            imageUrl: imageUrl ?? '',
            fit: BoxFit.cover,
            fallback: SizedBox(
              width: diameter,
              height: diameter,
              child: Center(child: fallback),
            ),
          ),
        ),
      ),
    );
  }
}
