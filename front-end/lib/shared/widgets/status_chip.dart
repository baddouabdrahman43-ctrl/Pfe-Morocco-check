import 'package:flutter/material.dart';

import '../../core/constants/app_text_styles.dart';

enum StatusChipTone { defaultTone, success, warning, danger }

enum StatusChipSize { small, medium }

class StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final StatusChipTone tone;
  final StatusChipSize size;

  const StatusChip({
    super.key,
    required this.icon,
    required this.label,
    this.tone = StatusChipTone.defaultTone,
    this.size = StatusChipSize.medium,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (foreground, background) = switch (tone) {
      StatusChipTone.success => (
        const Color(0xFF0F8C5F),
        const Color(0x1F0F8C5F),
      ),
      StatusChipTone.warning => (
        const Color(0xFFB56A00),
        const Color(0x1FB56A00),
      ),
      StatusChipTone.danger => (
        colorScheme.error,
        colorScheme.error.withValues(alpha: 0.12),
      ),
      StatusChipTone.defaultTone => (
        colorScheme.primary,
        colorScheme.primary.withValues(alpha: 0.12),
      ),
    };

    final iconSize = size == StatusChipSize.small ? 14.0 : 16.0;
    final padding = size == StatusChipSize.small
        ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 8);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: foreground),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
