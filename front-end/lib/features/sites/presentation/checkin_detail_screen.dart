import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/api_service.dart';
import '../../../core/utils/media_url.dart';
import 'checkin_photo_gallery_screen.dart';
import 'models/checkin_detail.dart';

class CheckinDetailScreen extends StatefulWidget {
  final String checkinId;
  final ApiService? apiService;

  const CheckinDetailScreen({
    super.key,
    required this.checkinId,
    this.apiService,
  });

  @override
  State<CheckinDetailScreen> createState() => _CheckinDetailScreenState();
}

class _CheckinDetailScreenState extends State<CheckinDetailScreen> {
  late final ApiService _apiService;
  final PageController _pageController = PageController();

  CheckinDetail? _checkin;
  bool _isLoading = true;
  String? _error;
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCheckin();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadCheckin() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final checkin = await _apiService.fetchCheckinDetail(widget.checkinId);
      if (!mounted) return;
      setState(() {
        _checkin = checkin;
        _currentPhotoIndex = 0;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day/$month/$year a $hour:$minute';
  }

  String _formatDistance(double distance) {
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(2)} km';
    }
    return '${distance.toStringAsFixed(distance < 10 ? 1 : 0)} m';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'OPEN':
        return AppColors.secondary;
      case 'CLOSED':
      case 'CLOSED_PERMANENTLY':
        return AppColors.error;
      case 'UNDER_CONSTRUCTION':
      case 'RENOVATING':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail du check-in'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorState()
          : _checkin == null
          ? const Center(child: Text('Check-in introuvable.'))
          : RefreshIndicator(
              onRefresh: _loadCheckin,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeaderCard(_checkin!),
                  const SizedBox(height: 16),
                  if (_checkin!.photos.isNotEmpty) ...[
                    _buildGalleryCard(_checkin!),
                    const SizedBox(height: 16),
                  ],
                  _buildSummaryCard(_checkin!),
                  const SizedBox(height: 16),
                  if (_checkin!.verificationNotes.trim().isNotEmpty) ...[
                    _buildVerificationNotesCard(_checkin!),
                    const SizedBox(height: 16),
                  ],
                  if ((_checkin!.comment ?? '').trim().isNotEmpty) ...[
                    _buildCommentCard(_checkin!),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 52),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Impossible de charger ce check-in.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadCheckin,
              icon: const Icon(Icons.refresh),
              label: const Text('Reessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(CheckinDetail checkin) {
    final statusColor = _statusColor(checkin.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(checkin.siteName, style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildChip(
                  label: checkin.formattedStatus,
                  backgroundColor: statusColor.withValues(alpha: 0.12),
                  foregroundColor: statusColor,
                ),
                _buildChip(
                  label: checkin.validationStatus,
                  backgroundColor: AppColors.secondary.withValues(alpha: 0.12),
                  foregroundColor: AppColors.secondary,
                ),
                _buildChip(
                  label: '+${checkin.pointsEarned} pts',
                  backgroundColor: Colors.amber.withValues(alpha: 0.18),
                  foregroundColor: Colors.orange.shade800,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Effectue le ${_formatDate(checkin.createdAt)} par ${checkin.authorName}',
              style: AppTextStyles.caption.copyWith(color: Colors.grey[700]),
            ),
            if (checkin.photos.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${checkin.photos.length} photo${checkin.photos.length > 1 ? 's' : ''} jointe${checkin.photos.length > 1 ? 's' : ''}',
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

  Widget _buildGalleryCard(CheckinDetail checkin) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Galerie photo',
              style: AppTextStyles.heading2.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 12),
            AspectRatio(
              aspectRatio: 1.2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: checkin.photos.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPhotoIndex = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final photo = checkin.photos[index];
                    return GestureDetector(
                      onTap: () =>
                          _openPhotoGallery(checkin, initialIndex: index),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            buildMediaUrl(photo.imageUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: AppColors.surfaceAlt,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.open_in_full,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Plein ecran',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Photo ${_currentPhotoIndex + 1} / ${checkin.photos.length}',
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
                if ((checkin.photos[_currentPhotoIndex].caption ?? '')
                    .trim()
                    .isNotEmpty)
                  Flexible(
                    child: Text(
                      checkin.photos[_currentPhotoIndex].caption!.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: checkin.photos.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final photo = checkin.photos[index];
                  final isSelected = index == _currentPhotoIndex;
                  return GestureDetector(
                    onTap: () {
                      if (index == _currentPhotoIndex) {
                        _openPhotoGallery(checkin, initialIndex: index);
                        return;
                      }
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          buildMediaUrl(photo.thumbnailUrl ?? photo.imageUrl),
                          width: 70,
                          height: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 70,
                              height: 70,
                              color: AppColors.surfaceAlt,
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(CheckinDetail checkin) {
    final locationLines = <String>[
      if (checkin.address.trim().isNotEmpty) checkin.address.trim(),
      if (checkin.city.trim().isNotEmpty || checkin.region.trim().isNotEmpty)
        [
          checkin.city.trim(),
          checkin.region.trim(),
        ].where((part) => part.isNotEmpty).join(', '),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resume du check-in',
              style: AppTextStyles.heading2.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 12),
            _buildMetricRow(
              Icons.route_outlined,
              'Distance',
              _formatDistance(checkin.distance),
            ),
            _buildMetricRow(
              Icons.gps_fixed,
              'Precision GPS',
              '${checkin.accuracy.toStringAsFixed(0)} m',
            ),
            _buildMetricRow(
              Icons.verified_outlined,
              'Verification',
              checkin.validationStatus,
            ),
            _buildMetricRow(
              Icons.camera_alt_outlined,
              'Preuve photo',
              checkin.hasPhoto ? 'Oui' : 'Non',
            ),
            if (checkin.visitDurationSeconds > 0)
              _buildMetricRow(
                Icons.timer_outlined,
                'Presence sur place',
                '${checkin.visitDurationSeconds}s',
              ),
            const SizedBox(height: 4),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              'Lieu concerne',
              style: AppTextStyles.caption.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (locationLines.isNotEmpty)
              Text(locationLines.join('\n'), style: AppTextStyles.body),
            if (locationLines.isNotEmpty) const SizedBox(height: 12),
            Text(
              'Coordonnees du check-in',
              style: AppTextStyles.caption.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${checkin.latitude.toStringAsFixed(5)}, ${checkin.longitude.toStringAsFixed(5)}',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => context.push('/sites/${checkin.siteId}'),
              icon: const Icon(Icons.place_outlined),
              label: const Text('Voir la fiche du site'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationNotesCard(CheckinDetail checkin) {
    final allowedDistance =
        checkin.validationContext['allowed_distance_meters'];
    final allowedAccuracy =
        checkin.validationContext['allowed_accuracy_meters'];
    final recommendedDuration =
        checkin.validationContext['minimum_visit_duration_seconds'];
    final radiusStrategy =
        '${checkin.validationContext['radius_strategy'] ?? ''}'.trim();
    final lines = checkin.verificationNotes
        .split('|')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (radiusStrategy.isNotEmpty)
          Text(
            'Strategie: $radiusStrategy',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
          ),
        if (allowedDistance != null || allowedAccuracy != null) ...[
          const SizedBox(height: 8),
          Text(
            [
              if (allowedDistance != null) 'Rayon max: $allowedDistance m',
              if (allowedAccuracy != null) 'Precision max: $allowedAccuracy m',
              if (recommendedDuration != null)
                'Duree cible: ${recommendedDuration}s',
            ].join(' - '),
            style: AppTextStyles.caption.copyWith(color: Colors.grey[700]),
          ),
        ],
        const SizedBox(height: 12),
        ...lines.map(
          (line) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Icon(
                    Icons.verified_outlined,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(line, style: AppTextStyles.body)),
              ],
            ),
          ),
        ),
      ],
    );

    if (_hasModerationNotes(checkin)) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contexte de verification',
                style: AppTextStyles.heading2.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 10),
              content,
            ],
          ),
        ),
      );
    }

    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Text(
            'Contexte de verification',
            style: AppTextStyles.heading2.copyWith(fontSize: 20),
          ),
          subtitle: Text(
            'Voir les notes et seuils de verification',
            style: AppTextStyles.caption.copyWith(color: Colors.grey[700]),
          ),
          children: [content],
        ),
      ),
    );
  }

  Widget _buildCommentCard(CheckinDetail checkin) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Commentaire',
              style: AppTextStyles.heading2.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 10),
            Text(checkin.comment!.trim(), style: AppTextStyles.body),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: AppTextStyles.body)),
          Text(
            value,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  bool _hasModerationNotes(CheckinDetail checkin) {
    final notes = checkin.verificationNotes.toLowerCase();
    final status = checkin.validationStatus.toUpperCase();

    return status == 'REJECTED' ||
        notes.contains('moder') ||
        notes.contains('rejet') ||
        notes.contains('reject') ||
        notes.contains('admin') ||
        notes.contains('manuel') ||
        notes.contains('manual');
  }

  Future<void> _openPhotoGallery(
    CheckinDetail checkin, {
    required int initialIndex,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CheckinPhotoGalleryScreen(
          photos: checkin.photos,
          initialIndex: initialIndex,
          title: checkin.siteName,
        ),
      ),
    );
  }
}
