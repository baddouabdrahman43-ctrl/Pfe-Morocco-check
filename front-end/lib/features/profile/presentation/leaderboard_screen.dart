import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/api_service.dart';
import '../../../shared/widgets/app_circle_avatar.dart';
import '../../auth/presentation/auth_provider.dart';
import 'models/leaderboard_entry.dart';

class LeaderboardScreen extends StatefulWidget {
  final ApiService? apiService;

  const LeaderboardScreen({super.key, this.apiService});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late final ApiService _apiService;
  final List<LeaderboardEntry> _entries = <LeaderboardEntry>[];

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;
  int _page = 1;
  int _total = 0;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
    _loadLeaderboard(reset: true);
  }

  Future<void> _loadLeaderboard({required bool reset}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _error = null;
        _page = 1;
      });
    } else {
      setState(() {
        _isLoadingMore = true;
        _error = null;
      });
    }

    try {
      final result = await _apiService.fetchLeaderboard(
        page: reset ? 1 : _page + 1,
        limit: _pageSize,
      );
      if (!mounted) return;

      setState(() {
        if (reset) {
          _entries
            ..clear()
            ..addAll(result.items);
        } else {
          _entries.addAll(result.items);
        }
        _page = result.page;
        _total = result.total;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  bool get _hasMore => _entries.length < _total;

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthProvider>().user?.id.toString();
    final podiumEntries = _entries.take(3).toList();
    final rankedEntries = _entries.length > 3
        ? _entries.skip(3).toList()
        : const <LeaderboardEntry>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Classement')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: () => _loadLeaderboard(reset: true),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildHero(),
                  const SizedBox(height: 12),
                  if (podiumEntries.isNotEmpty) _buildPodium(podiumEntries),
                  const SizedBox(height: 12),
                  Text(
                    'Classement complet',
                    style: AppTextStyles.heading2.copyWith(fontSize: 22),
                  ),
                  const SizedBox(height: 12),
                  ...rankedEntries.asMap().entries.map((entry) {
                    final index = entry.key;
                    final user = entry.value;
                    return _LeaderboardTile(
                      position: index + 4,
                      entry: user,
                      isCurrentUser: currentUserId == user.id,
                      onTap: () => context.push('/users/${user.id}'),
                    );
                  }),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  if (_hasMore)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Center(
                        child: _isLoadingMore
                            ? const CircularProgressIndicator()
                            : ElevatedButton.icon(
                                onPressed: () => _loadLeaderboard(reset: false),
                                icon: const Icon(Icons.expand_more),
                                label: const Text('Voir plus'),
                              ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber, size: 26),
              SizedBox(width: 10),
              Text(
                'Classement communautaire',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Le classement est calcule a partir des points, du niveau et de l activite reelle des utilisateurs.',
            style: AppTextStyles.body.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            '$_total contributeur${_total > 1 ? 's' : ''} visibles',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> leaders) {
    final ordered = <LeaderboardEntry?>[
      leaders.length > 1 ? leaders[1] : null,
      leaders.isNotEmpty ? leaders[0] : null,
      leaders.length > 2 ? leaders[2] : null,
    ];
    final heights = <double>[92, 120, 84];
    final labels = <String>['#2', '#1', '#3'];
    final colors = <Color>[
      Color(0xFF94A3B8),
      Color(0xFFF59E0B),
      Color(0xFFB45309),
    ];

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List<Widget>.generate(3, (index) {
            final entry = ordered[index];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: entry == null
                    ? const SizedBox.shrink()
                    : InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => context.push('/users/${entry.id}'),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AppCircleAvatar(
                              radius: index == 1 ? 24 : 20,
                              backgroundColor: colors[index].withValues(
                                alpha: 0.15,
                              ),
                              imageUrl: entry.profilePicture,
                              fallback: Icon(Icons.person, color: colors[index]),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              entry.displayName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              height: heights[index],
                              decoration: BoxDecoration(
                                color: colors[index],
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(18),
                                ),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                   children: [
                                     Text(
                                       labels[index],
                                       style: const TextStyle(
                                         color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                     Text(
                                       '${entry.points} pts',
                                       style: const TextStyle(
                                         color: Colors.white,
                                         fontSize: 11,
                                         fontWeight: FontWeight.w600,
                                       ),
                                     ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Aucun classement disponible',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: 8),
            Text(
              _error ??
                  'Le leaderboard sera visible des qu il y aura assez de donnees.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadLeaderboard(reset: true),
              child: const Text('Actualiser'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final int position;
  final LeaderboardEntry entry;
  final bool isCurrentUser;
  final VoidCallback onTap;

  const _LeaderboardTile({
    required this.position,
    required this.entry,
    required this.isCurrentUser,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: isCurrentUser ? const Color(0xFFEFF6FF) : null,
      child: ListTile(
        onTap: onTap,
        leading: AppCircleAvatar(
          radius: 20,
          backgroundColor: isCurrentUser
              ? AppColors.primary.withValues(alpha: 0.16)
              : Colors.grey.shade200,
          imageUrl: entry.profilePicture,
          fallback: Text(
            '$position',
            style: TextStyle(
              color: isCurrentUser ? AppColors.primary : Colors.black87,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                entry.displayName,
                style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (isCurrentUser)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Vous',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          '${entry.rank} • Niveau ${entry.level} • ${entry.checkinsCount} check-ins • ${entry.reviewsCount} avis',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${entry.points}',
              style: AppTextStyles.heading2.copyWith(
                fontSize: 20,
                color: AppColors.primary,
              ),
            ),
            Text(
              'points',
              style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
