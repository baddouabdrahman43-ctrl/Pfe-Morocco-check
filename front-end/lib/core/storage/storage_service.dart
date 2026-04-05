import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // Singleton instance
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // Storage instances
  late final FlutterSecureStorage _secureStorage;
  late SharedPreferences _prefs;
  bool _isInitialized = false;
  final ValueNotifier<String> preferredLanguageNotifier = ValueNotifier<String>(
    'fr',
  );

  // Storage keys
  static const String _tokenKey = 'jwt_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userDataKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _preferredLanguageKey = 'settings_preferred_language';
  static const String _notificationsEnabledKey =
      'settings_notifications_enabled';
  static const String _preciseLocationEnabledKey =
      'settings_precise_location_enabled';
  static const String _technicalInfoVisibleKey =
      'settings_technical_info_visible';
  static const String _apiBaseUrlKey = 'settings_api_base_url';
  static const String _biometricAuthEnabledKey =
      'settings_biometric_auth_enabled';
  static const String _dailyReminderEnabledKey =
      'settings_daily_reminder_enabled';
  static const String _dailyReminderHourKey = 'settings_daily_reminder_hour';
  static const Set<String> _supportedLanguageCodes = <String>{
    'fr',
    'ar',
    'en',
  };

  // Initialize storage
  Future<void> init() async {
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(),
    );
    _prefs = await SharedPreferences.getInstance();
    preferredLanguageNotifier.value = getPreferredLanguage();
    _isInitialized = true;
  }

  bool get isInitialized => _isInitialized;

  // ==================== JWT Token Methods (Secure Storage) ====================

  /// Save JWT token securely
  Future<bool> saveToken(String token) async {
    if (!_isInitialized) return false;
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
      await _prefs.setBool(_isLoggedInKey, true);
      return true;
    } catch (e) {
      debugPrint('Error saving token: $e');
      return false;
    }
  }

  /// Get JWT token
  Future<String?> getToken() async {
    if (!_isInitialized) return null;
    try {
      return await _secureStorage.read(key: _tokenKey);
    } catch (e) {
      debugPrint('Error reading token: $e');
      return null;
    }
  }

  /// Save refresh token securely
  Future<bool> saveRefreshToken(String refreshToken) async {
    if (!_isInitialized) return false;
    try {
      await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
      return true;
    } catch (e) {
      debugPrint('Error saving refresh token: $e');
      return false;
    }
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    if (!_isInitialized) return null;
    try {
      return await _secureStorage.read(key: _refreshTokenKey);
    } catch (e) {
      debugPrint('Error reading refresh token: $e');
      return null;
    }
  }

  /// Delete JWT token
  Future<bool> deleteToken() async {
    if (!_isInitialized) return false;
    try {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      await _prefs.setBool(_isLoggedInKey, false);
      return true;
    } catch (e) {
      debugPrint('Error deleting token: $e');
      return false;
    }
  }

  // ==================== User Data Methods (SharedPreferences) ====================

  /// Save user data as JSON
  Future<bool> saveUserData(Map<String, dynamic> userData) async {
    if (!_isInitialized) return false;
    try {
      final jsonString = jsonEncode(userData);
      await _prefs.setString(_userDataKey, jsonString);
      return true;
    } catch (e) {
      debugPrint('Error saving user data: $e');
      return false;
    }
  }

  /// Get user data as Map
  Future<Map<String, dynamic>?> getUserData() async {
    if (!_isInitialized) return null;
    try {
      final jsonString = _prefs.getString(_userDataKey);
      if (jsonString == null) return null;
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error reading user data: $e');
      return null;
    }
  }

  /// Get specific user field
  Future<T?> getUserField<T>(String key) async {
    try {
      final userData = await getUserData();
      if (userData == null) return null;
      return userData[key] as T?;
    } catch (e) {
      debugPrint('Error reading user field: $e');
      return null;
    }
  }

  /// Update specific user field
  Future<bool> updateUserField(String key, dynamic value) async {
    try {
      final userData = await getUserData() ?? {};
      userData[key] = value;
      return await saveUserData(userData);
    } catch (e) {
      debugPrint('Error updating user field: $e');
      return false;
    }
  }

  /// Delete user data
  Future<bool> deleteUserData() async {
    if (!_isInitialized) return false;
    try {
      await _prefs.remove(_userDataKey);
      return true;
    } catch (e) {
      debugPrint('Error deleting user data: $e');
      return false;
    }
  }

  // ==================== Authentication State Methods ====================

  /// Check if user is logged in
  bool get isLoggedIn =>
      _isInitialized ? (_prefs.getBool(_isLoggedInKey) ?? false) : false;

  /// Set login state
  Future<bool> setLoggedIn(bool value) async {
    if (!_isInitialized) return false;
    try {
      await _prefs.setBool(_isLoggedInKey, value);
      return true;
    } catch (e) {
      debugPrint('Error setting login state: $e');
      return false;
    }
  }

  // ==================== Clear All Data (Logout) ====================

  /// Clear all stored data (use on logout)
  Future<bool> clearAll() async {
    if (!_isInitialized) return false;
    try {
      // Clear secure storage (tokens)
      await _secureStorage.deleteAll();

      // Clear user data
      await _prefs.remove(_userDataKey);
      await _prefs.setBool(_isLoggedInKey, false);

      return true;
    } catch (e) {
      debugPrint('Error clearing all data: $e');
      return false;
    }
  }

  // ==================== Generic Storage Methods ====================

  /// Save generic string value
  Future<bool> saveString(String key, String value) async {
    if (!_isInitialized) return false;
    try {
      await _prefs.setString(key, value);
      return true;
    } catch (e) {
      debugPrint('Error saving string: $e');
      return false;
    }
  }

  /// Get generic string value
  String? getString(String key) {
    if (!_isInitialized) return null;
    try {
      return _prefs.getString(key);
    } catch (e) {
      debugPrint('Error reading string: $e');
      return null;
    }
  }

  /// Save generic bool value
  Future<bool> saveBool(String key, bool value) async {
    if (!_isInitialized) return false;
    try {
      await _prefs.setBool(key, value);
      return true;
    } catch (e) {
      debugPrint('Error saving bool: $e');
      return false;
    }
  }

  /// Get generic bool value
  bool? getBool(String key) {
    if (!_isInitialized) return null;
    try {
      return _prefs.getBool(key);
    } catch (e) {
      debugPrint('Error reading bool: $e');
      return null;
    }
  }

  /// Save generic int value
  Future<bool> saveInt(String key, int value) async {
    if (!_isInitialized) return false;
    try {
      await _prefs.setInt(key, value);
      return true;
    } catch (e) {
      debugPrint('Error saving int: $e');
      return false;
    }
  }

  /// Get generic int value
  int? getInt(String key) {
    if (!_isInitialized) return null;
    try {
      return _prefs.getInt(key);
    } catch (e) {
      debugPrint('Error reading int: $e');
      return null;
    }
  }

  /// Remove a specific key
  Future<bool> remove(String key) async {
    if (!_isInitialized) return false;
    try {
      await _prefs.remove(key);
      return true;
    } catch (e) {
      debugPrint('Error removing key: $e');
      return false;
    }
  }

  /// Check if a key exists
  bool containsKey(String key) {
    if (!_isInitialized) {
      return false;
    }
    return _prefs.containsKey(key);
  }

  // ==================== App Preferences ====================

  Future<bool> savePreferredLanguage(String value) async {
    final normalized = _normalizeLanguageCode(value);
    final saved = await saveString(_preferredLanguageKey, normalized);
    if (saved) {
      preferredLanguageNotifier.value = normalized;
    }
    return saved;
  }

  String getPreferredLanguage() {
    return _normalizeLanguageCode(getString(_preferredLanguageKey));
  }

  Future<bool> saveNotificationsEnabled(bool value) async {
    return saveBool(_notificationsEnabledKey, value);
  }

  bool getNotificationsEnabled() {
    return getBool(_notificationsEnabledKey) ?? true;
  }

  Future<bool> savePreciseLocationEnabled(bool value) async {
    return saveBool(_preciseLocationEnabledKey, value);
  }

  bool getPreciseLocationEnabled() {
    return getBool(_preciseLocationEnabledKey) ?? true;
  }

  Future<bool> saveTechnicalInfoVisible(bool value) async {
    return saveBool(_technicalInfoVisibleKey, value);
  }

  bool getTechnicalInfoVisible() {
    return getBool(_technicalInfoVisibleKey) ?? false;
  }

  Future<bool> saveApiBaseUrl(String value) async {
    return saveString(_apiBaseUrlKey, value);
  }

  String? getApiBaseUrl() {
    final value = getString(_apiBaseUrlKey)?.trim();
    if (value == null || value.isEmpty) {
      return null;
    }
    return value;
  }

  Future<bool> clearApiBaseUrl() async {
    return remove(_apiBaseUrlKey);
  }

  Future<bool> saveBiometricAuthEnabled(bool value) async {
    return saveBool(_biometricAuthEnabledKey, value);
  }

  bool getBiometricAuthEnabled() {
    return getBool(_biometricAuthEnabledKey) ?? false;
  }

  Future<bool> saveDailyReminderEnabled(bool value) async {
    return saveBool(_dailyReminderEnabledKey, value);
  }

  bool getDailyReminderEnabled() {
    return getBool(_dailyReminderEnabledKey) ?? true;
  }

  Future<bool> saveDailyReminderHour(int value) async {
    return saveInt(_dailyReminderHourKey, value);
  }

  int getDailyReminderHour() {
    return getInt(_dailyReminderHourKey) ?? 19;
  }

  Future<void> resetAppPreferences() async {
    await remove(_preferredLanguageKey);
    await remove(_notificationsEnabledKey);
    await remove(_preciseLocationEnabledKey);
    await remove(_technicalInfoVisibleKey);
    await remove(_apiBaseUrlKey);
    await remove(_biometricAuthEnabledKey);
    await remove(_dailyReminderEnabledKey);
    await remove(_dailyReminderHourKey);
    preferredLanguageNotifier.value = 'fr';
  }

  String _normalizeLanguageCode(String? value) {
    final normalized = (value ?? '').trim().toLowerCase();
    if (_supportedLanguageCodes.contains(normalized)) {
      return normalized;
    }

    final baseLanguage = normalized.split(RegExp('[-_]')).first;
    if (_supportedLanguageCodes.contains(baseLanguage)) {
      return baseLanguage;
    }

    return 'fr';
  }
}
