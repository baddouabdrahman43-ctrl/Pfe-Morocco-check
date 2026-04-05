import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/theme/spacing_tokens.dart';

/// Bouton « Continuer avec Google » (style Material, cohérent sur login / inscription / welcome).
class GoogleContinueButton extends StatelessWidget {
  const GoogleContinueButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final Future<void> Function() onPressed;
  final bool isLoading;

  Future<void> _handleTap(BuildContext context) async {
    if (isLoading) return;
    if (!AppConstants.isGoogleSignInConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Configurez Firebase et GOOGLE_SERVER_CLIENT_ID (dart-define) '
            'comme indique dans le README front-end.',
          ),
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }
    await onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final configured = AppConstants.isGoogleSignInConfigured;

    return OutlinedButton(
      onPressed: isLoading ? null : () => _handleTap(context),
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
        side: BorderSide(
          color: configured
              ? colorScheme.outline
              : colorScheme.outline.withValues(alpha: 0.5),
        ),
        padding: const EdgeInsets.symmetric(
          vertical: SpacingTokens.m,
          horizontal: SpacingTokens.l,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _googleBadge(configured && !isLoading),
          const SizedBox(width: SpacingTokens.m),
          if (isLoading)
            SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.primary,
              ),
            )
          else
            Text(
              'Continuer avec Google',
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }

  Widget _googleBadge(bool enabled) {
    final a = enabled ? 1.0 : 0.45;
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: a),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF4285F4).withValues(alpha: a)),
      ),
      alignment: Alignment.center,
      child: Text(
        'G',
        style: TextStyle(
          color: const Color(0xFF4285F4).withValues(alpha: a),
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
    );
  }
}
