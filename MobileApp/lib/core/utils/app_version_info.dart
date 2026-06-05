import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionInfo {
  AppVersionInfo._(this.versionName, this.versionCode, this.platform);

  final String versionName;
  final int versionCode;
  final String platform;

  static AppVersionInfo? _cached;

  /// `Platform.isIOS` from dart:io throws `UnsupportedError` on Flutter Web,
  /// so gate the lookup behind `kIsWeb` before touching it.
  static String _detectPlatform() {
    if (kIsWeb) return 'Web';
    return Platform.isIOS ? 'iOS' : 'Android';
  }

  static Future<AppVersionInfo> current() async {
    if (_cached != null) return _cached!;
    final platform = _detectPlatform();
    try {
      final info = await PackageInfo.fromPlatform();
      final code = int.tryParse(info.buildNumber) ?? 0;
      return _cached = AppVersionInfo._(info.version, code, platform);
    } catch (_) {
      // package_info_plus is a native plugin; first launch after adding it
      // needs a full app restart (not hot reload). Fall back to the pubspec
      // version so the Profile screen still shows something useful.
      return _cached = AppVersionInfo._('1.0.0', 1, platform);
    }
  }
}
