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
    final rawPayload = json['payload'] as Map<String, dynamic>?;
    // The AI server is inconsistent about where it puts `is_skippable` —
    // sometimes it's a sibling of `payload`, sometimes inside it. Normalize
    // by promoting a top-level value into the payload map so downstream
    // helpers only need to check one location.
    Map<String, dynamic>? payload = rawPayload;
    if (json.containsKey('is_skippable')) {
      payload = {...?rawPayload, 'is_skippable': json['is_skippable']};
    }
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
      payload: payload,
    );
  }

  /// `payload.allowed_angles` for `GET_IMAGE` triggers — drives one upload
  /// row per angle (e.g. front_left, rear_right). Empty list means the
  /// caller should fall back to the legacy single-button flow.
  List<String> get allowedAngles {
    final raw = payload?['allowed_angles'];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList(growable: false);
    }
    return const [];
  }

  /// `payload.min_count` — minimum images required before "Done" enables.
  int? get minCount {
    final raw = payload?['min_count'];
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  /// `payload.max_count` — upper bound on uploadable images.
  int? get maxCount {
    final raw = payload?['max_count'];
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }
}
