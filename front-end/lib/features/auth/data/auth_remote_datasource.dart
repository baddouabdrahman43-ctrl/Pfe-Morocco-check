import '../../../core/network/api_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/models/user.dart';

class AuthRemoteDatasource {
  final ApiService _apiService;

  AuthRemoteDatasource({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  Future<User> login(String email, String password) async {
    final response = await _apiService.post(
      '${AppConstants.authBasePath}/login',
      data: <String, dynamic>{'email': email, 'password': password},
    );

    return _parseAuthUser(response.data as Map<String, dynamic>);
  }

  Future<User> loginWithGoogle(String idToken) async {
    final response = await _apiService.post(
      '${AppConstants.authBasePath}/google',
      data: <String, dynamic>{'id_token': idToken},
    );

    return _parseAuthUser(response.data as Map<String, dynamic>);
  }

  Future<User> register(
    String firstName,
    String lastName,
    String email,
    String password,
  ) async {
    final response = await _apiService.post(
      '${AppConstants.authBasePath}/register',
      data: <String, dynamic>{
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'password': password,
      },
    );

    return _parseAuthUser(response.data as Map<String, dynamic>);
  }

  Future<User> getProfile() async {
    final response = await _apiService.get(
      '${AppConstants.authBasePath}/profile',
    );
    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] as Map<String, dynamic>? ?? responseData;
    final userData = data['user'] as Map<String, dynamic>? ?? data;
    return User.fromJson(<String, dynamic>{
      ...userData,
      'badges': data['badges'],
    });
  }

  Future<void> logout() async {
    await _apiService.post('${AppConstants.authBasePath}/logout');
  }

  User _parseAuthUser(Map<String, dynamic> responseData) {
    final data = responseData['data'] as Map<String, dynamic>? ?? responseData;
    final userData =
        data['user'] as Map<String, dynamic>? ?? <String, dynamic>{};

    return User.fromJson(<String, dynamic>{
      ...userData,
      'token': data['access_token'] ?? data['token'],
      'refresh_token': data['refresh_token'],
    });
  }
}
