import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/api_constants.dart';

class StorageService {
  StorageService();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Future<SharedPreferences> _prefsFuture =
      SharedPreferences.getInstance();

  // Secure storage for sensitive data
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: ApiConstants.tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return _secureStorage.read(key: ApiConstants.tokenKey);
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: ApiConstants.tokenKey);
  }

  Future<void> saveUsername(String username) async {
    await _secureStorage.write(key: ApiConstants.usernameKey, value: username);
  }

  Future<String?> getUsername() async {
    return _secureStorage.read(key: ApiConstants.usernameKey);
  }

  // Shared preferences for non-sensitive data
  Future<void> saveBaseUrl(String url) async {
    print('💾 StorageService: Saving base URL: $url');
    final prefs = await _prefsFuture;
    await prefs.setString(ApiConstants.baseUrlKey, url);
    print('✅ StorageService: Base URL saved successfully');
  }

  Future<String> getBaseUrl() async {
    final prefs = await _prefsFuture;
    final url = prefs.getString(ApiConstants.baseUrlKey) ??
        ApiConstants.defaultBaseUrl;
    print('📖 StorageService: Retrieved base URL: $url');
    return url;
  }

  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    final prefs = await _prefsFuture;
    await prefs.clear();
  }
}
