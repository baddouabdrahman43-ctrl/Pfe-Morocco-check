import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/api_service.dart';
import '../../../shared/widgets/app_network_image.dart';
import '../../../shared/widgets/confirmation_dialog.dart';
import '../../auth/presentation/auth_provider.dart';
import 'models/my_review_item.dart';

enum _ReviewFilter { all, published, pending }
enum _ReviewCardAction { edit, delete }

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  final ApiService _apiService = ApiService();
  final ScrollController _scrollController = ScrollController();
  final List<MyReviewItem> _items = <MyReviewItem>[];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _isMutating = false;
  String? _error;
  int _currentPage = 1;
  _ReviewFilter _selectedFilter = _ReviewFilter.all;

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

  String? get _selectedApiStatus {
    switch (_selectedFilter) {
      case _ReviewFilter.all:
        return null;
      case _ReviewFilter.published:
        return 'PUBLISHED';
      case _ReviewFilter.pending:
        return 'PENDING';
    }
  }

  Future<void> _loadInitial() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id;

    if (userId == null) {
      setState(() {
        _error = 'Session introuvable.';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
      _hasMore = true;
    });

    try {
      final result = await _apiService.fetchMyReviews(
        userId: userId,
        page: 1,
        limit: _pageSize,
        status: _selectedApiStatus,
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
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.id;
    if (userId == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final result = await _apiService.fetchMyReviews(
        userId: userId,
        page: nextPage,
        limit: _pageSize,
        status: _selectedApiStatus,
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

  int _countFor(_ReviewFilter filter) {
    switch (filter) {
      case _ReviewFilter.all:
        return _items.length;
      case _ReviewFilter.published:
        return _items.where((item) => item.isPublished).length;
      case _ReviewFilter.pending:
        return _items.where((item) => item.isPending).length;
    }
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    return '$day/$month/$year';
  }

  Color _moderationColor(String status) {
    switch (status) {
      case 'APPROVED':
        return AppColors.secondary;
      case 'PENDING':
        return Colors.orange;
      case 'REJECTED':
      case 'SPAM':
        return AppColors.error;
      case 'FLAGGED':
        return Colors.deepOrange;
      default:
        return AppColors.primary;
    }
  }

  Future<void> _selectFilter(_ReviewFilter filter) async {
    if (_selectedFilter == filter) return;
    setState(() {
      _selectedFilter = filter;
    });
    await _loadInitial();
  }

  Future<void> _openEditDialog(MyReviewItem review) async {
    final commentController = TextEditingController(text: review.content);
    var selectedRating = review.rating;
    String? submitError;

    final updated = await showDialog<MyReviewItem>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Modifier mon avis'),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.siteName,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      children: List<Widget>.generate(5, (index) {
                        final starValue = index + 1;
                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              selectedRating = starValue;
                            });
                          },
                          child: Icon(
                            starValue <= selectedRating
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                            size: 30,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: commentController,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        hintText: 'Mettez a jour votre retour d experience',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (submitError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        submitError!,
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: _isMutating
                      ? null
                      : () async {
                          final content = commentController.text.trim();
                          if (selectedRating <= 0) {
                            setDialogState(() {
                              submitError = 'Veuillez choisir une note.';
                            });
                            return;
                          }
                          if (content.length < 20) {
                            setDialogState(() {
                              submitError =
                                  'Le commentaire doit contenir au moins 20 caracteres.';
                            });
                            return;
                          }

                          setState(() {
                            _isMutating = true;
                          });

                          try {
                            final result = await _apiService.updateMyReview(
                              reviewId: review.id,
                              rating: selectedRating,
                              content: content,
                              title: review.title,
                            );
                            if (!mounted || !dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop(result);
                          } catch (error) {
                            setDialogState(() {
                              submitError = _mapMutationError(error);
                            });
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isMutating = false;
                              });
                            }
                          }
                        },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );

    commentController.dispose();

    if (updated == null || !mounted) return;

    final index = _items.indexWhere((item) => item.id == updated.id);
    if (index == -1) return;

    setState(() {
      _items[index] = updated;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Avis mis a jour avec succes.'),
        backgroundColor: AppColors.secondary,
      ),
    );
  }

  Future<void> _confirmDelete(MyReviewItem review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: 'Supprimer cet avis ?',
        message:
            'Votre avis sur ${review.siteName} sera retire de votre historique visible.',
        confirmLabel: 'Supprimer',
        cancelLabel: 'Annuler',
        tone: ConfirmationDialogTone.danger,
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isMutating = true;
    });

    try {
      await _apiService.deleteMyReview(review.id);
      if (!mounted) return;

      setState(() {
        _items.removeWhere((item) => item.id == review.id);
      });
      await context.read<AuthProvider>().refreshUser();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avis supprime avec succes.'),
          backgroundColor: AppColors.secondary,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_mapMutationError(error)),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isMutating = false;
        });
      }
    }
  }

  String _mapMutationError(Object error) {
    if (error is ApiException) {
      if (error.isUnauthorized) {
        return 'Votre session a expire. Reconnectez-vous.';
      }
      if (error.isForbidden) {
        return 'Vous ne pouvez pas modifier cet avis.';
      }
      if (error.statusCode == 400) {
        return 'Le contenu de l avis est invalide.';
      }
      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'Impossible de contacter le serveur.';
      }
      if (error.message.isNotEmpty) {
        return error.message;
      }
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes avis')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInitial,
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHeroCard(),
                  const SizedBox(height: 16),
                  _buildFilterBar(),
                  const SizedBox(height: 16),
                  if (_items.isEmpty)
                    _buildEmptyState(
                      title: 'Aucun avis pour le moment',
                      message:
                          _error ??
                          'Vos prochains avis apparaitront ici avec leur statut de moderation.',
                    )
                  else
                    ..._items.map(_buildReviewCard),
                  if (_isLoadingMore)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (!_hasMore && _items.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 12),
                      child: Center(
                        child: Text(
                          'Tous les avis ont ete charges',
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

  Widget _buildHeroCard() {
    final publishedCount = _countFor(_ReviewFilter.published);
    final pendingCount = _countFor(_ReviewFilter.pending);
    final photosCount = _items.where((item) => item.hasPhotos).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF115E59), Color(0xFF134E4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Historique de mes avis',
            style: AppTextStyles.heading2.copyWith(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Suivez la moderation, revenez sur un commentaire et gardez la main sur ce que vous avez publie.',
            style: AppTextStyles.body.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SummaryPill(label: 'Total', value: '${_items.length}'),
              _SummaryPill(label: 'Publies', value: '$publishedCount'),
              _SummaryPill(label: 'En attente', value: '$pendingCount'),
              _SummaryPill(label: 'Avec photo', value: '$photosCount'),
            ],
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
            count: _countFor(_ReviewFilter.all),
            filter: _ReviewFilter.all,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            icon: Icons.verified_outlined,
            label: 'Publies',
            count: _countFor(_ReviewFilter.published),
            filter: _ReviewFilter.published,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            icon: Icons.pending_actions_outlined,
            label: 'En attente',
            count: _countFor(_ReviewFilter.pending),
            filter: _ReviewFilter.pending,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required IconData icon,
    required String label,
    required int count,
    required _ReviewFilter filter,
  }) {
    final isSelected = _selectedFilter == filter;

    return FilterChip(
      selected: isSelected,
      onSelected: (_) => _selectFilter(filter),
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

  Widget _buildReviewCard(MyReviewItem review) {
    final preview = review.photos.isNotEmpty
        ? review.photos.first.thumbnailUrl ?? review.photos.first.imageUrl
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 60,
                  height: 60,
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
                            Icons.rate_review_outlined,
                            color: AppColors.primary,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.siteName,
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(review.createdAt),
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (index) {
                    return Icon(
                      index < review.rating ? Icons.star : Icons.star_border,
                      size: 16,
                      color: Colors.amber,
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusBadge(
                  icon: review.isPublished
                      ? Icons.verified_outlined
                      : Icons.pending_actions_outlined,
                  label: review.formattedStatus,
                  color: review.isPublished
                      ? AppColors.secondary
                      : Colors.orange,
                ),
                _StatusBadge(
                  icon: Icons.shield_outlined,
                  label: review.formattedModerationStatus,
                  color: _moderationColor(review.moderationStatus),
                ),
                if (review.helpfulCount > 0)
                  _StatusBadge(
                    icon: Icons.thumb_up_alt_outlined,
                    label:
                        '${review.helpfulCount} utile${review.helpfulCount > 1 ? 's' : ''}',
                    color: AppColors.primary,
                  ),
                if (review.hasPhotos)
                  _StatusBadge(
                    icon: Icons.photo_camera_back_outlined,
                    label:
                        '${review.photos.length} photo${review.photos.length > 1 ? 's' : ''}',
                    color: Colors.purple.shade700,
                  ),
              ],
            ),
            if ((review.title ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                review.title!.trim(),
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              review.content,
              style: AppTextStyles.body.copyWith(color: Colors.grey[800]),
            ),
            if (review.hasOwnerResponse &&
                (review.ownerResponse ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 12),
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
                      'Reponse professionnelle',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      review.ownerResponse!.trim(),
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isMutating
                        ? null
                        : () => context.push('/sites/${review.siteId}'),
                    icon: const Icon(Icons.place_outlined),
                    label: const Text('Voir le site'),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<_ReviewCardAction>(
                  enabled: !_isMutating,
                  tooltip: 'Actions',
                  onSelected: (action) {
                    switch (action) {
                      case _ReviewCardAction.edit:
                        _openEditDialog(review);
                      case _ReviewCardAction.delete:
                        _confirmDelete(review);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _ReviewCardAction.edit,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Modifier'),
                      ),
                    ),
                    PopupMenuItem(
                      value: _ReviewCardAction.delete,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          Icons.delete_outline,
                          color: AppColors.error,
                        ),
                        title: Text(
                          'Supprimer',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.more_horiz),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required String title,
    required String message,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 56),
      child: Column(
        children: [
          Icon(
            Icons.rate_review_outlined,
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
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.go('/sites'),
              icon: const Icon(Icons.place_outlined),
              label: const Text('Voir les sites'),
            ),
          ),
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
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
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

class _StatusBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusBadge({
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
