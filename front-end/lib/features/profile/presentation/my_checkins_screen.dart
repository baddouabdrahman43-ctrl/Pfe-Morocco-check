import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/api_service.dart';
import '../../../shared/widgets/app_network_image.dart';
import 'models/checkin_history_item.dart';

enum _CheckinFilter { all, approved, pending, withPhotos }

class MyCheckinsScreen extends StatefulWidget {
  const MyCheckinsScreen({super.key});

  @override
  State<MyCheckinsScreen> createState() => _MyCheckinsScreenState();
}

class _MyCheckinsScreenState extends State<MyCheckinsScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final List<CheckinHistoryItem> _items = <CheckinHistoryItem>[];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _currentPage = 1;
  _CheckinFilter _selectedFilter = _CheckinFilter.all;

  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMore) {
      return;
    }

    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 280) {
      _loadMore();
    }
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      final result = await _apiService.fetchMyCheckins(
        page: 1,
        limit: _pageSize,
      );
      if (!mounted) return;

      setState(() {
        _items
          ..clear()
          ..addAll(result.items);
        _hasMore = _items.length < result.total;
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

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final result = await _apiService.fetchMyCheckins(
        page: nextPage,
        limit: _pageSize,
      );
      if (!mounted) return;

      setState(() {
        _items.addAll(result.items);
        _currentPage = nextPage;
        _hasMore = _items.length < result.total;
        _isLoadingMore = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoadingMore = false;
      });
    }
  }

  List<CheckinHistoryItem> get _filteredItems {
    switch (_selectedFilter) {
      case _CheckinFilter.all:
        return _items;
      case _CheckinFilter.approved:
        return _items.where((item) => item.isApproved).toList();
      case _CheckinFilter.pending:
        return _items.where((item) => item.isPendingReview).toList();
      case _CheckinFilter.withPhotos:
        return _items.where((item) => item.hasPhotos).toList();
    }
  }

  int _countFor(_CheckinFilter filter) {
    switch (filter) {
      case _CheckinFilter.all:
        return _items.length;
      case _CheckinFilter.approved:
        return _items.where((item) => item.isApproved).length;
      case _CheckinFilter.pending:
        return _items.where((item) => item.isPendingReview).length;
      case _CheckinFilter.withPhotos:
        return _items.where((item) => item.hasPhotos).length;
    }
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/$year a $hour:$minute';
  }

  String _formatDistance(double distance) {
    if (distance >= 1000) {
      return '${(distance / 1000).toStringAsFixed(1)} km';
    }
    return '${distance.toStringAsFixed(distance < 10 ? 1 : 0)} m';
  }

  Color _validationColor(String value) {
    switch (value) {
      case 'APPROVED':
        return AppColors.secondary;
      case 'PENDING':
        return Colors.orange;
      case 'REJECTED':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _filteredItems;

    return Scaffold(
      appBar: AppBar(title: const Text('Mes check-ins')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInitial,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryBand(),
                  const SizedBox(height: 12),
                  _buildFilterBar(),
                  const SizedBox(height: 16),
                  if (_items.isEmpty)
                    _buildEmptyState(
                      title: 'Aucun check-in pour le moment',
                      message:
                          _error ??
                          'Vos futurs check-ins apparaitront ici avec leur statut de validation.',
                      showExploreAction: true,
                    )
                  else if (visibleItems.isEmpty)
                    _buildEmptyState(
                      title: 'Aucun resultat pour ce filtre',
                      message:
                          'Essayez un autre filtre pour revoir l ensemble de votre historique.',
                      showExploreAction: false,
                    )
                  else
                    ...visibleItems.map(_buildCheckinCard),
                  if (_isLoadingMore)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (!_hasMore && visibleItems.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 12),
                      child: Center(
                        child: Text(
                          'Historique complet charge',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryBand() {
    final approvedCount = _countFor(_CheckinFilter.approved);
    final pendingCount = _countFor(_CheckinFilter.pending);
    final photosCount = _countFor(_CheckinFilter.withPhotos);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resume de mes check-ins',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _SummaryPill(label: 'Total', value: '${_items.length}'),
                const SizedBox(width: 8),
                _SummaryPill(label: 'Valides', value: '$approvedCount'),
                const SizedBox(width: 8),
                _SummaryPill(label: 'A verifier', value: '$pendingCount'),
                const SizedBox(width: 8),
                _SummaryPill(label: 'Avec photo', value: '$photosCount'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            icon: Icons.apps_outlined,
            label: 'Tous',
            count: _countFor(_CheckinFilter.all),
            filter: _CheckinFilter.all,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            icon: Icons.verified_outlined,
            label: 'Valides',
            count: _countFor(_CheckinFilter.approved),
            filter: _CheckinFilter.approved,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            icon: Icons.pending_actions_outlined,
            label: 'A verifier',
            count: _countFor(_CheckinFilter.pending),
            filter: _CheckinFilter.pending,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            icon: Icons.photo_camera_back_outlined,
            label: 'Avec photo',
            count: _countFor(_CheckinFilter.withPhotos),
            filter: _CheckinFilter.withPhotos,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required int count,
    required _CheckinFilter filter,
  }) {
    final isSelected = _selectedFilter == filter;

    return FilterChip(
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedFilter = filter;
        });
      },
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? Colors.white : AppColors.primary,
      ),
      label: Text('$label ($count)'),
      labelStyle: AppTextStyles.caption.copyWith(
        color: isSelected ? Colors.white : AppColors.primary,
        fontWeight: FontWeight.w700,
      ),
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.surfaceAlt,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.border,
      ),
      showCheckmark: false,
    );
  }

  Widget _buildCheckinCard(CheckinHistoryItem item) {
    final preview = item.photos.isNotEmpty
        ? item.photos.first.thumbnailUrl ?? item.photos.first.imageUrl
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/checkins/${item.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: preview != null
                      ? AppNetworkImage(
                          imageUrl: preview,
                          fit: BoxFit.cover,
                          fallback: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primary,
                          size: 28,
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.siteName,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.primaryLocationLabel.isEmpty
                          ? 'Lieu non precise'
                          : item.primaryLocationLabel,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HistoryBadge(
                          icon: Icons.flag_outlined,
                          label: item.formattedStatus,
                          color: AppColors.primary,
                        ),
                        _HistoryBadge(
                          icon: item.isPendingReview
                              ? Icons.pending_actions_outlined
                              : Icons.verified_outlined,
                          label: item.formattedValidationStatus,
                          color: _validationColor(item.validationStatus),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _MetaText(
                          icon: Icons.schedule_outlined,
                          label: _formatDate(item.createdAt),
                        ),
                        _MetaText(
                          icon: Icons.route_outlined,
                          label: _formatDistance(item.distance),
                        ),
                        _MetaText(
                          icon: Icons.gps_fixed,
                          label: '${item.accuracy.toStringAsFixed(0)} m',
                        ),
                        if (item.hasPhotos)
                          _MetaText(
                            icon: Icons.photo_camera_back_outlined,
                            label:
                                '${item.photos.length} photo${item.photos.length > 1 ? 's' : ''}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String message,
    required bool showExploreAction,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: Column(
        children: [
          Icon(
            Icons.location_history_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.heading2.copyWith(color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(color: Colors.grey[600]),
          ),
          if (showExploreAction) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/sites'),
                icon: const Icon(Icons.explore_outlined),
                label: const Text('Explorer des lieux'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HistoryBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaText({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: Colors.grey[700]),
        ),
      ],
    );
  }
}
