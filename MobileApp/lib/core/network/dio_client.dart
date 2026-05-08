import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'package:claim_ai/core/config/env_config.dart';
import 'package:claim_ai/core/constants/api_constants.dart';
import 'package:claim_ai/core/error/exceptions.dart';
import 'package:claim_ai/core/network/api_interceptor.dart';

class DioClient {
  late final Dio _dio;

  DioClient({required ApiInterceptor apiInterceptor}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: EnvConfig.baseUrl,
        connectTimeout: const Duration(
          milliseconds: ApiConstants.connectTimeout,
        ),
        receiveTimeout: const Duration(
          milliseconds: ApiConstants.receiveTimeout,
        ),
        sendTimeout: const Duration(
          milliseconds: ApiConstants.sendTimeout,
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    _dio.interceptors.add(apiInterceptor);

    // Add pretty logger only in debug builds. Registered AFTER ApiInterceptor
    // so the logged request includes the bearer token attached upstream, and
    // it sees responses before ApiInterceptor's 401-refresh logic runs.
    if (kDebugMode) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: true,
          error: true,
          compact: true,
          maxWidth: 120,
        ),
      );
    }
  }

  Dio get dio => _dio;

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Response> uploadFile(
    String path, {
    required FormData data,
    Options? options,
    void Function(int, int)? onSendProgress,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        options: options,
        onSendProgress: onSendProgress,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ServerException(
          message: 'Connection timed out',
          statusCode: 408,
        );
      case DioExceptionType.connectionError:
        return const NetworkException();
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final data = e.response?.data;
        final message = data is Map<String, dynamic>
            ? (data['message'] as String? ?? 'Server error')
            : 'Server error';
        if (statusCode == 401) {
          return UnauthorizedException(message: message);
        }
        return ServerException(message: message, statusCode: statusCode);
      default:
        return ServerException(
          message: e.message ?? 'Unexpected error occurred',
        );
    }
  }
}
