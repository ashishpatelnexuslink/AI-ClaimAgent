import 'package:claim_ai/models/chat_stream_message.dart';
import 'package:claim_ai/services/api_client.dart';

/// Simplified chat service that delegates all auth handling to [ApiClient].
///
/// Uses the streaming `/chat/stream` endpoint for all messages.
class ChatService {
  /// Stream structured messages from the chatbot via SSE.
  ///
  /// Each yielded [ChatStreamMessage] contains `content`, `messageType`,
  /// and `suggestions`.
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
}
