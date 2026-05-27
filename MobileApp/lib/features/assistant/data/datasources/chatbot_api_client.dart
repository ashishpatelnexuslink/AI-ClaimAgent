import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:http/http.dart' as http;

import 'package:claim_ai/config/app_config.dart';
import 'package:claim_ai/features/assistant/data/datasources/chatbot_auth_service.dart';

/// Single place for all authenticated HTTP calls to the chatbot API.
///
/// Automatically injects tokens and retries once on 401.
class ApiClient {
  static final _client = http.Client();
  static const _timeout = Duration(seconds: 60);

  // ── GET ──────────────────────────────────────────────────────────
  static Future<http.Response> get(
    String path, {
    Map<String, String>? queryParams,
  }) async {
    return _executeWithRetry(() async {
      final token = await AuthService.getValidToken();
      final uri = Uri.parse(
        '${AppConfig.chatbotBaseUrl}$path',
      ).replace(queryParameters: queryParams);
      return await _client
          .get(uri, headers: _buildHeaders(token))
          .timeout(_timeout);
    });
  }

  // ── POST ─────────────────────────────────────────────────────────
  static Future<http.Response> post(
    String path, {
    required Map<String, dynamic> body,
  }) async {
    return _executeWithRetry(() async {
      final token = await AuthService.getValidToken();
      return await _client
          .post(
            Uri.parse('${AppConfig.chatbotBaseUrl}$path'),
            headers: _buildHeaders(token),
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    });
  }

  // ── SSE STREAM (GET) ──────────────────────────────────────────────
  /// Yields each message object from the SSE stream as a raw map.
  static Stream<Map<String, dynamic>> getStream(
    String path, {
    Map<String, String>? queryParams,
  }) async* {
    final token = await AuthService.getValidToken();
    final uri = Uri.parse(
      '${AppConfig.chatbotBaseUrl}$path',
    ).replace(queryParameters: queryParams);

    if (kDebugMode) {
      debugPrint('[chat-stream] GET $uri');
    }

    final request = http.Request('GET', uri);
    request.headers.addAll(_buildHeaders(token));

    final streamedResponse = await _client.send(request);

    if (streamedResponse.statusCode == 401) {
      final newToken = await AuthService.forceRefresh();
      final retryRequest = http.Request('GET', uri);
      retryRequest.headers.addAll(_buildHeaders(newToken));
      final retryResponse = await _client.send(retryRequest);
      yield* _parseSSEStream(retryResponse);
      return;
    }

    yield* _parseSSEStream(streamedResponse);
  }

  // ── RETRY LOGIC ──────────────────────────────────────────────────
  static Future<http.Response> _executeWithRetry(
    Future<http.Response> Function() call,
  ) async {
    final response = await call();

    if (response.statusCode == 401) {
      // Token rejected → force silent re-login and retry once
      await AuthService.forceRefresh();
      return await call();
    }

    return response;
  }

  // ── SSE PARSER ───────────────────────────────────────────────────
  static Stream<Map<String, dynamic>> _parseSSEStream(
    http.StreamedResponse response,
  ) async* {
    await for (final chunk
        in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      if (chunk.startsWith('data: ')) {
        final data = chunk.substring(6).trim();
        if (data.isEmpty) continue;
        try {
          final json = jsonDecode(data) as Map<String, dynamic>;
          if (json['type'] == 'done') break;
          if (json['type'] == 'error') {
            throw Exception(json['message'] as String);
          }
          if (json['type'] == 'message') {
            final messages =
                (json['payload'] as Map<String, dynamic>)['messages'] as List;
            for (final msg in messages) {
              yield msg as Map<String, dynamic>;
            }
          }
        } catch (_) {
          // Skip malformed SSE frames
        }
      }
    }
  }

  static Map<String, String> _buildHeaders(String token) => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };
}
