import '../domain/auth_repository.dart';
import 'auth_remote_datasource.dart';
import 'auth_local_datasource.dart';
import 'google_sign_in_service.dart';
import '../../../core/network/api_service.dart';
import '../../../shared/models/user.dart';
import '../../../core/storage/storage_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _remoteDatasource;
  final AuthLocalDatasource _localDatasource;
  final StorageService _storageService;
  final GoogleSignInService _googleSignInService;

  AuthRepositoryImpl({
    AuthRemoteDatasource? remoteDatasource,
    AuthLocalDatasource? localDatasource,
    StorageService? storageService,
    GoogleSignInService? googleSignInService,
  }) : _remoteDatasource = remoteDatasource ?? AuthRemoteDatasource(),
       _localDatasource = localDatasource ?? AuthLocalDatasource(),
       _storageService = storageService ?? StorageService(),
       _googleSignInService = googleSignInService ?? GoogleSignInService();

  Future<User> _persistAuthenticatedUser(User user) async {
    if (user.token != null) {
      final tokenSaved = await _localDatasource.saveToken(user.token!);
      if (!tokenSaved) {
        throw Exception('Failed to save authentication token');
      }
    }

    if (user.refreshToken != null && user.refreshToken!.isNotEmpty) {
      final refreshTokenSaved = await _storageService.saveRefreshToken(
        user.refreshToken!,
      );
      if (!refreshTokenSaved) {
        throw Exception('Failed to save refresh token');
      }
    }

    await _storageService.saveUserData(user.toJson());

    return user.copyWith(token: null, refreshToken: null);
  }

  @override
  Future<User> login(String email, String password) async {
    try {
      final user = await _remoteDatasource.login(email, password);
      return _persistAuthenticatedUser(user);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<User> loginWithGoogle() async {
    try {
      final idToken = await _googleSignInService.authenticateAndGetIdToken();
      final user = await _remoteDatasource.loginWithGoogle(idToken);
      return _persistAuthenticatedUser(user);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<User> register(
    String firstName,
    String lastName,
    String email,
    String password,
  ) async {
    try {
      final user = await _remoteDatasource.register(
        firstName,
        lastName,
        email,
        password,
      );

      return _persistAuthenticatedUser(user);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      try {
        await _remoteDatasource.logout();
      } catch (_) {}
      await _googleSignInService.signOutSilently();

      final tokenDeleted = await _localDatasource.deleteToken();
      if (!tokenDeleted) {
        throw Exception('Failed to delete authentication token');
      }

      await _storageService.deleteUserData();
      await _storageService.setLoggedIn(false);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    try {
      final token = await _localDatasource.getToken();
      if (token == null) {
        return null;
      }

      final userData = await _storageService.getUserData();

      try {
        final user = await _remoteDatasource.getProfile();
        await _storageService.saveUserData(user.toJson());
        return user.copyWith(token: token);
      } catch (e) {
        final latestToken = await _localDatasource.getToken();
        if (latestToken == null || (e is ApiException && e.isUnauthorized)) {
          await _storageService.deleteUserData();
          await _storageService.setLoggedIn(false);
          return null;
        }

        if (userData != null) {
          return User.fromJson(userData).copyWith(token: latestToken);
        }
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
