import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import 'package:claim_ai/config/app_config.dart';
import 'package:claim_ai/features/assistant/data/models/chat_stream_message.dart';
import 'package:claim_ai/features/assistant/data/datasources/chatbot_api_client.dart';

/// Simplified chat service that delegates all auth handling to [ApiClient].
///
/// Uses the streaming `/chat/stream` endpoint for all messages.
class ChatService {
  /// Stream structured messages from the chatbot via SSE.
  ///
  /// `language` is the BCP-47 language code (e.g. "en", "it") and
  /// `countryCode` is the ISO-3166 country code (e.g. "IN", "IT") of the
  /// currently-selected app locale. The backend uses both to localize AI
  /// replies.
  static Stream<ChatStreamMessage> sendMessage(
    String message, {
    String? threadId,
    String? language,
    String? countryCode,
  }) async* {
    await for (final raw in ApiClient.getStream(
      '/chat/stream',
      queryParams: {
        'message': message,
        'thread_id': ?threadId,
        'language': ?language,
        'country_code': ?countryCode,
      },
    )) {
      if (kDebugMode) {
        debugPrint('[chat/stream] ← ${jsonEncode(raw)}');
      }
      yield ChatStreamMessage.fromJson(raw);
    }
  }

  /// POSTs to `/validate-images`. Returns the parsed JSON body.
  /// `images` maps an angle / slot key (e.g. "front_left") to base64-encoded
  /// image bytes (no data-URI prefix).
  static Future<ImageValidationResult> validateImages({
    required String groupKey,
    required String threadId,
    required Map<String, String> images,
    String? language,
    String? countryCode,
  }) async {
    if (kDebugMode) {
      final imageSizes = images.map(
        (k, v) => MapEntry(k, '${v.length} chars (base64)'),
      );
      debugPrint(
        '[validate-images] POST ${AppConfig.chatbotBaseUrl}/validate-images '
        'body={group_key: $groupKey, thread_id: $threadId, '
        'language: $language, country_code: $countryCode, '
        'images: $imageSizes}',
      );
    }
    final response = await ApiClient.post(
      '/validate-images',
      body: {
        'group_key': groupKey,
        'thread_id': threadId,
        'images': images,
        'language': ?language,
        'country_code': ?countryCode,
      },
    );
    if (kDebugMode) {
      debugPrint(
        '[validate-images] ← ${response.statusCode} ${response.body}',
      );
    }
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      body = const {};
    }
    final invalidAngles =
        (body['invalid_angles'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    final responseGroupKey = body['group_key']?.toString() ?? groupKey;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return ImageValidationResult(
        valid: false,
        failureReason:
            (body['failure_reason'] ?? body['detail'] ?? 'Validation failed')
                .toString(),
        invalidAngles: invalidAngles,
        groupKey: responseGroupKey,
        raw: body,
      );
    }
    return ImageValidationResult(
      valid: body['valid'] == true,
      failureReason: body['failure_reason']?.toString(),
      invalidAngles: invalidAngles,
      groupKey: responseGroupKey,
      raw: body,
    );
  }
}

class ImageValidationResult {
  final bool valid;
  final String? failureReason;
  final List<String> invalidAngles;
  final String? groupKey;
  final Map<String, dynamic> raw;
  const ImageValidationResult({
    required this.valid,
    this.failureReason,
    this.invalidAngles = const [],
    this.groupKey,
    this.raw = const {},
  });
}
