import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  final FlutterSecureStorage _secureStorage;
  final SharedPreferences _prefs;

  LocalStorage({
    required FlutterSecureStorage secureStorage,
    required SharedPreferences prefs,
  })  : _secureStorage = secureStorage,
        _prefs = prefs;

  // Secure token storage
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  Future<void> saveAccessToken(String token) async {
    await _secureStorage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  Future<void> clearTokens() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    // NOTE: the biometric flag is intentionally NOT cleared here. Token clears
    // also fire on 401/refresh failures from the Dio interceptor — wiping the
    // flag in that path silently disables biometric for the user. The flag is
    // only cleared on explicit logout (see AuthRepositoryImpl.logout).
  }

  /// True if either an access or refresh token is present in secure storage.
  /// Used to gate biometric login so we don't prompt when there's no session
  /// to unlock.
  Future<bool> hasStoredSession() async {
    final access = await getAccessToken();
    if (access != null && access.isNotEmpty) return true;
    final refresh = await getRefreshToken();
    return refresh != null && refresh.isNotEmpty;
  }

  // SharedPreferences for non-sensitive data
  Future<void> setBool(String key, bool value) async {
    await _prefs.setBool(key, value);
  }

  bool? getBool(String key) => _prefs.getBool(key);

  Future<void> setString(String key, String value) async {
    await _prefs.setString(key, value);
  }

  String? getString(String key) => _prefs.getString(key);

  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
    await _prefs.clear();
  }

  // Biometric preference (stored in secure storage alongside auth tokens
  // so it gets cleared together on logout).
  static const _biometricKey = 'biometric_enabled';

  Future<bool> isBiometricEnabled() async {
    final value = await _secureStorage.read(key: _biometricKey);
    return value == 'true';
  }

  Future<void> setBiometricEnabled(bool value) async {
    await _secureStorage.write(key: _biometricKey, value: value ? 'true' : 'false');
  }

  Future<void> clearBiometricFlag() async {
    await _secureStorage.delete(key: _biometricKey);
  }

  // First launch check
  bool get isFirstLaunch => getBool('is_first_launch') ?? true;

  Future<void> setFirstLaunchDone() async {
    await setBool('is_first_launch', false);
  }
}
