import 'package:dio/dio.dart';
import 'package:claim_ai/core/storage/local_storage.dart';
import 'package:claim_ai/core/constants/api_constants.dart';
import 'package:claim_ai/core/config/env_config.dart';
import 'package:logger/logger.dart';

class ApiInterceptor extends Interceptor {
  final LocalStorage _localStorage;
  final Dio _dio;
  final Logger _logger = Logger();

  ApiInterceptor({
    required LocalStorage localStorage,
    required Dio dio,
  })  : _localStorage = localStorage,
        _dio = dio;

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

    _logger.d('REQUEST[${options.method}] => PATH: ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _logger.d(
      'RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    _logger.e(
      'ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}\n'
      'METHOD: ${err.requestOptions.method}\n'
      'REQUEST DATA: ${err.requestOptions.data}\n'
      'QUERY: ${err.requestOptions.queryParameters}\n'
      'RESPONSE BODY: ${err.response?.data}\n'
      'DIO MESSAGE: ${err.message}',
    );

    if (err.response?.statusCode == 401) {
      final refreshed = await _tryRefreshToken();
      if (refreshed) {
        final retryResponse = await _retryRequest(err.requestOptions);
        return handler.resolve(retryResponse);
      }
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
        data: {
          'accessToken': accessToken ?? '',
          'refreshToken': refreshToken,
        },
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
