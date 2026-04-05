import 'package:flutter/material.dart';

class LoadingSkeleton extends StatelessWidget {
  final LoadingSkeletonVariant variant;

  const LoadingSkeleton.list({super.key})
    : variant = LoadingSkeletonVariant.list;

  const LoadingSkeleton.card({super.key})
    : variant = LoadingSkeletonVariant.card;

  const LoadingSkeleton.media({super.key})
    : variant = LoadingSkeletonVariant.media;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.onSurface.withValues(alpha: 0.08);

    switch (variant) {
      case LoadingSkeletonVariant.list:
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (_, _) => _SkeletonBlock(
            height: 88,
            borderRadius: BorderRadius.circular(24),
            color: baseColor,
          ),
        );
      case LoadingSkeletonVariant.card:
        return _SkeletonBlock(
          height: 180,
          borderRadius: BorderRadius.circular(24),
          color: baseColor,
        );
      case LoadingSkeletonVariant.media:
        return _SkeletonBlock(
          height: 240,
          borderRadius: BorderRadius.circular(24),
          color: baseColor,
        );
    }
  }
}

enum LoadingSkeletonVariant { list, card, media }

class _SkeletonBlock extends StatelessWidget {
  final double height;
  final BorderRadius borderRadius;
  final Color color;

  const _SkeletonBlock({
    required this.height,
    required this.borderRadius,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(color: color, borderRadius: borderRadius),
    );
  }
}
