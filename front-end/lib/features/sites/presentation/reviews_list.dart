import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/api_service.dart';
import 'models/review.dart';
import 'widgets/review_card.dart';

class ReviewsList extends StatefulWidget {
  final String siteId;
  final List<Review> initialReviews;

  const ReviewsList({
    super.key,
    required this.siteId,
    this.initialReviews = const [],
  });

  @override
  State<ReviewsList> createState() => _ReviewsListState();
}

class _ReviewsListState extends State<ReviewsList> {
  final ApiService _apiService = ApiService();
  List<Review> _allReviews = [];
  List<Review> _displayedReviews = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  String? _error;

  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final reviews = await _apiService.fetchSiteReviews(widget.siteId);
      if (!mounted) return;

      _allReviews = reviews.isNotEmpty
          ? reviews
          : List<Review>.from(widget.initialReviews);
      _allReviews.sort((a, b) => b.date.compareTo(a.date));
      _loadPage(0);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
        _allReviews = List<Review>.from(widget.initialReviews);
        _displayedReviews = List<Review>.from(widget.initialReviews);
        _hasMore = false;
      });
    }
  }

  void _loadPage(int page) {
    final startIndex = page * _pageSize;
    final endIndex = (startIndex + _pageSize).clamp(0, _allReviews.length);

    if (startIndex >= _allReviews.length) {
      setState(() {
        _hasMore = false;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _displayedReviews = _allReviews.sublist(0, endIndex);
      _currentPage = page;
      _hasMore = endIndex < _allReviews.length;
      _isLoading = false;
    });
  }

  void _loadMore() {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    Future<void>.delayed(const Duration(milliseconds: 150), () {
      if (mounted) {
        _loadPage(_currentPage + 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_displayedReviews.isEmpty && _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_displayedReviews.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.rate_review_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Aucun avis pour le moment',
                style: AppTextStyles.heading2.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? 'Sois le premier a laisser un avis detaille.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(color: Colors.grey[500]),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadReviews,
                  child: const Text('Reessayer'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReviews,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _displayedReviews.length + (_hasMore ? 1 : 0) + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildSummaryCard();
          }

          final reviewIndex = index - 1;
          if (reviewIndex == _displayedReviews.length) {
            return _buildLoadMoreButton();
          }

          return ReviewCard(review: _displayedReviews[reviewIndex]);
        },
      ),
    );
  }

  Widget _buildSummaryCard() {
    final average = _allReviews.isEmpty
        ? 0.0
        : _allReviews
                  .map((review) => review.rating)
                  .reduce((value, element) => value + element) /
              _allReviews.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.star_rounded, color: Colors.amber),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_allReviews.length} avis verifie${_allReviews.length > 1 ? 's' : ''}',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Moyenne actuelle: ${average.toStringAsFixed(1)} / 5',
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'Plus recents',
              style: AppTextStyles.caption.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _loadMore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Charger plus'),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_downward, size: 18),
                  ],
                ),
              ),
      ),
    );
  }
}
