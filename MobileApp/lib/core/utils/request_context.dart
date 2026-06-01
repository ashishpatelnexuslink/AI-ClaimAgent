import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:claim_ai/core/storage/local_storage.dart';
import 'package:claim_ai/core/utils/app_version_info.dart';
import 'package:claim_ai/injection_container.dart';

/// Stable per-install device id, persisted in SharedPreferences. Reset on
/// reinstall (which is when SharedPreferences is wiped). Matches the user's
/// "privacy-safe stable UUID" choice over Android ID / iOS identifierForVendor.
class DeviceIdProvider {
  static const _key = 'device_install_id';
  static String? _cached;

  static Future<String> get() async {
    if (_cached != null) return _cached!;
    final storage = sl<LocalStorage>();
    final existing = storage.getString(_key);
    if (existing != null && existing.isNotEmpty) {
      return _cached = existing;
    }
    final fresh = const Uuid().v4();
    await storage.setString(_key, fresh);
    return _cached = fresh;
  }
}

/// Public IP — fetched once per app session via api.ipify.org. Returns null
/// on any failure so callers can simply omit the field.
class PublicIpProvider {
  static String? _cached;

  static Future<String?> get() async {
    if (_cached != null) return _cached;
    try {
      final response = await http
          .get(Uri.parse('https://api.ipify.org?format=json'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final ip = body['ip']?.toString();
      if (ip == null || ip.isEmpty) return null;
      return _cached = ip;
    } catch (_) {
      return null;
    }
  }
}

/// Bundles the three request-context fields used after `save_summary`.
class ChatRequestContext {
  final String deviceId;
  final String? ipAddress;
  final String appVersion;

  const ChatRequestContext({
    required this.deviceId,
    required this.ipAddress,
    required this.appVersion,
  });

  static Future<ChatRequestContext> gather() async {
    final results = await Future.wait<dynamic>([
      DeviceIdProvider.get(),
      PublicIpProvider.get(),
      AppVersionInfo.current(),
    ]);
    return ChatRequestContext(
      deviceId: results[0] as String,
      ipAddress: results[1] as String?,
      appVersion: (results[2] as AppVersionInfo).versionName,
    );
  }
}
