import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/api_service.dart';
import '../../../shared/models/user.dart';
import '../../../shared/widgets/app_circle_avatar.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../sites/presentation/sites_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _badges = [];
  Map<String, dynamic>? _contributorRequestStatus;
  bool _isExtrasLoading = false;
  bool _isContributorRequestSubmitting = false;
  String? _extrasError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _refreshProfile(context.read<AuthProvider>());
    });
  }

  Future<void> _refreshProfile(AuthProvider authProvider) async {
    setState(() {
      _isExtrasLoading = true;
      _extrasError = null;
    });

    try {
      await authProvider.refreshUser();
      final stats = await _apiService.fetchMyStats();
      final badges = await _apiService.fetchMyBadges();
      final contributorRequestStatus = await _apiService
          .fetchContributorRequestStatus();

      if (!mounted) return;
      setState(() {
        _stats = stats;
        _badges = badges;
        _contributorRequestStatus = contributorRequestStatus;
        _isExtrasLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isExtrasLoading = false;
        _extrasError = e.toString();
      });
    }
  }

  int _readInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? fallback;
  }

  String _readString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = '$value'.trim();
    return text.isEmpty ? fallback : text;
  }

  Map<String, dynamic>? _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, data) => MapEntry(key.toString(), data));
    }
    return null;
  }

  List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value
          .map((item) => '$item')
          .where((item) => item.trim().isNotEmpty)
          .toList();
    }
    return <String>[];
  }

  Future<void> _openContributorRequestDialog(AuthProvider authProvider) async {
    final controller = TextEditingController();
    String? submitError;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Demander le role CONTRIBUTOR'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Explique en quelques lignes pourquoi tu souhaites contribuer sur le terrain.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText:
                          'Exemple: je visite regulierement des sites touristiques et je souhaite signaler les changements sur le terrain...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (submitError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      submitError!,
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                onPressed: () async {
                  final motivation = controller.text.trim();
                  if (motivation.length < 20) {
                    setDialogState(() {
                      submitError =
                          'La motivation doit contenir au moins 20 caracteres.';
                    });
                    return;
                  }

                  try {
                    setState(() => _isContributorRequestSubmitting = true);
                    await _apiService.submitContributorRequest(
                      motivation: motivation,
                    );
                    if (!mounted || !dialogContext.mounted) return;
                    Navigator.of(dialogContext).pop(true);
                  } catch (error) {
                    setDialogState(() {
                      submitError = error.toString().replaceFirst(
                        'Exception: ',
                        '',
                      );
                    });
                  } finally {
                    if (mounted) {
                      setState(() => _isContributorRequestSubmitting = false);
                    }
                  }
                },
                child: const Text('Envoyer'),
              ),
            ],
          ),
        );
      },
    );

    controller.dispose();

    if (submitted == true) {
      await _refreshProfile(authProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demande envoyee. Elle sera examinee par un admin.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        if (authProvider.isLoading && user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (user == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Profil')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.person_off_outlined,
                      size: 56,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Aucun profil charge',
                      style: AppTextStyles.heading2,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      authProvider.error ??
                          'Connecte-toi pour recuperer tes informations.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Profil')),
          body: _buildContent(context, authProvider, user),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    AuthProvider authProvider,
    User user,
  ) {
    final sitesProvider = context.watch<SitesProvider>();
    final points = _asMap(_stats?['points']);
    final activity = _asMap(_stats?['activity']);
    final achievements = _asMap(_stats?['achievements']);
    final recentActivity =
        (_stats?['recent_activity'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<Map>()
            .map(
              (item) =>
                  item.map((key, value) => MapEntry(key.toString(), value)),
            )
            .toList();
    final activityItems = recentActivity.isNotEmpty
        ? recentActivity
        : sitesProvider.localRecentActivity
              .take(5)
              .map(
                (entry) => <String, dynamic>{
                  'type': entry.type == SiteActivityType.checkin
                      ? 'CHECKIN'
                      : 'REVIEW',
                  'site_id': entry.siteId,
                  'site_name': entry.siteName,
                  'points_earned': entry.type == SiteActivityType.checkin
                      ? 10
                      : 5,
                  'city': entry.city,
                },
              )
              .toList();

    final totalPoints = _readInt(points?['total'], fallback: user.points);
    final level = _readInt(points?['level'], fallback: user.level);
    final nextLevelAt = _readInt(
      points?['next_level_at'],
      fallback: level * 100,
    );
    final progress = (_readInt(points?['progress_to_next_level']) / 100)
        .clamp(0, 1)
        .toDouble();
    final rank = _readString(points?['rank'], fallback: user.rank ?? 'BRONZE');
    final contributorRequest = _asMap(_contributorRequestStatus?['request']);
    final contributorEligibility = _asMap(
      _contributorRequestStatus?['eligibility'],
    );
    final contributorMissingFields = _asStringList(
      contributorEligibility?['missing_fields'],
    );
    final contributorRequestStatus = _readString(
      contributorRequest?['status'],
      fallback: 'NONE',
    );
    final canRequestContributor =
        contributorEligibility?['can_request'] == true;
    final showContributorCard =
        (user.role ?? 'TOURIST') == 'TOURIST' || contributorRequest != null;
    final canManageSites = user.role == 'PROFESSIONAL' || user.role == 'ADMIN';

        return RefreshIndicator(
      onRefresh: () => _refreshProfile(authProvider),
      child: ListView(
        children: [
          _buildHeader(user, rank),
          _buildOverviewStrip(
            totalPoints: totalPoints,
            level: level,
            checkinsCount: _readInt(
              activity?['checkins_count'],
              fallback: user.checkinsCount,
            ),
            reviewsCount: _readInt(
              activity?['reviews_count'],
              fallback: user.reviewsCount,
            ),
          ),
          _sectionTitle('Mon compte'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildPrimaryActions(
              context: context,
              user: user,
              canManageSites: canManageSites,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: [
                  _infoTile('Rang', rank),
                  _infoTile('Role', user.role ?? 'TOURIST'),
                  _infoTile('Statut', user.status ?? 'ACTIVE'),
                  if ((user.phoneNumber ?? '').isNotEmpty)
                    _infoTile('Telephone', user.phoneNumber!),
                  if ((user.nationality ?? '').isNotEmpty)
                    _infoTile('Nationalite', user.nationality!),
                ],
              ),
            ),
          ),
          if ((user.bio ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(user.bio!, style: AppTextStyles.body),
                ),
              ),
            ),
          if (showContributorCard)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Passage vers CONTRIBUTOR',
                        style: AppTextStyles.bodyStrong,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        contributorRequest != null
                            ? 'Statut actuel: $contributorRequestStatus'
                            : 'Demande le role contributor pour debloquer les check-ins terrain.',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.grey[700],
                        ),
                      ),
                      if (contributorMissingFields.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'A completer: ${contributorMissingFields.join(', ')}',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed:
                            contributorRequest == null &&
                                canRequestContributor &&
                                !_isContributorRequestSubmitting
                            ? () => _openContributorRequestDialog(authProvider)
                            : null,
                        child: _isContributorRequestSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                contributorRequest == null
                                    ? 'Demander le role CONTRIBUTOR'
                                    : 'Demande en cours',
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          _sectionTitle('Progression'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _statCard('$totalPoints', 'pts'),
                _statCard(
                  '${_readInt(activity?['checkins_count'], fallback: user.checkinsCount)}',
                  'check-ins',
                ),
                _statCard(
                  '${_readInt(activity?['reviews_count'], fallback: user.reviewsCount)}',
                  'avis',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Niveau $level', style: AppTextStyles.bodyStrong),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: progress, minHeight: 8),
                    const SizedBox(height: 8),
                    Text(
                      '$totalPoints / $nextLevelAt points',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Badges',
                            style: AppTextStyles.bodyStrong,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/profile/badges'),
                          child: const Text('Voir tout'),
                        ),
                      ],
                    ),
                    Text(
                      '${_readInt(achievements?['badges_earned'], fallback: user.badgeCount)} / ${_readInt(achievements?['total_badges'])} obtenus',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_badges.isEmpty)
                      Text(
                        _isExtrasLoading
                            ? 'Chargement des badges...'
                            : 'Aucun badge obtenu pour le moment.',
                        style: AppTextStyles.body.copyWith(
                          color: Colors.grey[600],
                        ),
                      )
                    else
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _badges.take(3).map((badge) {
                          return SizedBox(
                            width: 92,
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: AppColors.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  child: const Icon(
                                    Icons.workspace_premium,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _readString(badge['name'], fallback: 'Badge'),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.caption.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ),
          ),
          _sectionTitle(
            'Activite',
            action: TextButton(
              onPressed: () => context.push('/profile/checkins'),
              child: const Text('Voir tout'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              margin: EdgeInsets.zero,
              child: Column(
                children: activityItems.take(3).map((item) {
                  final type = _readString(item['type'], fallback: 'ACTION');
                  final siteId = _readString(item['site_id']);
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          (type == 'CHECKIN' ? Colors.green : Colors.blue)
                              .withValues(alpha: 0.18),
                      child: Icon(
                        type == 'CHECKIN'
                            ? Icons.location_on
                            : Icons.rate_review,
                        size: 18,
                        color: type == 'CHECKIN' ? Colors.green : Colors.blue,
                      ),
                    ),
                    title: Text(
                      _readString(item['site_name'], fallback: 'Site'),
                    ),
                    subtitle: Text(
                      [
                        type == 'CHECKIN' ? 'Check-in' : 'Avis',
                        if (_readString(item['city']).isNotEmpty)
                          _readString(item['city']),
                        '+${_readInt(item['points_earned'])} pts',
                      ].join(' - '),
                    ),
                    trailing: siteId.isNotEmpty
                        ? const Icon(Icons.chevron_right)
                        : null,
                    onTap: siteId.isEmpty
                        ? null
                        : () => context.push('/sites/$siteId'),
                  );
                }).toList(),
              ),
            ),
          ),
          _sectionTitle('Acces rapides'),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _linkTile(
                  icon: Icons.location_history_outlined,
                  title: 'Mes check-ins',
                  onTap: () => context.push('/profile/checkins'),
                ),
                _linkTile(
                  icon: Icons.rate_review_outlined,
                  title: 'Mes avis',
                  onTap: () => context.push('/profile/reviews'),
                ),
                _linkTile(
                  icon: Icons.leaderboard,
                  title: 'Classement',
                  onTap: () => context.push('/leaderboard'),
                ),
                _linkTile(
                  icon: Icons.workspace_premium_outlined,
                  title: 'Voir tous les badges',
                  onTap: () => context.push('/profile/badges'),
                ),
                _linkTile(
                  icon: Icons.settings_outlined,
                  title: 'Reglages',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                _linkTile(
                  icon: Icons.business_center_outlined,
                  title: 'Espace professionnel',
                  subtitle: canManageSites
                      ? 'Acceder au hub et gerer vos etablissements'
                      : 'Decouvrir l espace dedie aux proprietaires et gestionnaires',
                  onTap: () => context.push('/professional'),
                ),
                if (canManageSites)
                  _linkTile(
                    icon: Icons.storefront_outlined,
                    title: 'Mes etablissements',
                    onTap: () => context.push('/professional/sites'),
                  ),
                if (canManageSites)
                  _linkTile(
                    icon: Icons.add_business_outlined,
                    title: 'Ajouter un lieu',
                    onTap: () => context.push('/professional/sites/new'),
                  ),
                _linkTile(
                  icon: Icons.refresh,
                  title: 'Rafraichir le profil',
                  onTap: _isExtrasLoading
                      ? null
                      : () => _refreshProfile(authProvider),
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.error),
                  title: const Text(
                    'Se deconnecter',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () async {
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirmation'),
                        content: const Text('Voulez-vous vous deconnecter ?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Annuler'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Deconnexion'),
                          ),
                        ],
                      ),
                    );
                    if (shouldLogout == true && context.mounted) {
                      await context.read<AuthProvider>().logout(
                        context: context,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          if (authProvider.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                authProvider.error!,
                style: AppTextStyles.caption.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ),
          if (_extrasError != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                _extrasError!,
                style: AppTextStyles.caption.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(User user, String rank) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDeep,
            AppColors.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppCircleAvatar(
                radius: 38,
                backgroundColor: Colors.white24,
                imageUrl: user.profilePicture,
                fallback: const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: AppTextStyles.heading2.copyWith(
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.84),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _headerPill(label: rank, backgroundColor: Colors.white),
              _headerPill(
                label: user.role ?? 'TOURIST',
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                textColor: Colors.white,
              ),
              _headerPill(
                label: user.status ?? 'ACTIVE',
                backgroundColor: Colors.white.withValues(alpha: 0.18),
                textColor: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, {Widget? action}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.heading2.copyWith(fontSize: 18),
            ),
          ),
          ...?action == null ? null : <Widget>[action],
        ],
      ),
    );
  }

  Widget _buildOverviewStrip({
    required int totalPoints,
    required int level,
    required int checkinsCount,
    required int reviewsCount,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _overviewMetric(
                title: 'Points',
                value: '$totalPoints',
                icon: Icons.stars_rounded,
              ),
              _overviewMetric(
                title: 'Niveau',
                value: '$level',
                icon: Icons.trending_up_rounded,
              ),
              _overviewMetric(
                title: 'Check-ins',
                value: '$checkinsCount',
                icon: Icons.location_on_outlined,
              ),
              _overviewMetric(
                title: 'Avis',
                value: '$reviewsCount',
                icon: Icons.rate_review_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _overviewMetric({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return SizedBox(
      width: 150,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: AppColors.primaryDeep),
            const SizedBox(height: 10),
            Text(
              value,
              style: AppTextStyles.heading2.copyWith(
                fontSize: 22,
                color: AppColors.primaryDeep,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: AppTextStyles.caption.copyWith(color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryActions({
    required BuildContext context,
    required User user,
    required bool canManageSites,
  }) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _actionCard(
          icon: Icons.edit_outlined,
          title: 'Modifier mon profil',
          subtitle: 'Mettre a jour vos informations',
          onTap: () => context.push('/profile/edit', extra: user),
        ),
        _actionCard(
          icon: Icons.lock_outline,
          title: 'Securite',
          subtitle: 'Changer le mot de passe',
          onTap: () => context.push('/profile/password'),
        ),
        _actionCard(
          icon: Icons.business_center_outlined,
          title: 'Espace professionnel',
          subtitle: canManageSites
              ? 'Acceder a vos etablissements'
              : 'Decouvrir les outils de gestion',
          onTap: () => context.push('/professional'),
        ),
      ],
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 170,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.primaryDeep, size: 20),
              ),
              const SizedBox(height: 12),
              Text(title, style: AppTextStyles.bodyStrong),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.caption.copyWith(color: Colors.grey[700]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerPill({
    required String label,
    required Color backgroundColor,
    Color textColor = AppColors.primaryDeep,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _statCard(String value, String label) {
    return Expanded(
      child: Card(
        margin: const EdgeInsets.all(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(
                value,
                style: AppTextStyles.heading2.copyWith(
                  color: AppColors.primary,
                  fontSize: 22,
                ),
              ),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return ListTile(
      title: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: Colors.grey[600]),
      ),
      trailing: Text(
        value,
        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _linkTile({
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
