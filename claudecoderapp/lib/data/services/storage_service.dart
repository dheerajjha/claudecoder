import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';

class StorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Secure storage for sensitive data
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: ApiConstants.tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _secureStorage.read(key: ApiConstants.tokenKey);
  }

  Future<void> deleteToken() async {
    await _secureStorage.delete(key: ApiConstants.tokenKey);
  }

  Future<void> saveUsername(String username) async {
    await _secureStorage.write(key: ApiConstants.usernameKey, value: username);
  }

  Future<String?> getUsername() async {
    return await _secureStorage.read(key: ApiConstants.usernameKey);
  }

  // Shared preferences for non-sensitive data
  Future<void> saveBaseUrl(String url) async {
    await _prefs?.setString(ApiConstants.baseUrlKey, url);
  }

  Future<String> getBaseUrl() async {
    return _prefs?.getString(ApiConstants.baseUrlKey) ??
        ApiConstants.defaultBaseUrl;
  }

  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    await _prefs?.clear();
  }
}
