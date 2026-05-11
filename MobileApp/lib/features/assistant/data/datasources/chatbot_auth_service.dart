import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:claim_ai/config/app_config.dart';
import 'package:claim_ai/features/assistant/data/models/token_model.dart';

/// Handles silent, background authentication.
///
/// The user never sees a login screen — this service fetches, caches,
/// persists, and refreshes tokens automatically.
class AuthService {
  static TokenModel? _cachedToken;
  static bool _isRefreshing = false;

  // ── MAIN METHOD ──────────────────────────────────────────────────
  /// Returns a valid access-token string, handling every edge-case
  /// silently (cache → storage → silent login).
  static Future<String> getValidToken() async {
    // 1. In-memory cache hit
    if (_cachedToken != null && !_cachedToken!.isExpired) {
      return _cachedToken!.accessToken;
    }

    // 2. Try SharedPreferences
    final stored = await _loadTokenFromStorage();
    if (stored != null && !stored.isExpired) {
      _cachedToken = stored;
      return _cachedToken!.accessToken;
    }

    // 3. Token missing or expired → silent login
    return await _silentLogin();
  }

  // ── SILENT LOGIN ─────────────────────────────────────────────────
  static Future<String> _silentLogin() async {
    // Prevent duplicate concurrent login calls
    if (_isRefreshing) {
      await Future.delayed(const Duration(milliseconds: 200));
      return getValidToken();
    }

    _isRefreshing = true;
    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.chatbotBaseUrl}/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': AppConfig.username,
              'password': AppConfig.password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = TokenModel(
          accessToken: data['access_token'] as String,
          expiresAt: _parseExpiryFromJwt(data['access_token'] as String),
        );
        _cachedToken = token;
        await _saveTokenToStorage(token);
        return token.accessToken;
      } else {
        throw Exception('Silent login failed: ${response.statusCode}');
      }
    } finally {
      _isRefreshing = false;
    }
  }

  // ── JWT EXPIRY PARSER ────────────────────────────────────────────
  static DateTime _parseExpiryFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) throw const FormatException('Invalid JWT');

      String payload = parts[1];
      // Pad to a multiple of 4 for base64
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final decoded = utf8.decode(base64Url.decode(payload));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      if (map['exp'] != null) {
        return DateTime.fromMillisecondsSinceEpoch(
          (map['exp'] as num).toInt() * 1000,
        );
      }
    } catch (_) {
      // Fall through to default
    }
    // Fallback: assume 55-minute expiry
    return DateTime.now().add(const Duration(minutes: 55));
  }

  // ── FORCE REFRESH ────────────────────────────────────────────────
  /// Called when a 401 is received from any API call.
  static Future<String> forceRefresh() async {
    _cachedToken = null;
    await _clearTokenFromStorage();
    return await _silentLogin();
  }

  // ── STORAGE HELPERS ──────────────────────────────────────────────
  static const _storageKey = 'chatbot_auth_token';

  static Future<void> _saveTokenToStorage(TokenModel token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(token.toJson()));
  }

  static Future<TokenModel?> _loadTokenFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return null;
      return TokenModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> _clearTokenFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}
