import 'package:claim_ai/core/constants/api_constants.dart';

enum Environment { dev, staging, prod }

class EnvConfig {
  static Environment _environment = Environment.prod;

  static Environment get environment => _environment;

  static void init(Environment env) {
    _environment = env;
  }

  static String get baseUrl {
    switch (_environment) {
      case Environment.dev:
        return ApiConstants.devBaseUrl;
      case Environment.staging:
        return ApiConstants.stagingBaseUrl;
      case Environment.prod:
        return ApiConstants.prodBaseUrl;
    }
  }

  static bool get isDev => _environment == Environment.dev;
  static bool get isStaging => _environment == Environment.staging;
  static bool get isProd => _environment == Environment.prod;
}
