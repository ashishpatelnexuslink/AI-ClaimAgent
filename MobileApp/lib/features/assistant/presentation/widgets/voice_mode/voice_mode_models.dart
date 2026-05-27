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
  /// Stable-English keyed payload (parallel to [payload]) for DB persistence
  /// on `save_summary` / `final_summary` turns. Null on older bot versions.
  final Map<String, dynamic>? enPayload;
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

  /// Set when `/validate-images` aborted with a TimeoutException. Renders a
  /// minimal bubble that shows only a "Try Again" button which re-fires the
  /// same request — no re-upload UI, no other failure messaging.
  final bool validationTimeoutRetry;

  /// Snapshot of the request that timed out, used to re-fire the exact same
  /// `/validate-images` call when the user taps "Try Again".
  final Map<String, String>? validationRetryImages;
  final String? validationRetryQuestion;
  final bool validationRetryIsLegacy;

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
    this.enPayload,
    this.imagePaths = const [],
    this.documentNames = const [],
    this.validationFailedAngles = const [],
    this.validationFailedLegacy = false,
    this.validationGroupKey,
    this.validationAllowedAngles = const [],
    this.validationTimeoutRetry = false,
    this.validationRetryImages,
    this.validationRetryQuestion,
    this.validationRetryIsLegacy = false,
  });
}

class SpeechEntry {
  final int messageIndex;
  final int totalChars;
  const SpeechEntry(this.messageIndex, this.totalChars);
}
