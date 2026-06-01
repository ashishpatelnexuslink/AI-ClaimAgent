import 'dart:io';
import 'package:package_info_plus/package_info_plus.dart';

class AppVersionInfo {
  AppVersionInfo._(this.versionName, this.versionCode, this.platform);

  final String versionName;
  final int versionCode;
  final String platform;

  static AppVersionInfo? _cached;

  static Future<AppVersionInfo> current() async {
    if (_cached != null) return _cached!;
    final platform = Platform.isIOS ? 'iOS' : 'Android';
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
