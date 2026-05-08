/// Shared data classes used by [VoiceModeScreen] and its extracted widgets.
class ChatMessage {
  final String text;
  final String type; // 'bot' or 'user'
  final List<String>? chips;
  final bool isTyping;
  final String messageType;
  final List<String> triggers;
  final Map<String, dynamic>? claimData;
  final String? payloadType;
  final Map<String, dynamic>? payload;
  final List<String> imagePaths;
  final List<String> documentNames;

  /// Angles flagged as `angle_matches: false` by `/validate-images`. When
  /// non-empty, the bot bubble renders a per-angle re-upload card.
  final List<String> validationFailedAngles;

  /// Set when `/validate-images` fails for the legacy free-form flow (no
  /// per-angle breakdown). Drives a single "Re-upload Photos" button in
  /// the failure bubble.
  final bool validationFailedLegacy;

  /// `group_key` echoed back by `/validate-images`. Scopes the failure card
  /// to a particular upload group (e.g. `vehicle_photos`).
  final String? validationGroupKey;

  /// Full set of allowed angles for this group, carried forward from the
  /// original GET_IMAGE trigger so retry submits can re-validate every angle
  /// (failed + previously valid) — `/validate-images` expects the complete
  /// batch on each call.
  final List<String> validationAllowedAngles;

  const ChatMessage({
    required this.text,
    required this.type,
    this.chips,
    this.isTyping = false,
    this.messageType = '',
    this.triggers = const [],
    this.claimData,
    this.payloadType,
    this.payload,
    this.imagePaths = const [],
    this.documentNames = const [],
    this.validationFailedAngles = const [],
    this.validationFailedLegacy = false,
    this.validationGroupKey,
    this.validationAllowedAngles = const [],
  });
}

class SpeechEntry {
  final int messageIndex;
  final int totalChars;
  const SpeechEntry(this.messageIndex, this.totalChars);
}
