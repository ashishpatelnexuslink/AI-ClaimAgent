class AppConfig {
  static const String chatbotBaseUrl =
      'https://aiagnetforclaim.nexuslink.co.in';

  // For production, load from --dart-define:
  //   flutter run --dart-define=USERNAME=xxx --dart-define=PASSWORD=xxx
  static const String username = String.fromEnvironment(
    'USERNAME',
    defaultValue: 'svc_claimbot_mobile_prod',
  );
  static const String password = String.fromEnvironment(
    'PASSWORD',
    defaultValue: 'V9rQ2!mL7@tP4\$zN8^wK3&x',
  );

  /// Refresh token this many minutes before it actually expires.
  static const int tokenExpiryBuffer = 5;
}
