import 'package:dio/dio.dart';
import 'package:claim_ai/core/auth/session_event_bus.dart';
import 'package:claim_ai/core/storage/local_storage.dart';
import 'package:claim_ai/core/constants/api_constants.dart';
import 'package:claim_ai/core/config/env_config.dart';
import 'package:claim_ai/core/utils/app_version_info.dart';

class ApiInterceptor extends Interceptor {
  final LocalStorage _localStorage;
  final Dio _dio;
  final SessionEventBus _sessionBus;

  ApiInterceptor({
    required LocalStorage localStorage,
    required Dio dio,
    required SessionEventBus sessionBus,
  }) : _localStorage = localStorage,
       _dio = dio,
       _sessionBus = sessionBus;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _localStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    // Let Dio set the correct Content-Type for FormData (multipart/form-data)
    if (options.data is! FormData) {
      options.headers['Content-Type'] = 'application/json';
    }
    options.headers['Accept'] = 'application/json';

    try {
      final info = await AppVersionInfo.current();
      options.headers['X-App-Version'] = info.versionName;
      options.headers['X-App-Platform'] = info.platform;
    } catch (_) {
      // PackageInfo can fail in some test contexts — skip silently.
    }

    // Tell the backend which language to localize its response in (validation
    // messages, AI chat replies, notification text, etc.). Reads directly from
    // LocalStorage rather than LocaleCubit to keep this interceptor free of a
    // BLoC dependency. Emits a BCP-47 tag like "it-IT" when both pieces are
    // available, falling back to just the language ("it") otherwise.
    final localeCode = _localStorage.getLocaleCode();
    if (localeCode != null && localeCode.isNotEmpty) {
      final countryCode = _localStorage.getCountryCode();
      final tag = (countryCode != null && countryCode.isNotEmpty)
          ? '$localeCode-$countryCode'
          : localeCode;
      options.headers['Accept-Language'] = tag;
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        final retryResponse = await _retryRequest(err.requestOptions);
        return handler.resolve(retryResponse);
      }
      await _localStorage.clearTokens();
      _sessionBus.emit(SessionEvent.expired);
    }

    handler.next(err);
  }

  Future<bool> _tryRefreshToken() async {
    try {
      final refreshToken = await _localStorage.getRefreshToken();
      final accessToken = await _localStorage.getAccessToken();
      if (refreshToken == null) return false;

      final response = await Dio().post(
        '${EnvConfig.baseUrl}${ApiConstants.refreshToken}',
        data: {'accessToken': accessToken ?? '', 'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        final newAccessToken = data['accessToken'] as String;
        final newRefreshToken = data['refreshToken'] as String;
        await _localStorage.saveAccessToken(newAccessToken);
        await _localStorage.saveRefreshToken(newRefreshToken);
        return true;
      }
      return false;
    } catch (_) {
      await _localStorage.clearTokens();
      return false;
    }
  }

  Future<Response> _retryRequest(RequestOptions requestOptions) async {
    // Re-issue the exact original request — preserves baseUrl, path, method,
    // data, query params and headers. Avoids Flutter Web resolving a relative
    // path against the browser origin (localhost:<devPort>) on retry.
    final token = await _localStorage.getAccessToken();
    requestOptions.headers['Authorization'] = 'Bearer $token';

    // FormData is a single-use stream — Dio consumes its bytes during the
    // first attempt. Without cloning, the retry tries to re-read an empty
    // stream and the upload silently fails (the 401 we just refreshed past
    // becomes a hung request or a confusing follow-on error). Clone so the
    // retry has fresh bytes.
    if (requestOptions.data is FormData) {
      requestOptions.data = (requestOptions.data as FormData).clone();
    }

    return _dio.fetch(requestOptions);
  }
}
