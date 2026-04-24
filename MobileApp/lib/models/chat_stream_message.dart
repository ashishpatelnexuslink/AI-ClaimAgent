/// A single message from the `/chat/stream` SSE endpoint.
class ChatStreamMessage {
  final String content;
  final String messageType;
  final List<String> suggestions;
  final List<String> triggers;
  final Map<String, dynamic>? claimData;
  final String? payloadType;
  final Map<String, dynamic>? payload;

  const ChatStreamMessage({
    required this.content,
    this.messageType = '',
    this.suggestions = const [],
    this.triggers = const [],
    this.claimData,
    this.payloadType,
    this.payload,
  });

  factory ChatStreamMessage.fromJson(Map<String, dynamic> json) {
    return ChatStreamMessage(
      content: json['content'] as String? ?? '',
      messageType: json['message_type'] as String? ?? '',
      suggestions: (json['suggestions'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      triggers: (json['triggers'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      claimData: json['claim_data'] as Map<String, dynamic>?,
      payloadType: json['payload_type'] as String?,
      payload: json['payload'] as Map<String, dynamic>?,
    );
  }
}
