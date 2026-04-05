import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ProfessionalStatusInfo {
  final String label;
  final String description;
  final Color color;
  final IconData icon;

  const ProfessionalStatusInfo({
    required this.label,
    required this.description,
    required this.color,
    required this.icon,
  });
}

ProfessionalStatusInfo publicationStatusInfo(String status) {
  switch (status) {
    case 'PUBLISHED':
      return const ProfessionalStatusInfo(
        label: 'Publie',
        description: 'Visible par les visiteurs dans l application.',
        color: AppColors.secondary,
        icon: Icons.public,
      );
    case 'PENDING_REVIEW':
      return const ProfessionalStatusInfo(
        label: 'En attente de revue',
        description: 'Le lieu attend encore une validation de l equipe.',
        color: Colors.orange,
        icon: Icons.hourglass_top_rounded,
      );
    case 'ARCHIVED':
      return const ProfessionalStatusInfo(
        label: 'Archive',
        description: 'Le lieu n est plus diffuse dans le catalogue public.',
        color: Colors.grey,
        icon: Icons.archive_outlined,
      );
    default:
      return const ProfessionalStatusInfo(
        label: 'Statut inconnu',
        description: 'Le backend a renvoye un statut non reconnu.',
        color: AppColors.primary,
        icon: Icons.info_outline,
      );
  }
}

ProfessionalStatusInfo verificationStatusInfo(String status) {
  switch (status) {
    case 'VERIFIED':
      return const ProfessionalStatusInfo(
        label: 'Validation confirmee',
        description: 'Les informations du lieu ont ete validees.',
        color: AppColors.secondary,
        icon: Icons.verified_rounded,
      );
    case 'PENDING':
      return const ProfessionalStatusInfo(
        label: 'Validation en attente',
        description: 'L equipe n a pas encore tranche sur cette fiche.',
        color: Colors.orange,
        icon: Icons.schedule_rounded,
      );
    case 'REJECTED':
      return const ProfessionalStatusInfo(
        label: 'Validation refusee',
        description:
            'La fiche doit etre ajustee avant une nouvelle soumission.',
        color: AppColors.error,
        icon: Icons.gpp_bad_outlined,
      );
    default:
      return const ProfessionalStatusInfo(
        label: 'Validation inconnue',
        description: 'Le backend a renvoye un statut non reconnu.',
        color: AppColors.primary,
        icon: Icons.help_outline,
      );
  }
}
