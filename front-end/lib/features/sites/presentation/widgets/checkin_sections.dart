import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class CheckinSiteSummaryCard extends StatelessWidget {
  final String name;
  final String category;

  const CheckinSiteSummaryCard({
    super.key,
    required this.name,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            Text(
              category,
              style: AppTextStyles.body.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CheckinPolicyCard extends StatelessWidget {
  final String strategyLabel;
  final int allowedDistanceMeters;
  final int maxAccuracyMeters;
  final int minimumVisitDurationSeconds;
  final int pendingQueueCount;

  const CheckinPolicyCard({
    super.key,
    required this.strategyLabel,
    required this.allowedDistanceMeters,
    required this.maxAccuracyMeters,
    required this.minimumVisitDurationSeconds,
    required this.pendingQueueCount,
  });

  @override
  Widget build(BuildContext context) {
    final summary =
        '$strategyLabel - Rayon $allowedDistanceMeters m - Precision <= $maxAccuracyMeters m';

    return Card(
      color: AppColors.primary.withValues(alpha: 0.06),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            'Politique de verification',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(summary, style: AppTextStyles.caption),
          trailing: const Text('En savoir plus'),
          children: [
            Text(
              'Presence recommandee: $minimumVisitDurationSeconds s avant soumission.',
              style: AppTextStyles.caption,
            ),
            if (pendingQueueCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '$pendingQueueCount check-in${pendingQueueCount > 1 ? 's' : ''} en attente de synchronisation.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class CheckinLocationLoadingCard extends StatelessWidget {
  const CheckinLocationLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Verification de votre position...',
                style: AppTextStyles.body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CheckinDistanceCard extends StatelessWidget {
  final double distanceMeters;
  final int allowedDistanceMeters;
  final double? positionAccuracy;
  final int? visitDurationSeconds;
  final String Function(double value) formatDistance;

  const CheckinDistanceCard({
    super.key,
    required this.distanceMeters,
    required this.allowedDistanceMeters,
    required this.formatDistance,
    this.positionAccuracy,
    this.visitDurationSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final isAllowed = distanceMeters <= allowedDistanceMeters;

    return Card(
      color: isAllowed
          ? AppColors.secondary.withValues(alpha: 0.1)
          : AppColors.error.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isAllowed ? Icons.check_circle : Icons.error,
              color: isAllowed ? AppColors.secondary : AppColors.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Distance: ${formatDistance(distanceMeters)}',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Rayon autorise: $allowedDistanceMeters m',
                    style: AppTextStyles.caption,
                  ),
                  if (positionAccuracy != null)
                    Text(
                      'Precision GPS: ${positionAccuracy!.toStringAsFixed(0)} m',
                      style: AppTextStyles.caption,
                    ),
                  if (visitDurationSeconds != null)
                    Text(
                      'Temps passe sur place: ${visitDurationSeconds!}s',
                      style: AppTextStyles.caption,
                    ),
                  if (isAllowed)
                    Text(
                      'Vous etes a proximite du site',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.secondary,
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
}

class CheckinErrorCard extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const CheckinErrorCard({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.error.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.error_outline, color: AppColors.error),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error,
                    style: AppTextStyles.body.copyWith(color: AppColors.error),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CheckinRestrictionCard extends StatelessWidget {
  final String message;

  const CheckinRestrictionCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.error.withValues(alpha: 0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline, color: AppColors.error),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.body.copyWith(color: AppColors.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CheckinPhotoSection extends StatelessWidget {
  final bool isLoading;
  final List<XFile> selectedPhotos;
  final VoidCallback onAddPhotos;
  final ValueChanged<XFile> onRemovePhoto;

  const CheckinPhotoSection({
    super.key,
    required this.isLoading,
    required this.selectedPhotos,
    required this.onAddPhotos,
    required this.onRemovePhoto,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos du check-in',
          style: AppTextStyles.heading2.copyWith(fontSize: 20),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: isLoading || selectedPhotos.length >= 5
              ? null
              : onAddPhotos,
          icon: const Icon(Icons.add_a_photo_outlined),
          label: Text(
            selectedPhotos.isEmpty
                ? 'Ajouter jusqu a 5 photos'
                : 'Ajouter d autres photos',
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            selectedPhotos.isEmpty
                ? 'Ajoutez des photos pour renforcer la preuve terrain de votre check-in.'
                : '${selectedPhotos.length} photo${selectedPhotos.length > 1 ? 's' : ''} selectionnee${selectedPhotos.length > 1 ? 's' : ''}. Un check-in avec photo rapporte plus de points.',
            style: AppTextStyles.caption.copyWith(color: Colors.grey[800]),
          ),
        ),
        if (selectedPhotos.isNotEmpty) const SizedBox(height: 12),
        if (selectedPhotos.isNotEmpty)
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: selectedPhotos.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final photo = selectedPhotos[index];
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FutureBuilder<Uint8List>(
                        future: photo.readAsBytes(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return Image.memory(
                              snapshot.data!,
                              width: 96,
                              height: 96,
                              fit: BoxFit.cover,
                            );
                          }

                          return Container(
                            width: 96,
                            height: 96,
                            color: Colors.grey[300],
                            alignment: Alignment.center,
                            child: snapshot.hasError
                                ? Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.grey[700],
                                  )
                                : const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: isLoading ? null : () => onRemovePhoto(photo),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}

class CheckinSuccessAnimationOverlay extends StatefulWidget {
  final VoidCallback onAnimationComplete;
  final int pointsEarned;

  const CheckinSuccessAnimationOverlay({
    super.key,
    required this.onAnimationComplete,
    required this.pointsEarned,
  });

  @override
  State<CheckinSuccessAnimationOverlay> createState() =>
      _CheckinSuccessAnimationOverlayState();
}

class _CheckinSuccessAnimationOverlayState
    extends State<CheckinSuccessAnimationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pointsAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    _pointsAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        widget.onAnimationComplete();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Check-in reussi!',
                    style: AppTextStyles.heading2.copyWith(
                      fontSize: 24,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedBuilder(
                    animation: _pointsAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _pointsAnimation.value,
                        child: Transform.translate(
                          offset: Offset(0, -20 * (1 - _pointsAnimation.value)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.stars,
                                  color: AppColors.secondary,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '+${widget.pointsEarned} points',
                                  style: AppTextStyles.body.copyWith(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
