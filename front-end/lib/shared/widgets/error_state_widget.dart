import 'package:flutter/material.dart';

import '../../core/constants/app_text_styles.dart';

class ErrorStateWidget extends StatelessWidget {
  final String message;
  final String? helpText;
  final VoidCallback onRetry;
  final bool isInline;

  const ErrorStateWidget.fullScreen({
    super.key,
    required this.message,
    this.helpText,
    required this.onRetry,
  }) : isInline = false;

  const ErrorStateWidget.inline({
    super.key,
    required this.message,
    this.helpText,
    required this.onRetry,
  }) : isInline = true;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final content = Column(
      mainAxisSize: isInline ? MainAxisSize.min : MainAxisSize.max,
      mainAxisAlignment: isInline
          ? MainAxisAlignment.start
          : MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, size: 52, color: colorScheme.error),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(color: colorScheme.error),
        ),
        if (helpText != null) ...[
          const SizedBox(height: 8),
          Text(
            helpText!,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Reessayer'),
        ),
      ],
    );

    if (isInline) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.error.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24),
        ),
        child: content,
      );
    }

    return Center(
      child: Padding(padding: const EdgeInsets.all(24), child: content),
    );
  }
}
