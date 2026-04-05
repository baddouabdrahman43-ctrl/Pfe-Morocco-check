import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class BiometricAuthService {
  BiometricAuthService._();

  static final BiometricAuthService instance = BiometricAuthService._();

  final LocalAuthentication _localAuthentication = LocalAuthentication();

  Future<bool> isAvailable() async {
    try {
      final canCheck = await _localAuthentication.canCheckBiometrics;
      final deviceSupported = await _localAuthentication.isDeviceSupported();
      return canCheck || deviceSupported;
    } catch (error) {
      debugPrint('Biometric availability error: $error');
      return false;
    }
  }

  Future<bool> authenticateForUnlock() async {
    try {
      return await _localAuthentication.authenticate(
        localizedReason:
            'Confirmez votre identite pour retrouver votre session MoroccoCheck.',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (error) {
      debugPrint('Biometric auth error: $error');
      return false;
    }
  }
}
