import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/firebase/app_firebase.dart';

class GoogleSignInService {
  GoogleSignInService({GoogleSignIn? googleSignIn, FirebaseAuth? firebaseAuth})
    : _googleSignIn = googleSignIn ?? GoogleSignIn.instance,
      _firebaseAuth = firebaseAuth;

  final GoogleSignIn _googleSignIn;
  final FirebaseAuth? _firebaseAuth;
  bool _isInitialized = false;

  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;

  Future<void> _ensureInitialized() async {
    if (_isInitialized) {
      return;
    }

    if (!AppConstants.isGoogleSignInConfigured) {
      throw Exception(
        'Google Sign-In n est pas encore configure pour cette application.',
      );
    }

    await AppFirebase.initialize();
    await _googleSignIn.initialize(
      clientId: _resolveClientId(),
      serverClientId: _resolveServerClientId(),
    );

    if (!AppFirebase.isConfigured) {
      throw Exception(
        'Firebase Auth n est pas encore configure pour cette application.',
      );
    }

    _isInitialized = true;
  }

  String? _resolveClientId() {
    if (kIsWeb && AppConstants.googleWebClientId.isNotEmpty) {
      return AppConstants.googleWebClientId;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS &&
        AppConstants.googleIosClientId.isNotEmpty) {
      return AppConstants.googleIosClientId;
    }

    return null;
  }

  String? _resolveServerClientId() {
    return AppConstants.googleServerClientId.isEmpty
        ? null
        : AppConstants.googleServerClientId;
  }

  Future<String> authenticateAndGetIdToken() async {
    await _ensureInitialized();

    if (!_googleSignIn.supportsAuthenticate()) {
      throw Exception(
        'Google Sign-In n est pas disponible sur cette plateforme.',
      );
    }

    try {
      final GoogleSignInAccount account = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication authentication = account.authentication;
      final String? googleIdToken = authentication.idToken?.trim();
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleIdToken,
      );
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      final String? firebaseIdToken = await userCredential.user?.getIdToken(
        true,
      );

      if (googleIdToken != null && googleIdToken.isNotEmpty) {
        return googleIdToken;
      }

      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        throw Exception(
          'Firebase n a pas fourni de jeton d identification exploitable.',
        );
      }

      return firebaseIdToken;
    } on FirebaseAuthException catch (error) {
      throw Exception(_mapFirebaseException(error));
    } on GoogleSignInException catch (error) {
      throw Exception(_mapGoogleException(error));
    }
  }

  Future<void> signOutSilently() async {
    if (!_isInitialized) {
      return;
    }

    try {
      await _auth.signOut();
    } catch (_) {}

    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  String _mapGoogleException(GoogleSignInException error) {
    switch (error.code) {
      case GoogleSignInExceptionCode.canceled:
        return 'Connexion Google annulee.';
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'La configuration Google Sign-In est incomplete.';
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'L interface Google Sign-In est indisponible pour le moment.';
      case GoogleSignInExceptionCode.interrupted:
        return 'La connexion Google a ete interrompue. Veuillez reessayer.';
      case GoogleSignInExceptionCode.userMismatch:
        return 'Le compte Google selectionne ne correspond pas a la session en cours.';
      case GoogleSignInExceptionCode.unknownError:
        return error.description?.trim().isNotEmpty == true
            ? error.description!.trim()
            : 'Une erreur Google Sign-In est survenue.';
    }
  }

  String _mapFirebaseException(FirebaseAuthException error) {
    switch (error.code) {
      case 'account-exists-with-different-credential':
        return 'Ce compte Google est deja associe a une autre methode de connexion.';
      case 'invalid-credential':
        return 'Les informations Google recues sont invalides.';
      case 'network-request-failed':
        return 'Impossible de contacter Firebase pour le moment.';
      case 'too-many-requests':
        return 'Trop de tentatives de connexion Google. Reessayez plus tard.';
      case 'user-disabled':
        return 'Ce compte Firebase est desactive.';
      default:
        return error.message?.trim().isNotEmpty == true
            ? error.message!.trim()
            : 'Une erreur Firebase Auth est survenue.';
    }
  }
}
