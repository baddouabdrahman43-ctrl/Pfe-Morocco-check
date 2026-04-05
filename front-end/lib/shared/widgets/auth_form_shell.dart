import 'package:flutter/material.dart';

import '../../core/constants/app_text_styles.dart';
import '../../core/theme/spacing_tokens.dart';

class AuthFormShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;

  const AuthFormShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: SpacingTokens.allXl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: AppTextStyles.heading1.copyWith(
                color: colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SpacingTokens.s),
            Text(
              subtitle,
              style: AppTextStyles.body.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: SpacingTokens.xl),
            child,
            if (footer != null) ...[
              const SizedBox(height: SpacingTokens.xl),
              footer!,
            ],
          ],
        ),
      ),
    );
  }
}

class AuthFormSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const AuthFormSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.bodyStrong.copyWith(
            color: colorScheme.onSurface,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: SpacingTokens.m),
        ...children,
      ],
    );
  }
}
