import 'package:claim_ai/config/app_config.dart';

class TokenModel {
  final String accessToken;
  final DateTime expiresAt;

  TokenModel({
    required this.accessToken,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(
        expiresAt.subtract(Duration(minutes: AppConfig.tokenExpiryBuffer)),
      );

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'expires_at': expiresAt.toIso8601String(),
      };

  factory TokenModel.fromJson(Map<String, dynamic> json) => TokenModel(
        accessToken: json['access_token'] as String,
        expiresAt: DateTime.parse(json['expires_at'] as String),
      );
}
