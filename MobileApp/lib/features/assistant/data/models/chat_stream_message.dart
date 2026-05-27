/// A single message from the `/chat/stream` SSE endpoint.
class ChatStreamMessage {
  final String content;
  final String messageType;
  final List<String> suggestions;
  final List<String> triggers;
  final Map<String, dynamic>? claimData;
  final String? payloadType;
  /// Localized key/value map (keys reflect the conversation language).
  /// Render this when displaying the summary to the user.
  final Map<String, dynamic>? payload;
  /// Same shape as [payload] but with stable English keys. Use this when
  /// persisting to the DB so canonical column mapping doesn't depend on the
  /// conversation language. Null on older bot versions that don't emit it —
  /// callers should fall back to [payload] in that case.
  final Map<String, dynamic>? enPayload;

  const ChatStreamMessage({
    required this.content,
    this.messageType = '',
    this.suggestions = const [],
    this.triggers = const [],
    this.claimData,
    this.payloadType,
    this.payload,
    this.enPayload,
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
      // The chatbot occasionally double-escapes line breaks — the SSE payload
      // arrives with the literal two-character sequence `\` + `n` instead of
      // an actual newline (0x0A). Normalize here so rendering layers see a
      // real newline and wrap the text correctly. Also handle `\r\n` and
      // `\t` defensively for the same reason.
      content: _unescapeLiteralEscapes(json['content'] as String? ?? ''),
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
      enPayload: json['en_payload'] as Map<String, dynamic>?,
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

  /// Converts the literal two-character escape sequences `\n`, `\r\n` and
  /// `\t` (a backslash followed by `n` / `r` / `t`) into their actual
  /// control characters. Workaround for the chatbot double-escaping line
  /// breaks in its SSE payload.
  static String _unescapeLiteralEscapes(String s) {
    if (s.isEmpty) return s;
    return s
        .replaceAll(r'\r\n', '\n')
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\t', '\t');
  }
}
