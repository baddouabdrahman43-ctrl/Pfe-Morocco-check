import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/presentation/auth_provider.dart';

class ProfessionalHubScreen extends StatelessWidget {
  const ProfessionalHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final isAuthenticated = authProvider.isAuthenticated;
        final canManageSites =
            user?.role == 'PROFESSIONAL' || user?.role == 'ADMIN';

        return Scaffold(
          appBar: AppBar(title: const Text('Espace professionnel')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeroSection(
                roleLabel: isAuthenticated
                    ? (user?.role ?? 'TOURIST')
                    : 'Visiteur',
                isAuthenticated: isAuthenticated,
                canManageSites: canManageSites,
              ),
              const SizedBox(height: 16),
              _OverviewStrip(
                canManageSites: canManageSites,
                isAuthenticated: isAuthenticated,
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Actions rapides',
                icon: Icons.flash_on_outlined,
                child: Column(
                  children: [
                    if (canManageSites) ...[
                      _ActionTile(
                        icon: Icons.verified_user_outlined,
                        title: 'Revendiquer un site existant',
                        subtitle:
                            'Rattacher une fiche deja publiee a votre espace professionnel.',
                        onTap: () => context.push('/professional/claims'),
                      ),
                      const SizedBox(height: 10),
                      _ActionTile(
                        icon: Icons.dashboard_customize_outlined,
                        title: 'Ouvrir mon espace professionnel',
                        subtitle:
                            'Acceder a la liste de vos etablissements et a leur suivi.',
                        onTap: () => context.push('/professional/sites'),
                      ),
                      const SizedBox(height: 10),
                      _ActionTile(
                        icon: Icons.add_business_outlined,
                        title: 'Ajouter un etablissement',
                        subtitle:
                            'Envoyer une nouvelle fiche depuis votre compte.',
                        onTap: () => context.push('/professional/sites/new'),
                      ),
                    ] else if (isAuthenticated) ...[
                      _InfoBanner(
                        icon: Icons.lock_outline,
                        color: Colors.orange,
                        message:
                            'Votre compte est connecte, mais votre role actuel ne donne pas encore acces a la gestion professionnelle.',
                      ),
                      const SizedBox(height: 12),
                      _ActionTile(
                        icon: Icons.person_outline,
                        title: 'Voir mon profil',
                        subtitle:
                            'Verifier votre role actuel et les informations rattachees a votre compte.',
                        onTap: () => context.push('/profile'),
                      ),
                    ] else ...[
                      _InfoBanner(
                        icon: Icons.login_outlined,
                        color: AppColors.primary,
                        message:
                            'Connectez-vous pour rattacher un espace professionnel a votre compte et commencer a gerer vos lieux.',
                      ),
                      const SizedBox(height: 12),
                      _ActionTile(
                        icon: Icons.login,
                        title: 'Se connecter',
                        subtitle:
                            'Acceder a votre compte avant de soumettre ou gerer un etablissement.',
                        onTap: () => context.push('/login'),
                      ),
                      const SizedBox(height: 10),
                      _ActionTile(
                        icon: Icons.person_add_alt_1_outlined,
                        title: 'Creer un compte',
                        subtitle:
                            'Demarrer un parcours professionnel a partir d un nouveau compte.',
                        onTap: () => context.push('/register'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ExpandableSectionCard(
                title: 'Ce que permet cet espace',
                icon: Icons.business_center_outlined,
                subtitle: 'Voir les usages principaux',
                child: Column(
                  children: const [
                    _FeatureTile(
                      icon: Icons.storefront_outlined,
                      title: 'Gerer ses etablissements',
                      subtitle:
                          'Suivre les lieux rattaches au compte professionnel et consulter leur statut.',
                    ),
                    _FeatureTile(
                      icon: Icons.add_business_outlined,
                      title: 'Soumettre un nouveau lieu',
                      subtitle:
                          'Creer une fiche proprietaire avec coordonnees, horaires et services declares.',
                    ),
                    _FeatureTile(
                      icon: Icons.timeline_outlined,
                      title: 'Suivre validation et activite',
                      subtitle:
                          'Voir moderation, fraicheur des donnees, vues, avis et verification terrain.',
                    ),
                    _FeatureTile(
                      icon: Icons.edit_note_outlined,
                      title: 'Mettre a jour rapidement',
                      subtitle:
                          'Corriger les informations publiques quand un changement intervient sur le terrain.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _ExpandableSectionCard(
                title: 'Parcours recommande',
                icon: Icons.route_outlined,
                subtitle: 'Voir les etapes conseillees',
                child: Column(
                  children: const [
                    _StepTile(
                      number: '1',
                      title: 'Creer ou connecter un compte',
                      description:
                          'Le compte permet de rattacher l activite terrain et les etablissements a un proprietaire.',
                    ),
                    _StepTile(
                      number: '2',
                      title: 'Soumettre une fiche professionnelle',
                      description:
                          'Le lieu peut etre complete avec categorie, adresse, services et horaires.',
                    ),
                    _StepTile(
                      number: '3',
                      title: 'Suivre moderation et corrections',
                      description:
                          'La fiche evolue ensuite avec les validations et les retours remontes dans l application.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HeroSection extends StatelessWidget {
  final String roleLabel;
  final bool isAuthenticated;
  final bool canManageSites;

  const _HeroSection({
    required this.roleLabel,
    required this.isAuthenticated,
    required this.canManageSites,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = canManageSites
        ? 'Votre compte peut deja piloter des etablissements et suivre leur validation.'
        : isAuthenticated
        ? 'Votre compte est connecte, mais l acces a la gestion pro reste reserve aux roles autorises.'
        : 'Cet espace montre comment MoroccoCheck aide les proprietaires a garder une fiche claire et a jour.';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF115E59), Color(0xFF134E4A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroPill(
                icon: Icons.apartment_outlined,
                label: 'Lieux professionnels',
              ),
              _HeroPill(icon: Icons.badge_outlined, label: 'Role: $roleLabel'),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Piloter ses etablissements depuis MoroccoCheck',
            style: AppTextStyles.heading1.copyWith(
              color: Colors.white,
              fontSize: 26,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Creation de fiches, suivi de moderation, corrections rapides et lecture des signaux utiles depuis un seul espace.',
            style: AppTextStyles.body.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              statusText,
              style: AppTextStyles.body.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          const SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _HeroBusinessCard(
                  title: 'Visibilite',
                  subtitle: 'soigner la fiche publique',
                ),
                SizedBox(width: 10),
                _HeroBusinessCard(
                  title: 'Confiance',
                  subtitle: 'reponse et fraicheur',
                ),
                SizedBox(width: 10),
                _HeroBusinessCard(
                  title: 'Pilotage',
                  subtitle: 'corriger et suivre vite',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroBusinessCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _HeroBusinessCard({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 156,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.body.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewStrip extends StatelessWidget {
  final bool canManageSites;
  final bool isAuthenticated;

  const _OverviewStrip({
    required this.canManageSites,
    required this.isAuthenticated,
  });

  @override
  Widget build(BuildContext context) {
    final items = canManageSites
        ? const [
            _OverviewItem(
              icon: Icons.dashboard_customize_outlined,
              title: 'Suivi pro',
              subtitle: 'Vos lieux et leur statut',
            ),
            _OverviewItem(
              icon: Icons.rate_review_outlined,
              title: 'Reactivite',
              subtitle: 'Repondre et corriger vite',
            ),
            _OverviewItem(
              icon: Icons.verified_user_outlined,
              title: 'Validation',
              subtitle: 'Moderation et qualite',
            ),
          ]
        : isAuthenticated
        ? const [
            _OverviewItem(
              icon: Icons.lock_outline,
              title: 'Acces limite',
              subtitle: 'Role a faire evoluer',
            ),
            _OverviewItem(
              icon: Icons.person_outline,
              title: 'Compte actif',
              subtitle: 'Profil deja connecte',
            ),
            _OverviewItem(
              icon: Icons.support_agent_outlined,
              title: 'Parcours pro',
              subtitle: 'Pret a etre active',
            ),
          ]
        : const [
            _OverviewItem(
              icon: Icons.login_outlined,
              title: 'Connexion',
              subtitle: 'Demarrer le parcours',
            ),
            _OverviewItem(
              icon: Icons.add_business_outlined,
              title: 'Soumission',
              subtitle: 'Creer ou revendiquer',
            ),
            _OverviewItem(
              icon: Icons.public_outlined,
              title: 'Visibilite',
              subtitle: 'Ameliorer la fiche',
            ),
          ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < items.length; index++) ...[
            _OverviewCard(item: items[index]),
            if (index < items.length - 1) const SizedBox(width: 10),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.heading2.copyWith(fontSize: 20),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _OverviewItem {
  final IconData icon;
  final String title;
  final String subtitle;

  const _OverviewItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class _OverviewCard extends StatelessWidget {
  final _OverviewItem item;

  const _OverviewCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 156,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            item.subtitle,
            style: AppTextStyles.caption.copyWith(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }
}

class _ExpandableSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _ExpandableSectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          title: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.heading2.copyWith(fontSize: 20),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(left: 34),
            child: Text(
              subtitle,
              style: AppTextStyles.caption.copyWith(color: Colors.grey[700]),
            ),
          ),
          children: [child],
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final String number;
  final String title;
  final String description;

  const _StepTile({
    required this.number,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              number,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          color: AppColors.surfaceAlt,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;

  const _InfoBanner({
    required this.icon,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.body.copyWith(color: Colors.grey[900]),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
