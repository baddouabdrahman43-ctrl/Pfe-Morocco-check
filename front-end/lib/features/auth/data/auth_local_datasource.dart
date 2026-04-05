import '../../../core/storage/storage_service.dart';

class AuthLocalDatasource {
  final StorageService _storageService;

  AuthLocalDatasource({StorageService? storageService})
    : _storageService = storageService ?? StorageService();

  /// Save JWT token securely using FlutterSecureStorage
  /// Returns true if successful, false otherwise
  Future<bool> saveToken(String token) async {
    return await _storageService.saveToken(token);
  }

  /// Get JWT token from FlutterSecureStorage
  /// Returns the token if found, null otherwise
  Future<String?> getToken() async {
    return await _storageService.getToken();
  }

  /// Delete JWT token from FlutterSecureStorage
  /// Also clears refresh token and sets logged in state to false
  /// Returns true if successful, false otherwise
  Future<bool> deleteToken() async {
    return await _storageService.deleteToken();
  }
}
