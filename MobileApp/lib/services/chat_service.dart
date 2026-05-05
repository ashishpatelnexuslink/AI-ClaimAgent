import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import 'package:claim_ai/config/app_config.dart';
import 'package:claim_ai/models/chat_stream_message.dart';
import 'package:claim_ai/services/api_client.dart';

/// Simplified chat service that delegates all auth handling to [ApiClient].
///
/// Uses the streaming `/chat/stream` endpoint for all messages.
class ChatService {
  /// Stream structured messages from the chatbot via SSE.
  static Stream<ChatStreamMessage> sendMessage(
    String message, {
    String? threadId,
  }) async* {
    await for (final raw in ApiClient.getStream(
      '/chat/stream',
      queryParams: {'message': message, 'thread_id': ?threadId},
    )) {
      yield ChatStreamMessage.fromJson(raw);
    }
  }

  /// POSTs to `/validate-images`. Returns the parsed JSON body.
  /// `images` maps an angle / slot key (e.g. "front_left") to base64-encoded
  /// image bytes (no data-URI prefix).
  static Future<ImageValidationResult> validateImages({
    required String questionLabel,
    required String threadId,
    required Map<String, String> images,
  }) async {
    if (kDebugMode) {
      final imageSizes = images.map(
        (k, v) => MapEntry(k, '${v.length} chars (base64)'),
      );
      debugPrint(
        '[validate-images] POST ${AppConfig.chatbotBaseUrl}/validate-images '
        'body={question_label: $questionLabel, thread_id: $threadId, '
        'images: $imageSizes}',
      );
    }
    final response = await ApiClient.post(
      '/validate-images',
      body: {
        'question_label': questionLabel,
        'thread_id': threadId,
        'images': images,
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
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return ImageValidationResult(
        valid: false,
        failureReason:
            (body['failure_reason'] ?? body['detail'] ?? 'Validation failed')
                .toString(),
        raw: body,
      );
    }
    return ImageValidationResult(
      valid: body['valid'] == true,
      failureReason: body['failure_reason']?.toString(),
      raw: body,
    );
  }
}

class ImageValidationResult {
  final bool valid;
  final String? failureReason;
  final Map<String, dynamic> raw;
  const ImageValidationResult({
    required this.valid,
    this.failureReason,
    this.raw = const {},
  });
}
