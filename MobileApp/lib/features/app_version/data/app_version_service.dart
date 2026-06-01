import 'package:claim_ai/core/constants/api_constants.dart';
import 'package:claim_ai/core/network/dio_client.dart';
import 'package:claim_ai/core/utils/app_version_info.dart';
import 'package:claim_ai/features/app_version/data/app_version_models.dart';

class AppVersionService {
  final DioClient _client;

  AppVersionService({required DioClient client}) : _client = client;

  Future<VersionCheckResult?> checkForUpdate() async {
    try {
      final info = await AppVersionInfo.current();
      final response = await _client.post(
        ApiConstants.appVersionCheck,
        data: {
          'platform': info.platform,
          'versionCode': info.versionCode,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>?;
      if (data == null) return null;
      return VersionCheckResult.fromJson(data);
    } catch (_) {
      // Network/backend not configured yet — fail open, no update prompt.
      return null;
    }
  }
}
