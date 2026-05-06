import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import 'package:claim_ai/core/navigation/app_routes.dart';
import 'package:claim_ai/core/services/voice_service.dart';
import 'package:claim_ai/core/storage/chat_transcript_writer.dart';
import 'package:claim_ai/features/assistant/presentation/widgets/sample_images_dialog.dart';
import 'package:claim_ai/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:claim_ai/features/claims/presentation/cubit/claims_cubit.dart';
import 'package:claim_ai/features/claims/data/datasources/claims_remote_datasource.dart';
import 'package:claim_ai/injection_container.dart' as di;
import 'package:claim_ai/services/chat_service.dart';

// ─── Design Tokens ───────────────────────────────────────────────────────────
const _kBg = Color(0xFFF0F2F7);
const _kDark = Color(0xFF1A1D3B);
const _kBlue = Color(0xFF2A6FDB);
const _kRed = Color(0xFFE53935);
const _kUserInitialsBg = Color(0xFFE8E4FF);
const _kUserInitialsText = Color(0xFF6C5CE7);

// ─── Chat Message Model ─────────────────────────────────────────────────────
class _ChatMessage {
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

  const _ChatMessage({
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

class _SpeechEntry {
  final int messageIndex;
  final int totalChars;
  const _SpeechEntry(this.messageIndex, this.totalChars);
}

/// Running progress for a single GET_DOCUMENT trigger so the user can satisfy
/// `min_count` across multiple separate uploads.
class _DocTriggerProgress {
  int count = 0;
  final List<String> imagePaths = [];
  final List<String> docNames = [];
}

class VoiceModeScreen extends StatefulWidget {
  const VoiceModeScreen({super.key});

  @override
  State<VoiceModeScreen> createState() => _VoiceModeScreenState();
}

class _VoiceModeScreenState extends State<VoiceModeScreen>
    with TickerProviderStateMixin {
  // ─── State ──────────────────────────────────────────────────────────────
  final List<_ChatMessage> _messages = [];
  bool _isRecording = false;
  bool _botTyping = false;
  late final String _threadId;

  // Trigger UI state (mirrors claim_chat_screen).
  final TextEditingController _locationController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final List<File> _pickedImages = [];
  final int _maxImages = 4;
  // Dynamic per-angle flow driven by `payload.allowed_angles` — keyed by
  // angle name (e.g. "front_left"). Cleared after each successful submit.
  final Map<String, File> _angleImages = {};
  // For each angle that `/validate-images` flagged as invalid, the path of
  // the image at the time of failure. Used by the failure card to detect
  // when the user has picked a replacement (enabling re-submit). Cleared on
  // a successful validate + upload pass.
  final Map<String, String> _failedAnglePaths = {};
  // group_keys that have already validated + uploaded successfully in this
  // session. Disables Submit on any older failure card so a stale card can't
  // re-fire validation against an already-stored group.
  final Set<String> _uploadedGroupKeys = {};
  final List<PlatformFile> _pickedDocuments = [];
  final int _maxDocuments = 10;
  final List<String> _allowedDocExtensions = const [
    'pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx',
  ];
  final List<String> _uploadedDocumentIds = [];

  // Per-GET_DOCUMENT-trigger upload progress. Lets the user satisfy
  // `min_count` across multiple separate uploads instead of picking everything
  // at once. Cleared once the min is reached and the bot advances.
  final Map<_ChatMessage, _DocTriggerProgress> _docTriggerProgress = {};
  final List<DateTime> _messageTimestamps = [];
  String? _submittedClaimId;
  bool _fetchingLocation = false;
  bool _uploadingFiles = false;
  bool _submittingClaim = false;
  bool _closingConversation = false;
  bool _confirmingFinalSummary = false;
  // Claim/docs/conversation persisted server-side once the bot streams a
  // `save_summary` message. Close button only writes the local transcript
  // unless this flag is still false (then it falls back to a full save).
  bool _savedOnSummary = false;
  Future<void>? _autoSaveFuture;

  // GET_DATE_TIME trigger selection (nullable until user picks).
  DateTime? _dtDate;
  TimeOfDay? _dtTime;

  final ChatTranscriptWriter _transcriptWriter = di.sl<ChatTranscriptWriter>();

  // ─── Speech Recognition ──────────────────────────────────────────────────
  final VoiceService _voice = VoiceService();
  bool _voiceAvailable = false;
  String? _localeId;
  String _liveTranscript = '';

  // ─── Text-to-Speech (avatar voice) ──────────────────────────────────────
  final FlutterTts _tts = FlutterTts();
  bool _botSpeaking = false;

  // ─── Speech-synced typewriter ──────────────────────────────────────────
  // Bot bubbles reveal their text progressively, in sync with TTS playback,
  // so reading and listening stay aligned. We queue an entry per utterance
  // because flutter_tts queues replies (setQueueMode(1)) and only fires the
  // start handler when each one actually begins.
  final List<_SpeechEntry> _pendingSpeech = [];
  _SpeechEntry? _currentSpeech;
  int _spokenChars = 0;
  // Bot message indices that have been added to `_messages` but whose TTS
  // utterance hasn't started yet. The list view hides these so back-to-back
  // bot replies appear one at a time, in lockstep with what the avatar is
  // actually saying — no more "second bubble + buttons appear while the first
  // is still being typed out".
  final Set<int> _pendingRevealIndices = {};

  // ─── Auto-listen after bot finishes speaking ───────────────────────────
  Timer? _autoListenTimer;
  // Wait long enough for the TTS audio session / focus to release before we
  // start the recognizer. 600ms was too short on Android — the engine would
  // start "listening" while audio routing was still owned by TTS, so the mic
  // was deaf until the user manually re-tapped. 1500ms reliably hands over.
  static const Duration _autoListenDelay = Duration(milliseconds: 1500);

  // ─── Controllers ────────────────────────────────────────────────────────
  final TextEditingController _textController = TextEditingController();
  bool _hasDraftText = false;
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _pulseController;
  late final AnimationController _blinkController;
  late final AnimationController _typingController;
  late final AnimationController _speakController;

  @override
  void initState() {
    super.initState();
    _threadId = const Uuid().v4();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _speakController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _initVoice();
    _initTts();

    _textController.addListener(() {
      final hasText = _textController.text.trim().isNotEmpty;
      if (hasText != _hasDraftText) {
        setState(() => _hasDraftText = hasText);
      }
      // User is composing → don't auto-listen over them.
      if (hasText) _cancelAutoListen();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _streamBotReply('hello');
    });
  }

  Future<void> _initVoice() async {
    _voice
      ..onTextUpdate = _onVoiceTextUpdate
      ..onFinalText = _onVoiceFinalText
      ..onError = _onVoiceError
      ..onListeningChange = _onVoiceListeningChange;

    final ok = await _voice.initialize();
    _voiceAvailable = ok;
    if (ok) {
      _localeId = await _voice.resolveBestEnglishLocale();
    }
    if (mounted) setState(() {});
  }

  // ─── VoiceService callbacks ──────────────────────────────────────────────
  void _onVoiceTextUpdate(String liveText) {
    if (!mounted) return;
    setState(() => _liveTranscript = liveText);
  }

  void _onVoiceFinalText(String finalText) {
    if (!mounted) return;
    setState(() => _liveTranscript = '');
    _resetRecordingUi();
    final transcript = finalText.trim();
    if (transcript.isNotEmpty) {
      _handleVoiceInput(transcript);
    }
  }

  void _onVoiceError(String error) {
    if (!mounted) return;
    if (error == 'permission_denied') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Microphone permission is required for voice input'),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => openAppSettings(),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Voice error: $error')),
      );
    }
    _resetRecordingUi();
  }

  void _onVoiceListeningChange(bool isActive) {
    if (!mounted) return;
    setState(() => _isRecording = isActive);
    if (isActive) {
      _pulseController.repeat(reverse: true);
      _blinkController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.reset();
      _blinkController.stop();
      _blinkController.reset();
    }
  }

  Future<void> _initTts() async {
    // iOS-only: opt into a shared `playAndRecord` audio session so the mic
    // stays usable after TTS playback. flutter_tts defaults to `playback`,
    // which is exclusive — once it has been activated, SFSpeechRecognizer
    // can't acquire the input route, so on iPhone the listening UI silently
    // does nothing after the first bot reply.
    if (Platform.isIOS) {
      try {
        await _tts.setSharedInstance(true);
        await _tts.setIosAudioCategory(
          IosTextToSpeechAudioCategory.playAndRecord,
          [
            IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          ],
          IosTextToSpeechAudioMode.voicePrompt,
        );
      } catch (_) {
        // Older flutter_tts builds may lack one of these APIs — fall through
        // and accept whatever the default session is.
      }
    }
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(false);
    // Queue replies so back-to-back bot messages are spoken sequentially
    // (no-op on iOS, which queues by default).
    await _tts.setQueueMode(1);

    _tts.setStartHandler(() {
      if (!mounted) return;
      _cancelAutoListen();
      setState(() {
        _botSpeaking = true;
        _currentSpeech =
            _pendingSpeech.isNotEmpty ? _pendingSpeech.removeAt(0) : null;
        _spokenChars = 0;
        if (_currentSpeech != null) {
          _pendingRevealIndices.remove(_currentSpeech!.messageIndex);
        }
      });
      _speakController.repeat(reverse: true);
      // A queued bubble just became visible — keep it in view.
      _scrollToBottom();
    });
    _tts.setProgressHandler((text, start, end, word) {
      if (!mounted || _currentSpeech == null) return;
      setState(() => _spokenChars = end);
    });
    _tts.setCompletionHandler(() {
      if (!mounted) return;
      setState(() {
        _botSpeaking = false;
        _currentSpeech = null;
        _spokenChars = 0;
      });
      _speakController.stop();
      _speakController.reset();
      // Trigger widgets (date picker, upload card, final-summary card,
      // suggestion chips) only render once speech finishes — scroll so the
      // newly-revealed control is visible without a manual swipe.
      _scrollToBottom();
      _scheduleAutoListen();
    });
    _tts.setCancelHandler(() {
      if (!mounted) return;
      setState(() {
        _botSpeaking = false;
        _currentSpeech = null;
        _spokenChars = 0;
        _pendingSpeech.clear();
        // Reveal anything that was waiting on a now-cancelled utterance so
        // those bubbles don't stay hidden forever.
        _pendingRevealIndices.clear();
      });
      _speakController.stop();
      _speakController.reset();
    });
    _tts.setErrorHandler((_) {
      if (!mounted) return;
      setState(() {
        _botSpeaking = false;
        _currentSpeech = null;
        _spokenChars = 0;
        _pendingSpeech.clear();
        _pendingRevealIndices.clear();
      });
      _speakController.stop();
      _speakController.reset();
    });
  }

  /// Arm a timer to auto-start listening 5s after the bot finishes speaking.
  /// Skipped when the current turn expects a widget interaction (triggers
  /// like GET_IMAGE / GET_DATE_TIME / SUBMIT_CLAIM), the conversation is
  /// done, or the user is typing.
  void _scheduleAutoListen() {
    _cancelAutoListen();
    if (!_shouldAutoListen()) return;
    _autoListenTimer = Timer(_autoListenDelay, () {
      if (!mounted) return;
      if (!_shouldAutoListen()) return;
      _onMicTap();
    });
  }

  void _cancelAutoListen() {
    _autoListenTimer?.cancel();
    _autoListenTimer = null;
  }

  bool _shouldAutoListen() {
    if (_isRecording || _botTyping || _botSpeaking) return false;
    if (_hasDraftText) return false;
    final lastBotIdx = _lastBotIndex();
    if (lastBotIdx < 0) return false;
    final last = _messages[lastBotIdx];
    if (last.messageType == 'done') return false;
    // SHOW_TABLE is informational; GET_DATE_TIME and GET_LOCATION accept a
    // spoken answer (e.g. "yesterday at 9pm", "MG Road Pune") in addition to
    // their respective widgets, so we still auto-listen on those turns.
    // GET_IMAGE / GET_DOCUMENT / SUBMIT_CLAIM genuinely require widget
    // interaction.
    const voiceFriendlyTriggers = {
      'SHOW_TABLE',
      'GET_DATE_TIME',
      'GET_LOCATION',
    };
    final blockingTriggers = last.triggers
        .where((t) => !voiceFriendlyTriggers.contains(t))
        .toList();
    if (blockingTriggers.isNotEmpty) return false;
    return true;
  }

  String _sanitizeForSpeech(String text) {
    return text
        .replaceAll(RegExp(r'```[\s\S]*?```'), ' ')
        .replaceAll(RegExp(r'`([^`]*)`'), r'$1')
        .replaceAll(RegExp(r'!\[[^\]]*\]\([^)]*\)'), ' ')
        .replaceAll(RegExp(r'\[([^\]]*)\]\([^)]*\)'), r'$1')
        .replaceAll(RegExp(r'[*_#>~]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Refreshes the claims list + dashboard summary on the already-mounted
  /// HomePage. Voice mode is pushed on top of HomePage, so popping back
  /// doesn't re-run HomePage.initState — without this, the list stays in
  /// whatever state it was in when voice mode opened (often still loading).
  void _refreshClaimsList() {
    if (!mounted) return;
    try {
      final cubit = context.read<ClaimsCubit>();
      cubit.fetchClaims(refresh: true);
      cubit.fetchDashboardSummary();
    } catch (_) {
      // Cubit not in scope — nothing to refresh.
    }
  }

  Future<void> _speakBotReply(String text, {int? messageIndex}) async {
    final spoken = _sanitizeForSpeech(text);
    if (spoken.isEmpty) return;
    if (messageIndex != null) {
      _pendingSpeech.add(_SpeechEntry(messageIndex, spoken.length));
      _pendingRevealIndices.add(messageIndex);
    }
    await _tts.speak(spoken);
  }

  /// Returns the portion of [text] that should be visible right now, based on
  /// TTS playback progress for the bot bubble at [index]. While the utterance
  /// is being spoken, characters are revealed proportionally to the spoken-
  /// chars / total-chars ratio reported by flutter_tts. Bubbles that aren't
  /// currently being spoken render their full text.
  String _visibleBotText(int index, String text) {
    final cur = _currentSpeech;
    if (cur == null || cur.messageIndex != index || cur.totalChars <= 0) {
      return text;
    }
    final ratio = (_spokenChars / cur.totalChars).clamp(0.0, 1.0);
    final n = (text.length * ratio).ceil().clamp(0, text.length);
    return text.substring(0, n);
  }

  @override
  void dispose() {
    _cancelAutoListen();
    _voice.dispose();
    _tts.stop();
    _textController.dispose();
    _locationController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    _blinkController.dispose();
    _typingController.dispose();
    _speakController.dispose();
    super.dispose();
  }

  // ─── Messaging Helpers ──────────────────────────────────────────────────

  void _addUserAttachmentMessage({
    required String text,
    List<String> imagePaths = const [],
    List<String> documentNames = const [],
  }) {
    unawaited(_tts.stop());
    _cancelAutoListen();
    setState(() {
      _messages.add(_ChatMessage(
        text: text,
        type: 'user',
        imagePaths: imagePaths,
        documentNames: documentNames,
      ));
      _messageTimestamps.add(DateTime.now());
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    // User has moved on — cancel any in-flight/queued avatar speech so the
    // next bot reply is the only thing we speak. Without this, flutter_tts
    // keeps the prior utterance in its queue and the new reply either plays
    // late or gets swallowed (most visible on GET_DOCUMENT → Skip).
    unawaited(_tts.stop());
    _cancelAutoListen();
    setState(() {
      _messages.add(_ChatMessage(text: text, type: 'user'));
      _messageTimestamps.add(DateTime.now());
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── Flow Logic (API-based) ──────────────────────────────────────────────

  Future<void> _streamBotReply(String userMessage) async {
    setState(() {
      _botTyping = true;
      _messages.add(const _ChatMessage(
        text: '',
        type: 'bot',
        isTyping: true,
      ));
    });
    _scrollToBottom();

    // `AUTO_GET_LOCATION` is delivered mid-stream, while `_botTyping` is
    // still true. `_onUseCurrentLocation` bails on that flag, so we defer
    // the fetch until after the stream finishes.
    bool autoFetchLocation = false;

    try {
      await for (final msg in ChatService.sendMessage(
        userMessage,
        threadId: _threadId,
      )) {
        if (!mounted) return;
        setState(() {
          _messages.removeWhere((m) => m.isTyping);
          _messages.add(_ChatMessage(
            text: msg.content,
            type: 'bot',
            chips: msg.suggestions.isNotEmpty ? msg.suggestions : null,
            messageType: msg.messageType,
            triggers: msg.triggers,
            claimData: msg.claimData,
            payloadType: msg.payloadType,
            payload: msg.payload,
          ));
          _messageTimestamps.add(DateTime.now());
        });
        _scrollToBottom();
        final botIndex = _messages.length - 1;
        unawaited(_speakBotReply(msg.content, messageIndex: botIndex));
        // Bot has streamed the final summary — fire-and-forget the save so
        // the Close button only has to write the local transcript file.
        if (msg.payloadType == 'save_summary') {
          _triggerAutoSaveOnSummary(msg.payload, msg.content);
        }
        if (msg.triggers.contains('AUTO_GET_LOCATION')) {
          autoFetchLocation = true;
        }
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m.isTyping);
        _messages.add(const _ChatMessage(
          text: 'Sorry, something went wrong. Please try again.',
          type: 'bot',
        ));
        _messageTimestamps.add(DateTime.now());
      });
    }

    if (!mounted) return;
    setState(() {
      _messages.removeWhere((m) => m.isTyping);
      _botTyping = false;
    });
    _scrollToBottom();

    if (autoFetchLocation) {
      unawaited(_onUseCurrentLocation());
    }
  }

  void _handleChipSelection(String value) {
    if (_botTyping) return;
    _addUserMessage(value);
    _streamBotReply(value);
  }

  void _handleVoiceInput(String transcript) {
    if (_botTyping) return;
    _addUserMessage(transcript);
    _streamBotReply(transcript);
  }

  /// Time the TTS audio session needs to fully release after `_tts.stop()`
  /// before we can reliably grab the mic. Without this brief gap, Android
  /// hands the recognizer an engine that's nominally listening but receives
  /// no audio (TTS still owns audio focus).
  static const Duration _postTtsStopDelay = Duration(milliseconds: 300);

  Future<void> _onMicTap() async {
    if (_botTyping) return;

    _cancelAutoListen();

    if (_botSpeaking) {
      await _tts.stop();
      await Future.delayed(_postTtsStopDelay);
    }

    if (_voice.isListening) {
      await _voice.stop();
      return;
    }

    if (!_voiceAvailable) {
      await _initVoice();
      if (!_voiceAvailable) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Microphone permission is required for voice input'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        return;
      }
    }

    await _voice.start(localeId: _localeId ?? 'en_IN');
  }

  void _resetRecordingUi() {
    if (!mounted) return;
    setState(() {
      _isRecording = false;
    });
    _pulseController.stop();
    _pulseController.reset();
    _blinkController.stop();
    _blinkController.reset();
  }

  void _stopRecordingAndSubmit() {
    _voice.stop();
  }

  /// Wipe the in-progress transcript without leaving listening mode, so the
  /// user can start over after misspeaking. The silence clock is reset too.
  void _onDeleteTranscript() {
    _voice.resetTranscript();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // SUMMARY CARD HELPERS (verified_summary / final_summary / policy)
  // ═════════════════════════════════════════════════════════════════════════

  static const _tablePayloadTypes = {
    'initial_summary',
    'verified_summary',
    'final_summary',
    'save_summary',
  };

  Map<String, String>? _tableFields(_ChatMessage msg) {
    if (!_tablePayloadTypes.contains(msg.payloadType)) return null;
    final payload = msg.payload;
    if (payload == null || payload.isEmpty) return null;

    final fields = <String, String>{};
    payload.forEach((key, value) {
      if (value == null) return;
      fields[key] = _formatFieldValue(key, value);
    });
    return fields.isEmpty ? null : fields;
  }

  String _cardTitleFor(String? payloadType) {
    switch (payloadType) {
      case 'initial_summary':
        return 'Initial Summary';
      case 'final_summary':
        return 'Claim Summary';
      case 'save_summary':
        return 'Saved Claim Summary';
      case 'verified_summary':
      default:
        return 'Policy Verified';
    }
  }

  String _formatFieldValue(String key, dynamic value) {
    final raw = value.toString().trim();
    if (raw.isEmpty) return '';
    final iso = RegExp(r'^\d{4}-\d{2}-\d{2}').firstMatch(raw);
    if (iso != null) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) return DateFormat('d MMM, yyyy').format(parsed);
    }
    return raw;
  }

  static final _policyFieldPattern = RegExp(r'\*\*(.+?):\*\*\s*(.+)');

  Map<String, String>? _parsePolicyFields(String text) {
    final matches = _policyFieldPattern.allMatches(text).toList();
    if (matches.length < 4) return null;
    final fields = <String, String>{};
    for (final m in matches) {
      fields[m.group(1)!.trim()] = m.group(2)!.trim();
    }
    final keys = fields.keys.map((k) => k.toLowerCase()).toSet();
    if (!keys.contains('policy holder') && !keys.contains('policyholder')) {
      return null;
    }
    if (!keys.any((k) => k.contains('policy') && k.contains('number'))) {
      return null;
    }
    return fields;
  }

  String _policyIntroText(String text) {
    final lines = text.split('\n');
    final buffer = StringBuffer();
    for (final line in lines) {
      if (_policyFieldPattern.hasMatch(line)) break;
      final trimmed = line.trim();
      if (trimmed.isNotEmpty) {
        if (buffer.isNotEmpty) buffer.write(' ');
        buffer.write(trimmed);
      }
    }
    return buffer.toString();
  }

  // ═════════════════════════════════════════════════════════════════════════
  // TRIGGER HANDLERS
  // ═════════════════════════════════════════════════════════════════════════

  /// GET_DATE_TIME — open the native date picker and store selection.
  Future<void> _pickIncidentDate() async {
    if (_botTyping) return;
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final initial = _dtDate ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _kBlue),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;
    setState(() => _dtDate = date);
  }

  Future<void> _pickIncidentTime() async {
    if (_botTyping) return;
    FocusScope.of(context).unfocus();
    final initial = _dtTime ?? TimeOfDay.fromDateTime(DateTime.now());
    final time = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _kBlue),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;
    setState(() => _dtTime = time);
  }

  void _confirmIncidentDateTime() {
    if (_botTyping) return;
    final now = DateTime.now();
    final date = _dtDate ?? now;
    final time = _dtTime ?? TimeOfDay.fromDateTime(now);
    final selected =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    final formatted = DateFormat('dd MMM yyyy, hh:mm a').format(selected);
    setState(() {
      _dtDate = null;
      _dtTime = null;
    });
    _addUserMessage(formatted);
    _streamBotReply(formatted);
  }

  // ── GET_LOCATION ─────────────────────────────────────────────────────────
  void _onSubmitLocation() {
    final text = _locationController.text.trim();
    if (text.isEmpty || _botTyping) return;
    _locationController.clear();
    _sendLocationReply(text);
  }

  Future<void> _onUseCurrentLocation() async {
    if (_botTyping || _fetchingLocation) return;
    setState(() => _fetchingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Please enable location services (GPS) in device settings'),
          ),
        );
        await Geolocator.openLocationSettings();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required')),
        );
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Location permission is permanently denied. Please enable it in app settings.'),
          ),
        );
        await Geolocator.openAppSettings();
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      String address;
      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final parts = <String>[
            if (p.subLocality != null && p.subLocality!.isNotEmpty)
              p.subLocality!,
            if (p.locality != null && p.locality!.isNotEmpty) p.locality!,
            if (p.administrativeArea != null &&
                p.administrativeArea!.isNotEmpty)
              p.administrativeArea!,
          ];
          address = parts.isNotEmpty
              ? parts.join(', ')
              : '${position.latitude}, ${position.longitude}';
        } else {
          address = '${position.latitude}, ${position.longitude}';
        }
      } catch (_) {
        address = '${position.latitude}, ${position.longitude}';
      }

      if (!mounted) return;
      _sendLocationReply(address);
    } on LocationServiceDisabledException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled')),
      );
    } on PermissionDeniedException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission was denied')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get location: $e')),
      );
    } finally {
      if (mounted) setState(() => _fetchingLocation = false);
    }
  }

  void _sendLocationReply(String location) {
    _addUserMessage(location);
    _streamBotReply(location);
  }

  // ── GET_IMAGE ────────────────────────────────────────────────────────────
  Future<void> _onPickImages() async {
    if (_pickedImages.length >= _maxImages) return;
    final remaining = _maxImages - _pickedImages.length;
    final images = await _imagePicker.pickMultiImage(
      imageQuality: 80,
      limit: remaining,
    );
    if (images.isEmpty || !mounted) return;

    setState(() {
      for (final img in images) {
        if (_pickedImages.length >= _maxImages) break;
        _pickedImages.add(File(img.path));
      }
    });
    _scrollToBottom();
  }

  void _onRemoveImage(int index) {
    setState(() => _pickedImages.removeAt(index));
  }

  // ── Per-angle GET_IMAGE handlers (driven by `payload.allowed_angles`) ──

  Future<void> _onPickAngleImage(String angle) async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null || !mounted) return;
    setState(() => _angleImages[angle] = File(picked.path));
    _scrollToBottom();
  }

  void _onRemoveAngleImage(String angle) {
    setState(() => _angleImages.remove(angle));
  }

  Future<void> _onSubmitAngleImages({_ChatMessage? originatingMsg}) async {
    if (_angleImages.isEmpty || _botTyping || _uploadingFiles) return;

    // Resolve the group_key for THIS submission. Priority:
    //   1. validationGroupKey on the originating failure card.
    //   2. Keyword scan on the originating GET_IMAGE trigger's bot text.
    //   3. Walk-back inference (legacy fallback).
    String category;
    if (originatingMsg?.validationGroupKey != null &&
        originatingMsg!.validationGroupKey!.isNotEmpty) {
      category = originatingMsg.validationGroupKey!;
    } else if (originatingMsg != null && originatingMsg.text.isNotEmpty) {
      category = _inferCategoryFromText(originatingMsg.text, isImage: true);
    } else {
      category = _inferCategory(isImage: true);
    }

    // Block re-submission of a group that already validated + uploaded.
    if (_uploadedGroupKeys.contains(category)) {
      debugPrint(
        '[Validate] skipping re-submit for already-uploaded group: $category',
      );
      return;
    }

    // Scope the entries to the full allowed-angles set for this card. On a
    // retry, the failure card carries `validationAllowedAngles` (forwarded
    // from the original GET_IMAGE trigger) so we always send the complete
    // batch — newly replaced angles + previously valid ones — to
    // `/validate-images`. Sending only failed angles would have the AI
    // re-validate a partial set, which the agent rejects.
    final List<String> allowedAngles =
        (originatingMsg?.validationAllowedAngles.isNotEmpty ?? false)
        ? originatingMsg!.validationAllowedAngles
        : (originatingMsg != null ? _allowedAnglesOf(originatingMsg) : const []);
    final List<String>? scopedAngles =
        allowedAngles.isEmpty ? null : allowedAngles;
    final entries = scopedAngles == null
        ? _angleImages.entries.toList(growable: false)
        : _angleImages.entries
              .where((e) => scopedAngles.contains(e.key))
              .toList(growable: false);
    if (entries.isEmpty) return;
    setState(() => _uploadingFiles = true);

    // Read bytes once; reused for both upload + validation.
    final List<({String angle, String name, Uint8List bytes, String path})>
        prepared = [];
    for (final entry in entries) {
      final bytes = await entry.value.readAsBytes();
      final name = entry.value.path.split(RegExp(r'[\\/]')).last;
      prepared.add((
        angle: entry.key,
        name: name.isEmpty ? 'image.jpg' : name,
        bytes: bytes,
        path: entry.value.path,
      ));
    }

    // ── Validate first (AI image validation) ───────────────────────────
    // Only `vehicle_photos` goes through `/validate-images` — every other
    // group (damage_photos, driver_license, …) uploads directly.
    if (category == 'vehicle_photos') {
      final validation = await _runImageValidation(
        questionLabel: category,
        images: {
          for (final p in prepared) p.angle: base64Encode(p.bytes),
        },
        allowedAngles: allowedAngles,
      );
      if (!validation.valid) {
        if (!mounted) return;
        setState(() => _uploadingFiles = false);
        return;
      }
    }

    int uploadedCount = 0;
    try {
      final ds = di.sl<ClaimsRemoteDataSource>();
      for (final p in prepared) {
        final response = await ds.uploadClaimDocument(
          bytes: p.bytes,
          fileName: p.name,
          kind: 'Image',
          groupKey: category,
          chatThreadId: _threadId,
          angle: p.angle,
        );
        final id = (response['id'] ?? '').toString();
        if (id.isNotEmpty) {
          _uploadedDocumentIds.add(id);
          uploadedCount++;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed: $e')),
        );
      }
      debugPrint('[Upload] angle image upload failed: $e');
    }

    if (!mounted) return;
    final count = uploadedCount == 0 ? entries.length : uploadedCount;
    final paths = prepared.map((p) => p.path).toList();
    setState(() {
      // Drop only the angles we just uploaded — preserves any picks the user
      // may have made for a different group's still-open card.
      for (final p in prepared) {
        _angleImages.remove(p.angle);
      }
      _uploadedGroupKeys.add(category);
      _uploadingFiles = false;
    });
    _addUserAttachmentMessage(
      text: '$count photo${count > 1 ? 's' : ''} uploaded',
      imagePaths: paths,
    );
    _streamBotReply(count.toString());
  }

  /// POSTs the picked images to `/validate-images` and renders a transient
  /// "validating…" bot bubble. On success the bubble is removed; on failure
  /// it's swapped for a per-angle re-upload card. Returns the validation
  /// result so callers can decide whether to continue with the upload + chat.
  Future<ImageValidationResult> _runImageValidation({
    required String questionLabel,
    required Map<String, String> images,
    bool isLegacy = false,
    List<String> allowedAngles = const [],
  }) async {
    final waitingMsg = _ChatMessage(
      text: 'Please wait while we validate your images...',
      type: 'bot',
    );
    setState(() => _messages.add(waitingMsg));
    _scrollToBottom();

    ImageValidationResult result;
    try {
      result = await ChatService.validateImages(
        questionLabel: questionLabel,
        threadId: _threadId,
        images: images,
      );
    } catch (e) {
      debugPrint('[Validate] image validation failed: $e');
      result = ImageValidationResult(
        valid: false,
        failureReason: 'Could not validate images. Please try again.',
      );
    }

    if (!mounted) return result;

    final failedAngles = result.invalidAngles;

    setState(() {
      _messages.remove(waitingMsg);
      if (!result.valid) {
        // Snapshot the rejected paths so the failure card can detect when
        // the user picks a replacement (re-enabling Submit). The picked
        // images themselves stay in `_angleImages` so their thumbnails
        // remain visible alongside the per-angle error status.
        _failedAnglePaths.clear();
        for (final a in failedAngles) {
          final f = _angleImages[a];
          if (f != null) _failedAnglePaths[a] = f.path;
        }
        final useLegacy = isLegacy || failedAngles.isEmpty;
        _messages.add(
          _ChatMessage(
            text: useLegacy
                ? 'Image validation failed. Please re-upload.'
                : '',
            type: 'bot',
            validationFailedAngles: useLegacy ? const [] : failedAngles,
            validationFailedLegacy: useLegacy,
            validationGroupKey: result.groupKey,
            validationAllowedAngles: allowedAngles,
          ),
        );
      } else {
        _failedAnglePaths.clear();
      }
    });
    _scrollToBottom();
    return result;
  }

  /// Re-renders the same legacy GET_IMAGE trigger card inside the failure
  /// bubble so the user can remove rejected images, add more, and resubmit.
  /// `_pickedImages` is preserved on validation failure, so the originally
  /// rejected thumbnails stay visible until the user edits them.
  Widget _buildLegacyValidationFailure() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: _buildLegacyImageTrigger(),
    );
  }

  /// Renders the validation-failure card: header, one row per failed angle
  /// (thumbnail of the rejected/replacement image, label, status, Upload or
  /// Replace button), and a Submit button that re-runs the validate + upload
  /// flow once every failed angle has a replacement.
  Widget _buildValidationFailureList(_ChatMessage msg, List<String> angles) {
    bool isStillRejected(String a) =>
        _failedAnglePaths[a] != null &&
        _angleImages[a]?.path == _failedAnglePaths[a];
    final allReplaced = angles.every((a) => !isStillRejected(a));
    // Once this card's group has been validated + uploaded, freeze its Submit
    // so a stale card can't re-fire validation against an already-stored group.
    final groupAlreadyDone =
        msg.validationGroupKey != null &&
        _uploadedGroupKeys.contains(msg.validationGroupKey);
    final canSubmit =
        allReplaced && !_uploadingFiles && !_botTyping && !groupAlreadyDone;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Some images need to be re-uploaded',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFFB00020),
            ),
          ),
          const SizedBox(height: 8),
          ...angles.map((angle) {
            final picked = _angleImages[angle];
            final stillRejected = isStillRejected(angle);
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  if (picked != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        picked,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ] else ...[
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.grey.shade500,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _humanizeAngle(angle),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _kDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          stillRejected
                              ? '${_humanizeAngle(angle)} does not match the required view. Please re-upload.'
                              : 'Ready to submit',
                          style: TextStyle(
                            fontSize: 11,
                            color: stillRejected
                                ? const Color(0xFFB00020)
                                : _kBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _uploadingFiles
                        ? null
                        : () => _onPickAngleImage(angle),
                    icon: Icon(
                      stillRejected
                          ? Icons.camera_alt_outlined
                          : Icons.refresh,
                      size: 16,
                    ),
                    label: Text(
                      stillRejected ? 'Upload' : 'Replace',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: _kBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canSubmit
                  ? () => _onSubmitAngleImages(originatingMsg: msg)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade600,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _uploadingFiles
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Submit',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSubmitImages() async {
    debugPrint('[Upload] _onSubmitImages enter '
        'picked=${_pickedImages.length} '
        'botTyping=$_botTyping uploading=$_uploadingFiles');
    if (_pickedImages.isEmpty || _botTyping || _uploadingFiles) {
      debugPrint('[Upload] _onSubmitImages BAILED (guard)');
      return;
    }

    final files = List<File>.from(_pickedImages);
    setState(() => _uploadingFiles = true);

    final category = _inferCategory(isImage: true);

    // Read bytes once; reused for validate + upload.
    final List<({String name, Uint8List bytes, String path})> prepared = [];
    for (final file in files) {
      final bytes = await file.readAsBytes();
      final name = file.path.split(RegExp(r'[\\/]')).last;
      prepared.add((
        name: name.isEmpty ? 'image.jpg' : name,
        bytes: bytes,
        path: file.path,
      ));
    }

    // Only `vehicle_photos` runs through AI validation; every other group
    // uploads directly.
    if (category == 'vehicle_photos') {
      final validation = await _runImageValidation(
        questionLabel: category,
        images: {
          for (var i = 0; i < prepared.length; i++)
            'image_$i': base64Encode(prepared[i].bytes),
        },
        isLegacy: true,
      );
      if (!validation.valid) {
        if (!mounted) return;
        setState(() => _uploadingFiles = false);
        return;
      }
    }

    int uploadedCount = 0;
    try {
      final ds = di.sl<ClaimsRemoteDataSource>();
      for (final p in prepared) {
        final response = await ds.uploadClaimDocument(
          bytes: p.bytes,
          fileName: p.name,
          kind: 'Image',
          groupKey: category,
          chatThreadId: _threadId,
        );
        final id = (response['id'] ?? '').toString();
        if (id.isNotEmpty) {
          _uploadedDocumentIds.add(id);
          uploadedCount++;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image upload failed: $e')),
        );
      }
      debugPrint('[Upload] image upload failed: $e');
    }

    if (!mounted) return;
    final count = uploadedCount == 0 ? prepared.length : uploadedCount;
    final paths = prepared.map((p) => p.path).toList();
    setState(() {
      _pickedImages.clear();
      _uploadingFiles = false;
    });
    debugPrint('[Upload] images submit → uploadedCount=$uploadedCount '
        'fallbackCount=${files.length} sending="${count.toString()}"');
    _addUserAttachmentMessage(
      text: '$count photo${count > 1 ? 's' : ''} uploaded',
      imagePaths: paths,
    );
    _streamBotReply(count.toString());
  }

  // ── GET_DOCUMENT ─────────────────────────────────────────────────────────
  Future<void> _onPickDocuments() async {
    if (_pickedDocuments.length >= _maxDocuments) return;

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: _allowedDocExtensions,
    );
    if (result == null || !mounted) return;

    setState(() {
      for (final file in result.files) {
        if (_pickedDocuments.length >= _maxDocuments) break;
        _pickedDocuments.add(file);
      }
    });
    _scrollToBottom();
  }

  void _onRemoveDocument(int index) {
    setState(() => _pickedDocuments.removeAt(index));
  }

  Future<void> _onSubmitDocuments(_ChatMessage msg) async {
    debugPrint('[Upload] _onSubmitDocuments enter '
        'picked=${_pickedDocuments.length} '
        'botTyping=$_botTyping uploading=$_uploadingFiles');
    if (_pickedDocuments.isEmpty || _botTyping || _uploadingFiles) {
      debugPrint('[Upload] _onSubmitDocuments BAILED (guard)');
      return;
    }

    final docs = List<PlatformFile>.from(_pickedDocuments);
    final progress =
        _docTriggerProgress.putIfAbsent(msg, () => _DocTriggerProgress());
    final minCount = _payloadInt(msg, 'min_count') ?? 1;
    setState(() => _uploadingFiles = true);

    int uploadedCount = 0;
    try {
      final ds = di.sl<ClaimsRemoteDataSource>();
      final category = _inferCategory(isImage: false);
      for (final doc in docs) {
        List<int> bytes;
        if (doc.bytes != null) {
          bytes = doc.bytes!;
        } else if (doc.path != null) {
          bytes = await File(doc.path!).readAsBytes();
        } else {
          continue;
        }
        final response = await ds.uploadClaimDocument(
          bytes: bytes,
          fileName: doc.name,
          kind: 'Document',
          groupKey: category,
          chatThreadId: _threadId,
        );
        final id = (response['id'] ?? '').toString();
        if (id.isNotEmpty) {
          _uploadedDocumentIds.add(id);
          uploadedCount++;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document upload failed: $e')),
        );
      }
      debugPrint('[Upload] document upload failed: $e');
    }

    if (!mounted) return;
    final batchCount = uploadedCount == 0 ? docs.length : uploadedCount;
    for (final d in docs) {
      final ext = d.extension?.toLowerCase() ?? '';
      final isImage = const {'jpg', 'jpeg', 'png'}.contains(ext);
      if (isImage && d.path != null) {
        progress.imagePaths.add(d.path!);
      } else {
        progress.docNames.add(d.name);
      }
    }
    progress.count += batchCount;

    // Below `min_count` — keep the trigger card visible so the user can
    // upload another batch. No user bubble yet; the trigger UI shows progress.
    if (progress.count < minCount) {
      setState(() {
        _pickedDocuments.clear();
        _uploadingFiles = false;
      });
      return;
    }

    final total = progress.count;
    final imagePaths = List<String>.from(progress.imagePaths);
    final docNames = List<String>.from(progress.docNames);
    if (imagePaths.isEmpty && docNames.isEmpty) {
      docNames.addAll(docs.map((d) => d.name));
    }
    _docTriggerProgress.remove(msg);
    setState(() {
      _pickedDocuments.clear();
      _uploadingFiles = false;
    });
    debugPrint('[Upload] docs submit → uploadedCount=$uploadedCount '
        'fallbackCount=${docs.length} sending="${total.toString()}"');
    _addUserAttachmentMessage(
      text: '$total document${total > 1 ? 's' : ''} uploaded',
      imagePaths: imagePaths,
      documentNames: docNames,
    );
    _streamBotReply(total.toString());
  }

  void _onSkipDocuments() {
    if (_botTyping) return;
    setState(() => _pickedDocuments.clear());
    _addUserMessage('Skip');
    _streamBotReply('Skip');
  }

  // ── Confirm & Submit Claim (final_summary card) ─────────────────────────
  Future<void> _onConfirmFinalSummary(_ChatMessage msg) async {
    if (_confirmingFinalSummary || _botTyping) return;
    setState(() => _confirmingFinalSummary = true);

    String? errorMessage;
    try {
      await _runSaveClaimAndConversation(
        saveSummaryPayload: msg.payload,
      );
      _savedOnSummary = true;
    } catch (e) {
      errorMessage = 'Failed to save claim: $e';
      debugPrint('[ConfirmFinalSummary] save failed: $e');
    }

    if (!mounted) return;
    setState(() => _confirmingFinalSummary = false);

    if (errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    const reply = 'Yes Confirm';
    _addUserMessage(reply);
    _streamBotReply(reply);
  }

  // ── SUBMIT_CLAIM ─────────────────────────────────────────────────────────
  Future<void> _onSubmitClaim(Map<String, dynamic> claimData) async {
    if (_submittingClaim) return;
    setState(() => _submittingClaim = true);

    try {
      final payload = {
        ...claimData,
        'chatThreadId': _threadId,
      };
      final dataSource = di.sl<ClaimsRemoteDataSource>();
      final response = await dataSource.createClaim(payload);

      if (!mounted) return;
      final claimNumber = response['claimNumber'] as String? ?? '';
      _submittedClaimId =
          (response['id'] ?? response['claimId'] ?? claimNumber).toString();

      setState(() {
        _messages.add(_ChatMessage(
          text: 'Claim **$claimNumber** has been submitted successfully!',
          type: 'bot',
        ));
        _messageTimestamps.add(DateTime.now());
        _submittingClaim = false;
      });
      _scrollToBottom();
      unawaited(_speakBotReply('Claim $claimNumber has been submitted successfully.'));
      _refreshClaimsList();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(const _ChatMessage(
          text: 'Failed to submit claim. Please try again.',
          type: 'bot',
        ));
        _messageTimestamps.add(DateTime.now());
        _submittingClaim = false;
      });
      _scrollToBottom();
    }
  }

  // ── Close conversation (message_type == 'done') ─────────────────────────
  static final _claimRefPattern = RegExp(
    r'([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})',
  );

  String? _extractClaimReference(String text) {
    final match = _claimRefPattern.firstMatch(text);
    return match?.group(1);
  }

  Map<String, dynamic>? _latestClaimData() {
    for (int i = _messages.length - 1; i >= 0; i--) {
      final data = _messages[i].claimData;
      if (data != null && data.isNotEmpty) return data;
    }
    return null;
  }

  Map<String, dynamic>? _latestSaveSummaryPayload() {
    for (int i = _messages.length - 1; i >= 0; i--) {
      final m = _messages[i];
      if (m.messageType == 'done' &&
          m.payloadType == 'save_summary' &&
          m.payload != null &&
          m.payload!.isNotEmpty) {
        return m.payload;
      }
    }
    return null;
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  DateTime? _combineIncidentDateTime(String? dateRaw, String? timeRaw) {
    if (dateRaw == null || dateRaw.trim().isEmpty) return null;
    DateTime? date;
    for (final pattern in const ['dd-MM-yyyy', 'd-M-yyyy', 'yyyy-MM-dd']) {
      try {
        date = DateFormat(pattern).parseStrict(dateRaw.trim());
        break;
      } catch (_) {}
    }
    date ??= DateTime.tryParse(dateRaw.trim());
    if (date == null) return null;
    if (timeRaw == null || timeRaw.trim().isEmpty) return date;
    for (final pattern in const ['hh:mm a', 'h:mm a', 'HH:mm']) {
      try {
        final t = DateFormat(pattern).parseStrict(timeRaw.trim());
        return DateTime(date.year, date.month, date.day, t.hour, t.minute);
      } catch (_) {}
    }
    return date;
  }

  Map<String, dynamic> _mapSaveSummaryToDto(Map<String, dynamic> summary) {
    final mapped = <String, dynamic>{};
    String? incidentDateRaw;
    String? incidentTimeRaw;

    summary.forEach((key, value) {
      if (value == null) return;
      switch (key.toLowerCase().trim()) {
        case 'policy number':
          mapped['policyNumber'] = value; break;
        case 'policy holder':
        case 'policyholder':
        case 'full name':
        case 'name':
          mapped['fullName'] = value; break;
        case 'plat number':
        case 'plate number':
        case 'vehicle number':
        case 'vehicle registration number':
        case 'registration number':
          mapped['vehicleNumber'] = value;
          mapped['vehicleRegistrationNumber'] = value;
          break;
        case 'vin':
        case 'vin number':
        case 'vehicle identification number':
          mapped['vinNumber'] = value; break;
        case 'vehicle':
        case 'vehicle model':
          mapped['vehicleModel'] = value; break;
        case 'coverage':
        case 'coverage type':
          mapped['coverageType'] = value; break;
        case 'status':
        case 'policy status':
          mapped['policyStatus'] = value; break;
        case 'valid until':
        case 'policy valid until':
          {
            final parsed = DateTime.tryParse(value.toString());
            if (parsed != null) {
              mapped['policyValidUntil'] = parsed.toUtc().toIso8601String();
            } else {
              mapped[key] = value;
            }
          }
          break;
        case 'claim type': mapped['claimType'] = value.toString(); break;
        case 'incident date':
        case 'date': incidentDateRaw = value.toString(); break;
        case 'incident time':
        case 'time': incidentTimeRaw = value.toString(); break;
        case 'incident location':
        case 'location': mapped['incidentLocation'] = value; break;
        case 'incident description':
        case 'damage details':
        case 'description':
          mapped['incidentDescription'] = value;
          mapped['description'] = value;
          break;
        case 'claim amount':
        case 'amount':
          if (value is num) {
            mapped['amount'] = value;
          } else {
            final parsed = num.tryParse(value.toString());
            if (parsed != null) mapped['amount'] = parsed;
          }
          break;
        case 'vehicle photos':
        case 'vehicle photos count':
          mapped['vehiclePhotosCount'] = _extractCount(value); break;
        case 'damage photos':
        case 'damage photos count':
          mapped['damagePhotosCount'] = _extractCount(value); break;
        case 'driver license':
        case 'driving license':
        case 'license photos':
        case 'license photos count':
          mapped['licensePhotosCount'] = _extractCount(value); break;
        case 'police report':
        case 'police report count':
          mapped['policeReportCount'] = _extractCount(value); break;
        case 'repair bill':
        case 'bill invoice':
        case 'invoice':
        case 'invoice count':
        case 'repair bill count':
          mapped['repairBillCount'] = _extractCount(value); break;
        case 'supporting docs':
        case 'supporting documents':
          mapped[key] = _extractCount(value); break;
        default: mapped[key] = value;
      }
    });

    final combinedIncident =
        _combineIncidentDateTime(incidentDateRaw, incidentTimeRaw);
    if (combinedIncident != null) {
      mapped['incidentDate'] = combinedIncident.toUtc().toIso8601String();
    } else {
      if (incidentDateRaw != null) mapped['Incident Date'] = incidentDateRaw;
      if (incidentTimeRaw != null) mapped['Incident Time'] = incidentTimeRaw;
    }
    return mapped;
  }

  String _inferCategory({required bool isImage}) {
    // Walk back to the most recent bot message that actually carries content
    // — skip empty validation-failure bubbles so the inference doesn't get
    // pulled to its default by a per-angle failure card.
    String text = '';
    for (int i = _messages.length - 1; i >= 0; i--) {
      final m = _messages[i];
      if (m.type != 'bot') continue;
      if (m.validationFailedAngles.isNotEmpty || m.validationFailedLegacy) {
        continue;
      }
      if (m.text.trim().isEmpty) continue;
      text = m.text;
      break;
    }
    return _inferCategoryFromText(text, isImage: isImage);
  }

  String _inferCategoryFromText(String raw, {required bool isImage}) {
    final text = raw.toLowerCase();
    if (text.contains('damage')) return 'damage_photos';
    if (text.contains('license') || text.contains('licence')) {
      return 'driver_license';
    }
    if (text.contains('police')) return 'police_report';
    if (text.contains('repair') ||
        text.contains('bill') ||
        text.contains('invoice')) {
      return 'bill_invoice';
    }
    if (text.contains('vehicle') || text.contains('car')) {
      return isImage ? 'vehicle_photos' : 'supporting_docs';
    }
    return isImage ? 'vehicle_photos' : 'supporting_docs';
  }

  /// Fire-and-forget auto-save invoked the moment the bot streams a message
  /// with `payload_type == "save_summary"`. Idempotent — only the first call
  /// per session does any work; the Close button awaits [_autoSaveFuture]
  /// so it won't race-create a duplicate claim.
  void _triggerAutoSaveOnSummary(
      Map<String, dynamic>? saveSummaryPayload, String doneText) {
    if (_savedOnSummary || _autoSaveFuture != null) return;
    final externalRef = _extractClaimReference(doneText);
    final future = _runSaveClaimAndConversation(
      saveSummaryPayload: saveSummaryPayload,
      externalRef: externalRef,
    );
    _autoSaveFuture = future;
    future.then((_) {
      _savedOnSummary = true;
    }).catchError((Object e) {
      debugPrint('[AutoSave] save_summary save failed (will retry on Close): $e');
      _autoSaveFuture = null;
    });
  }

  /// Performs the full server-side save: create claim row (if not already
  /// created via SUBMIT_CLAIM) and attach uploaded documents. Throws on any
  /// step failure.
  Future<void> _runSaveClaimAndConversation({
    Map<String, dynamic>? saveSummaryPayload,
    String? externalRef,
  }) async {
    String? finalClaimId = _submittedClaimId;

    if (finalClaimId == null || finalClaimId.isEmpty) {
      final claimData = _latestClaimData() ?? <String, dynamic>{};
      final saveSummary = saveSummaryPayload ?? _latestSaveSummaryPayload();
      final summaryFields = saveSummary != null
          ? _mapSaveSummaryToDto(saveSummary)
          : <String, dynamic>{};
      final payload = <String, dynamic>{
        ...claimData,
        ...summaryFields,
        'chatThreadId': _threadId,
        'externalReference': ?externalRef,
      };
      final response = await di
          .sl<ClaimsRemoteDataSource>()
          .createClaimFromChat(payload);
      final created = (response['id'] ?? response['claimId'] ?? '').toString();
      if (created.isEmpty) {
        throw Exception('Claim created but backend returned no id.');
      }
      finalClaimId = created;
      _submittedClaimId = finalClaimId;
    }

    if (_uploadedDocumentIds.isNotEmpty) {
      await di.sl<ClaimsRemoteDataSource>().attachClaimDocuments(
            claimId: finalClaimId,
            documentIds: List<String>.from(_uploadedDocumentIds),
          );
    }
  }

  Future<void> _onCloseConversation(_ChatMessage doneMsg) async {
    if (_closingConversation) return;
    setState(() => _closingConversation = true);

    String? errorMessage;

    try {
      // Always write the local transcript file. The server-side save is
      // normally already done from the `save_summary` streaming hook above;
      // we only retry it here when that auto-save failed or never fired.
      try {
        await _transcriptWriter.writeTranscript(
          threadId: _threadId,
          claimId: _submittedClaimId,
          messages: [
            for (var i = 0; i < _messages.length; i++)
              if (!_messages[i].isTyping)
                TranscriptMessage(
                  role: _messages[i].type == 'user' ? 'user' : 'bot',
                  text: _messages[i].text,
                  timestamp: i < _messageTimestamps.length
                      ? _messageTimestamps[i]
                      : DateTime.now(),
                  messageType: _messages[i].messageType,
                  triggers: _messages[i].triggers,
                  claimData: _messages[i].claimData,
                ),
          ],
        );
      } catch (_) {}

      // Wait for any in-flight auto-save so we don't race-create a duplicate
      // claim, then fall back to a fresh save if it never succeeded.
      if (_autoSaveFuture != null) {
        try {
          await _autoSaveFuture;
        } catch (_) {}
      }

      if (!_savedOnSummary) {
        try {
          await _runSaveClaimAndConversation(
            externalRef: _extractClaimReference(doneMsg.text),
          );
          _savedOnSummary = true;
        } catch (e) {
          errorMessage = 'Failed to save claim: $e';
        }
      }
    } finally {
      if (mounted) {
        setState(() => _closingConversation = false);
        if (errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red.shade700,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.home,
          (route) => false,
          arguments: {'initialTab': 1},
        );
      }
    }
  }

  void _showEndSessionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('End Session?',
            style: TextStyle(fontWeight: FontWeight.bold, color: _kDark)),
        content: const Text(
            'Are you sure you want to end this voice session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('End Session',
                style: TextStyle(
                    color: _kRed, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _refreshClaimsList();
      },
      child: Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 390),
            child: Column(
              children: [
                _buildHeader(),
                _buildStateAvatar(),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: _messages.length,
                    itemBuilder: (_, index) {
                      final msg = _messages[index];
                      if (msg.isTyping) return _buildTypingIndicator();
                      if (msg.type == 'bot') {
                        // Hide bot bubbles whose TTS hasn't started yet — the
                        // queued speech entries reveal them one at a time.
                        if (_pendingRevealIndices.contains(index)) {
                          return const SizedBox.shrink();
                        }
                        return _buildBotBubble(msg, index);
                      }
                      return _buildUserBubble(msg);
                    },
                  ),
                ),
                if (_isRecording) _buildListeningBanner(),
                _buildInputBar(),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  // ─── Header (custom) ───────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: _kBg,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x11000000),
                    blurRadius: 4,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back, size: 18, color: _kDark),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'AI Claim Assistant',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: _kDark,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: _showEndSessionDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: _kRed.withValues(alpha: 0.4)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.close, size: 14, color: _kRed),
                  SizedBox(width: 4),
                  Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 13,
                      color: _kRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── State Avatar (Speaking / Listening / Idle) ────────────────────────
  Widget _buildStateAvatar() {
    final isListening = _isRecording;
    final isSpeaking = _botSpeaking;

    final Color ringColor = isListening
        ? const Color(0xFF22C55E)
        : _kBlue;
    final Color dotColor = isListening
        ? const Color(0xFF22C55E)
        : (isSpeaking ? const Color(0xFFF59E0B) : Colors.grey.shade400);
    final String label = isListening
        ? 'Listening...'
        : (isSpeaking ? 'Speaking...' : 'Idle');
    final Color labelColor = isListening
        ? const Color(0xFF22C55E)
        : (isSpeaking ? const Color(0xFFF59E0B) : Colors.grey);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isListening)
                  AnimatedBuilder(
                    animation: _blinkController,
                    builder: (_, _) {
                      final t = _blinkController.value;
                      return Container(
                        width: 72 - 8 * t,
                        height: 72 - 8 * t,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF22C55E)
                              .withValues(alpha: 0.18 * (1 - t)),
                        ),
                      );
                    },
                  )
                else if (isSpeaking)
                  AnimatedBuilder(
                    animation: _speakController,
                    builder: (_, _) {
                      final t = _speakController.value;
                      return Container(
                        width: 64 + 8 * t,
                        height: 64 + 8 * t,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _kBlue.withValues(alpha: 0.15 * (1 - t)),
                        ),
                      );
                    },
                  ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ringColor,
                    boxShadow: [
                      BoxShadow(
                        color: ringColor.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    isListening
                        ? Icons.hearing_rounded
                        : Icons.sentiment_neutral_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: dotColor,
                      border: Border.all(color: _kBg, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Claim Assistant',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: _kDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: labelColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedText(String text, TextStyle baseStyle) {
    final spans = <TextSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*', dotAll: true);
    int cursor = 0;
    for (final match in pattern.allMatches(text)) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ));
      cursor = match.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }
    return Text.rich(TextSpan(style: baseStyle, children: spans));
  }

  int _lastBotIndex() {
    for (int i = _messages.length - 1; i >= 0; i--) {
      final m = _messages[i];
      if (m.type == 'bot' &&
          !m.isTyping &&
          !_pendingRevealIndices.contains(i)) {
        return i;
      }
    }
    return -1;
  }

  /// True while the bot bubble at [index] is mid-utterance — chips, trigger
  /// buttons and other interactive affordances are suppressed during speech
  /// so the user sees them only after the message has finished being read.
  bool _isCurrentlySpeaking(int index) {
    return _currentSpeech?.messageIndex == index;
  }

  Widget _buildBotAvatar({bool animate = false}) {
    final avatar = Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(color: _kBlue, shape: BoxShape.circle),
      child: ClipOval(
        child: Image.asset(
          'assets/images/avatar_assistant.png',
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Icon(
            Icons.smart_toy_outlined,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
    if (!animate) return avatar;
    return AnimatedBuilder(
      animation: _speakController,
      builder: (_, child) {
        final t = _speakController.value;
        final scale = 1.0 + 0.08 * t;
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 36 + 12 * t,
              height: 36 + 12 * t,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kBlue.withValues(alpha: 0.18 * (1 - t)),
              ),
            ),
            Transform.scale(scale: scale, child: child),
          ],
        );
      },
      child: avatar,
    );
  }

  Widget _buildBotBubble(_ChatMessage msg, int index) {
    final isLastBot = index == _lastBotIndex();
    final visibleText = _visibleBotText(index, msg.text);
    // The GET_DOCUMENT trigger renders its own Skip control inside the upload
    // card, so suppress a duplicate "Skip" chip on the same turn.
    final List<String> visibleChips = (msg.chips ?? [])
        .where((s) => s != 'Skip' || !msg.triggers.contains('GET_DOCUMENT'))
        .toList();

    // Final summary uses the dedicated "Review Your Claim" card with a
    // "Confirm & Submit Claim" CTA that persists to the database.
    if (msg.payloadType == 'final_summary' &&
        msg.payload != null &&
        msg.payload!.isNotEmpty) {
      return _buildFinalSummaryCard(
        msg: msg,
        isLastBot: isLastBot,
        index: index,
      );
    }

    // Structured summary payload → render as a card (matches chat mode).
    final structured = _tableFields(msg);
    if (structured != null) {
      return _buildPolicyCard(
        msg: msg,
        title: _cardTitleFor(msg.payloadType),
        fields: structured,
        introText: visibleText,
        isLastBot: isLastBot,
        index: index,
      );
    }

    // Fallback: markdown bot text that lists **Key:** Value lines.
    final policyFields = _parsePolicyFields(msg.text);
    if (policyFields != null) {
      return _buildPolicyCard(
        msg: msg,
        title: 'Policy Verified',
        fields: policyFields,
        introText: _policyIntroText(visibleText),
        isLastBot: isLastBot,
        index: index,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBotAvatar(),
              const SizedBox(width: 10),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(0),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.06),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFormattedText(
                        visibleText,
                        const TextStyle(
                          fontSize: 14,
                          color: _kDark,
                          height: 1.4,
                        ),
                      ),
                      if (_showSampleOf(msg))
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: GestureDetector(
                            onTap: () => _openSampleImagesViewer(msg),
                            child: const Text(
                              '(See sample)',
                              style: TextStyle(
                                fontSize: 13,
                                color: _kBlue,
                                decoration: TextDecoration.underline,
                                decorationColor: _kBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (msg.validationFailedAngles.isNotEmpty)
                        _buildValidationFailureList(
                          msg,
                          msg.validationFailedAngles,
                        ),
                      if (msg.validationFailedLegacy)
                        _buildLegacyValidationFailure(),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Suggestion chips — only on the latest bot message with chips,
          // and only after its speech has finished playing. When the same
          // turn carries a GET_DOCUMENT trigger, drop the "Skip" chip since
          // the document trigger renders its own Skip control.
          if (visibleChips.isNotEmpty &&
              isLastBot &&
              !_botTyping &&
              !_isCurrentlySpeaking(index)) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 46),
              child: _buildChips(visibleChips),
            ),
          ],

          // Trigger widgets — only on the latest bot message, after speech.
          if (isLastBot &&
              !_botTyping &&
              !_isCurrentlySpeaking(index) &&
              msg.triggers.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 46),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: msg.triggers
                    .where((t) => t != 'SHOW_TABLE')
                    .map((t) => _buildTriggerButton(t, msg))
                    .toList(),
              ),
            ),
          ],

          // Close button on terminal (done) message.
          if (isLastBot &&
              !_botTyping &&
              !_isCurrentlySpeaking(index) &&
              msg.messageType == 'done') ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 46),
              child: _buildPillButton(
                icon: Icons.check_circle_outline,
                label: 'Close',
                onTap: () => _onCloseConversation(msg),
                isLoading: _closingConversation,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserAttachments(_ChatMessage msg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (msg.imagePaths.isNotEmpty)
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 6,
              runSpacing: 6,
              children: msg.imagePaths.map((path) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(path),
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 88,
                      height: 88,
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: Colors.grey.shade400,
                        size: 24,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        if (msg.documentNames.isNotEmpty) ...[
          if (msg.imagePaths.isNotEmpty) const SizedBox(height: 6),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: msg.documentNames.map((name) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.insert_drive_file_outlined,
                        size: 18,
                        color: _kBlue,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _kDark,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildUserBubble(_ChatMessage msg) {
    final hasAttachments =
        msg.imagePaths.isNotEmpty || msg.documentNames.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (hasAttachments) ...[
                  _buildUserAttachments(msg),
                  const SizedBox(height: 6),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: _kBlue,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(0),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: _buildFormattedText(
                    msg.text,
                    const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Builder(
            builder: (context) {
              final user = context.watch<AuthCubit>().state.user;
              final avatarUrl = user?.avatarUrl;
              final initials = (user?.fullName ?? '')
                  .split(' ')
                  .where((p) => p.isNotEmpty)
                  .take(2)
                  .map((p) => p[0].toUpperCase())
                  .join();
              return Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                child: ClipOval(
                  child: avatarUrl != null && avatarUrl.isNotEmpty
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          width: 36,
                          height: 36,
                          errorBuilder: (_, _, _) => CircleAvatar(
                            radius: 18,
                            backgroundColor: _kUserInitialsBg,
                            child: Text(
                              initials.isNotEmpty ? initials : '?',
                              style: const TextStyle(
                                color: _kUserInitialsText,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      : CircleAvatar(
                          radius: 18,
                          backgroundColor: _kUserInitialsBg,
                          child: Text(
                            initials.isNotEmpty ? initials : '?',
                            style: const TextStyle(
                              color: _kUserInitialsText,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChips(List<String> options) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        return GestureDetector(
          onTap: () => _handleChipSelection(option),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kBlue),
            ),
            child: Text(
              option,
              style: const TextStyle(
                fontSize: 13,
                color: _kBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // TRIGGER WIDGETS
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildTriggerButton(String trigger, _ChatMessage msg) {
    switch (trigger) {
      case 'GET_DATE_TIME':
        return _buildDateTimeTrigger();
      case 'GET_LOCATION':
        return _buildLocationTrigger();
      case 'GET_IMAGE':
        return _buildImageTrigger(msg);
      case 'GET_DOCUMENT':
        return _buildDocumentTrigger(msg);
      case 'SUBMIT_CLAIM':
        return _buildSubmitClaimTrigger();
      default:
        return const SizedBox.shrink();
    }
  }

  // Helpers to read GET_IMAGE constraints from a message payload.
  List<String> _allowedAnglesOf(_ChatMessage msg) {
    final raw = msg.payload?['allowed_angles'];
    if (raw is List) return raw.map((e) => e.toString()).toList(growable: false);
    return const [];
  }

  /// Whether the bot's `GET_IMAGE` payload requested showing the bundled
  /// sample-photos affordance (`payload.show_sample == true`).
  bool _showSampleOf(_ChatMessage msg) {
    if (!msg.triggers.contains('GET_IMAGE')) return false;
    final raw = msg.payload?['show_sample'];
    if (raw is bool) return raw;
    if (raw is String) return raw.toLowerCase() == 'true';
    return false;
  }

  void _openSampleImagesViewer(_ChatMessage msg) {
    if (!_showSampleOf(msg)) return;
    showSampleImagesDialog(
      context: context,
      assetPaths: const ['assets/images/damage_photos_sample.png'],
      labels: const [],
    );
  }

  int? _payloadInt(_ChatMessage msg, String key) {
    final raw = msg.payload?[key];
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  /// "front_left" → "Front Left" for display.
  String _humanizeAngle(String angle) {
    return angle
        .split(RegExp(r'[_\s]+'))
        .where((p) => p.isNotEmpty)
        .map((p) => p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join(' ');
  }

  Widget _buildDateTimeTrigger() {
    final now = DateTime.now();
    final date = _dtDate ?? now;
    final time = _dtTime ?? TimeOfDay.fromDateTime(now);
    final dateLabel = DateFormat('d MMM yyyy').format(date);
    final timeLabel = time.format(context);

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Incident Date & Time',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _dateTimeField(
                  icon: Icons.calendar_today_outlined,
                  value: dateLabel,
                  onTap: _pickIncidentDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _dateTimeField(
                  icon: Icons.access_time,
                  value: timeLabel,
                  onTap: _pickIncidentTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _confirmIncidentDateTime,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _kBlue,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: _kBlue.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Confirm Date & Time',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateTimeField({
    required IconData icon,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: _kBlue),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: _kDark,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.chevron_right, size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildPillButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kBlue),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _kBlue),
              )
            else
              Icon(icon, size: 16, color: _kBlue),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: _kBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationTrigger() {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _locationController,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _onSubmitLocation(),
            style: const TextStyle(fontSize: 13, color: _kDark),
            decoration: InputDecoration(
              hintText: 'Enter street, city or zip code',
              hintStyle:
                  TextStyle(fontSize: 13, color: Colors.grey.shade400),
              prefixIcon: Icon(Icons.location_on_outlined,
                  size: 18, color: Colors.grey.shade400),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 40, minHeight: 0),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(22),
                borderSide: const BorderSide(color: _kBlue),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildPillButton(
            icon: Icons.my_location,
            label: 'Use Current Location',
            onTap: _onUseCurrentLocation,
            isLoading: _fetchingLocation,
          ),
        ],
      ),
    );
  }

  Widget _buildImageTrigger(_ChatMessage msg) {
    final angles = _allowedAnglesOf(msg);
    if (angles.isEmpty) {
      return _buildLegacyImageTrigger();
    }
    final minCount = _payloadInt(msg, 'min_count') ?? angles.length;
    final maxCount = _payloadInt(msg, 'max_count') ?? angles.length;
    // Count only the angles this trigger owns. The global map can carry stray
    // entries from a different group's still-open failure card.
    final filledCount = angles.where(_angleImages.containsKey).length;
    final triggerCategory = _inferCategoryFromText(msg.text, isImage: true);
    final groupAlreadyDone = _uploadedGroupKeys.contains(triggerCategory);
    final canSubmit =
        filledCount >= minCount &&
        !_uploadingFiles &&
        !_botTyping &&
        !groupAlreadyDone;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload Photos',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: _kDark),
          ),
          const SizedBox(height: 4),
          Text(
            '$filledCount of $maxCount uploaded · min $minCount',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          for (int i = 0; i < angles.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _buildAngleRow(angles[i], maxCount),
          ],
          const SizedBox(height: 12),
          if (filledCount >= minCount)
            GestureDetector(
              onTap: canSubmit
                  ? () => _onSubmitAngleImages(originatingMsg: msg)
                  : null,
              child: Opacity(
                opacity: canSubmit ? 1.0 : 0.5,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _kBlue,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_uploadingFiles)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      else
                        const Icon(Icons.check_circle_outline,
                            size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text(
                        'DONE',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// One row in the per-angle uploader: label + thumbnail + upload/replace
  /// controls. Single-image picker per row.
  Widget _buildAngleRow(String angle, int maxCount) {
    final picked = _angleImages[angle];
    final atCap = _angleImages.length >= maxCount && picked == null;
    return Row(
      children: [
        if (picked != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(picked,
                width: 48, height: 48, fit: BoxFit.cover),
          ),
          const SizedBox(width: 10),
        ] else ...[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F2F7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.image_outlined,
                color: Colors.grey.shade500, size: 22),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _humanizeAngle(angle),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _kDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                picked == null ? 'Not uploaded' : 'Uploaded',
                style: TextStyle(
                  fontSize: 11,
                  color: picked == null ? Colors.grey.shade600 : _kBlue,
                ),
              ),
            ],
          ),
        ),
        if (picked != null)
          IconButton(
            tooltip: 'Remove',
            onPressed: () => _onRemoveAngleImage(angle),
            icon: const Icon(Icons.close, size: 18, color: Colors.red),
            visualDensity: VisualDensity.compact,
          ),
        TextButton.icon(
          onPressed: (atCap || _uploadingFiles)
              ? null
              : () => _onPickAngleImage(angle),
          icon: Icon(picked == null ? Icons.camera_alt_outlined : Icons.refresh,
              size: 16),
          label: Text(picked == null ? 'Upload' : 'Replace',
              style: const TextStyle(fontSize: 12)),
          style: TextButton.styleFrom(
            foregroundColor: _kBlue,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }

  Widget _buildLegacyImageTrigger() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upload Photos',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: _kDark),
          ),
          if (_pickedImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _pickedImages.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, index) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _pickedImages[index],
                          width: 72,
                          height: 72,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: -6,
                        right: -6,
                        child: GestureDetector(
                          onTap: () => _onRemoveImage(index),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 12, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_pickedImages.length}/$_maxImages UPLOADED',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _uploadingFiles
                ? null
                : (_pickedImages.isEmpty ? _onPickImages : _onSubmitImages),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_uploadingFiles)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _kDark),
                    )
                  else
                    Icon(
                      _pickedImages.isEmpty
                          ? Icons.camera_alt_outlined
                          : Icons.check_circle_outline,
                      size: 18,
                      color: _kDark,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    _pickedImages.isEmpty ? 'UPLOAD' : 'DONE',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_pickedImages.isNotEmpty &&
              _pickedImages.length < _maxImages) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _uploadingFiles ? null : _onPickImages,
              child: Text(
                '+ Add more',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentTrigger(_ChatMessage msg) {
    final minCount = _payloadInt(msg, 'min_count') ?? 1;
    final maxCount = _payloadInt(msg, 'max_count') ?? _maxDocuments;
    final alreadyUploaded = _docTriggerProgress[msg]?.count ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upload Documents',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _kDark),
              ),
              const SizedBox(height: 4),
              Text(
                minCount > 1
                    ? '$alreadyUploaded of $maxCount uploaded · min $minCount'
                    : 'You can upload photos or PDF files.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              if (_pickedDocuments.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...List.generate(_pickedDocuments.length, (index) {
                  final doc = _pickedDocuments[index];
                  final sizeKb = doc.size ~/ 1024;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.description_outlined,
                            size: 20, color: _kBlue),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                doc.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _kDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Document • $sizeKb KB',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _onRemoveDocument(index),
                          child: Icon(Icons.close,
                              size: 18, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }),
                Text(
                  '${_pickedDocuments.length}/$_maxDocuments UPLOADED',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _uploadingFiles
                    ? null
                    : (_pickedDocuments.isEmpty
                        ? _onPickDocuments
                        : () => _onSubmitDocuments(msg)),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_uploadingFiles)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _kDark),
                        )
                      else
                        Icon(
                          _pickedDocuments.isEmpty
                              ? Icons.upload_file_outlined
                              : Icons.check_circle_outline,
                          size: 18,
                          color: _kDark,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        _pickedDocuments.isEmpty ? 'UPLOAD' : 'DONE',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _kDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_pickedDocuments.isNotEmpty &&
                  _pickedDocuments.length < _maxDocuments) ...[
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _uploadingFiles ? null : _onPickDocuments,
                  child: Text(
                    '+ Add more',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _onSkipDocuments,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kBlue),
            ),
            child: const Text(
              'Skip',
              style: TextStyle(
                fontSize: 13,
                color: _kBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Review Your Claim card (payload_type == "final_summary") ──────────
  static const _incidentKeys = {
    'incident date',
    'incident time',
    'incident location',
    'incident description',
    'damage details',
    'date',
    'time',
    'location',
    'description',
  };

  static const _documentKeys = {
    'vehicle photos',
    'damage photos',
    'driver license',
    'driving license',
    'license photos',
    'supporting docs',
    'supporting documents',
    'police report',
    'bill invoice',
    'repair bill',
    'invoice',
    'vehicle photos count',
    'damage photos count',
    'license photos count',
    'police report count',
    'repair bill count',
    'invoice count',
  };

  String _humanizeDocLabel(String key) {
    final k = key.toLowerCase().trim();
    switch (k) {
      case 'vehicle photos':
      case 'vehicle photos count': return 'Vehicle Photos';
      case 'damage photos':
      case 'damage photos count': return 'Damage Vehicle Photos';
      case 'driver license':
      case 'driving license':
      case 'license photos':
      case 'license photos count': return 'Driving License';
      case 'supporting docs':
      case 'supporting documents': return 'Uploaded Documents';
      case 'police report':
      case 'police report count': return 'Police Report';
      case 'bill invoice':
      case 'invoice':
      case 'invoice count': return 'Invoice';
      case 'repair bill':
      case 'repair bill count': return 'Repair Bill';
      default: return key.replaceAll(' Count', '');
    }
  }

  int _extractCount(dynamic value) {
    if (value is num) return value.toInt();
    final raw = value.toString();
    final match = RegExp(r'\d+').firstMatch(raw);
    if (match != null) return int.parse(match.group(0)!);
    return _asInt(value);
  }

  Widget _buildFinalSummaryCard({
    required _ChatMessage msg,
    required bool isLastBot,
    required int index,
  }) {
    final payload = msg.payload!;
    final basic = <MapEntry<String, String>>[];
    final incident = <MapEntry<String, String>>[];
    final documents = <MapEntry<String, String>>[];

    payload.forEach((key, value) {
      if (value == null) return;
      final formatted = _formatFieldValue(key, value);
      if (formatted.isEmpty) return;
      final keyLc = key.toLowerCase().trim();
      if (_documentKeys.contains(keyLc)) {
        final count = _extractCount(value);
        documents.add(MapEntry(_humanizeDocLabel(key), '$count Files'));
      } else if (_incidentKeys.contains(keyLc)) {
        incident.add(MapEntry(key, formatted));
      } else {
        basic.add(MapEntry(key, formatted));
      }
    });

    final maxCardWidth = MediaQuery.of(context).size.width * 0.86;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bot avatar + intro bubble. The intro reveals progressively in
          // sync with TTS playback; the summary card below is held back until
          // speech finishes so the user never sees the table while the
          // sentence above it is still typing out.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBotAvatar(),
              const SizedBox(width: 10),
              if (msg.text.trim().isNotEmpty)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(0),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.06),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: _buildFormattedText(
                      _visibleBotText(index, msg.text),
                      const TextStyle(
                        fontSize: 14,
                        color: _kDark,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (!_isCurrentlySpeaking(index)) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(left: 46),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxCardWidth),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2A6FDB), Color(0xFF1E5BC2)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _kBlue.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.description_outlined,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Review Your Claim',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ..._reviewRows(basic),
                    if (incident.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _reviewSectionHeader('INCIDENT DETAILS'),
                      const SizedBox(height: 10),
                      ..._reviewRows(incident, multiline: true),
                    ],
                    if (documents.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _reviewSectionHeader('DOCUMENTS'),
                      const SizedBox(height: 10),
                      ..._reviewRows(documents),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (!isLastBot ||
                                _confirmingFinalSummary ||
                                _botTyping ||
                                _isCurrentlySpeaking(index))
                            ? null
                            : () => _onConfirmFinalSummary(msg),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _kBlue,
                          disabledBackgroundColor:
                              Colors.white.withValues(alpha: 0.7),
                          disabledForegroundColor:
                              _kBlue.withValues(alpha: 0.6),
                          elevation: 0,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                        child: _confirmingFinalSummary
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(_kBlue),
                                ),
                              )
                            : const Text(
                                'Confirm & Submit Claim',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ],
        ],
      ),
    );
  }

  Widget _reviewSectionHeader(String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 1,
          color: Colors.white.withValues(alpha: 0.2),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }

  List<Widget> _reviewRows(
    List<MapEntry<String, String>> rows, {
    bool multiline = false,
  }) {
    return [
      for (final r in rows)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(
                  '${r.key}:',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  r.value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.45,
                  ),
                  textAlign:
                      multiline ? TextAlign.left : TextAlign.right,
                  maxLines: multiline ? null : 2,
                  overflow:
                      multiline ? TextOverflow.visible : TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
    ];
  }

  // ─── Policy / Summary Card ──────────────────────────────────────────────
  Widget _buildPolicyCard({
    required _ChatMessage msg,
    required String title,
    required Map<String, String> fields,
    required String introText,
    required bool isLastBot,
    required int index,
  }) {
    final statusValue = fields.entries
        .where((e) => e.key.toLowerCase() == 'status')
        .map((e) => e.value)
        .firstOrNull;
    final isActive =
        statusValue != null && statusValue.toLowerCase().contains('active');

    final maxCardWidth = MediaQuery.of(context).size.width * 0.82;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row with avatar + intro text bubble (intro is what we speak).
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBotAvatar(),
              const SizedBox(width: 10),
              if (introText.isNotEmpty)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(0),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.06),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: _buildFormattedText(
                      introText,
                      const TextStyle(
                        fontSize: 14,
                        color: _kDark,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Card itself (indented under the avatar). Hidden while the intro
          // bubble is still being read aloud — we wait for the typewriter to
          // finish before revealing the structured fields, so the user never
          // sees the table while the message above it is mid-typing.
          if (!_isCurrentlySpeaking(index))
          Padding(
            padding: const EdgeInsets.only(left: 46, top: 10),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxCardWidth),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: const BoxDecoration(
                              color: Color(0xFF34A853),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check,
                                color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _kDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Fields
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Column(
                        children: List.generate(fields.length, (i) {
                          final entry = fields.entries.elementAt(i);
                          final isStatus =
                              entry.key.toLowerCase() == 'status';
                          final isLast = i == fields.length - 1;
                          return Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              border: isLast
                                  ? null
                                  : Border(
                                      bottom: BorderSide(
                                        color: Colors.grey.shade200,
                                        width: 1,
                                      ),
                                    ),
                            ),
                            child: Row(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 110,
                                  child: Text(
                                    '${entry.key}:',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    entry.value,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: isStatus && isActive
                                          ? const Color(0xFF34A853)
                                          : _kDark,
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          ),

          // Suggestion chips on last bot message — only after speech ends.
          if (isLastBot &&
              !_botTyping &&
              !_isCurrentlySpeaking(index) &&
              msg.chips != null &&
              msg.chips!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 46),
              child: _buildChips(msg.chips!),
            ),
          ],

          // Trigger widgets on last bot message.
          if (isLastBot &&
              !_botTyping &&
              !_isCurrentlySpeaking(index) &&
              msg.triggers.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 46),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: msg.triggers
                    .where((t) => t != 'SHOW_TABLE')
                    .map((t) => _buildTriggerButton(t, msg))
                    .toList(),
              ),
            ),
          ],

          // Close button on terminal message.
          if (isLastBot &&
              !_botTyping &&
              !_isCurrentlySpeaking(index) &&
              msg.messageType == 'done') ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 46),
              child: _buildPillButton(
                icon: Icons.check_circle_outline,
                label: 'Close',
                onTap: () => _onCloseConversation(msg),
                isLoading: _closingConversation,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitClaimTrigger() {
    final claimMsg = _messages.lastWhere(
      (m) => m.claimData != null && m.claimData!.isNotEmpty,
      orElse: () => const _ChatMessage(text: '', type: 'bot'),
    );
    if (claimMsg.claimData == null || claimMsg.claimData!.isEmpty) {
      return const SizedBox.shrink();
    }
    return _buildPillButton(
      icon: Icons.check_circle_outline,
      label: 'Submit Claim',
      onTap: () => _onSubmitClaim(claimMsg.claimData!),
      isLoading: _submittingClaim,
    );
  }

  // ─── Typing Indicator ──────────────────────────────────────────────────

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBotAvatar(),
          const SizedBox(width: 10),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(0),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.06),
                  blurRadius: 6,
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _typingController,
              builder: (_, _) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(3, (i) {
                    final delay = i * 0.15;
                    final t =
                        (_typingController.value - delay).clamp(0.0, 1.0);
                    final offset =
                        -4.0 * (1.0 - (2.0 * t - 1.0) * (2.0 * t - 1.0));
                    return Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
                      child: Transform.translate(
                        offset: Offset(0, offset),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Recording Indicator ───────────────────────────────────────────────

  // ─── Listening Banner ──────────────────────────────────────────────────

  Widget _buildListeningBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _blinkController,
                builder: (_, child) {
                  return Opacity(
                    opacity: 0.2 + 0.8 * (1.0 - _blinkController.value),
                    child: child,
                  );
                },
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: _kRed,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Listening... speak now',
                style: TextStyle(
                  fontSize: 13,
                  color: _kDark,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Spacer(),
              if (_liveTranscript.trim().isNotEmpty)
                GestureDetector(
                  onTap: _onDeleteTranscript,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 18,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              GestureDetector(
                onTap: _stopRecordingAndSubmit,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _kRed.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: const Text(
                    'Stop',
                    style: TextStyle(
                      fontSize: 13,
                      color: _kRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_liveTranscript.isNotEmpty) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _liveTranscript,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Input Bar (text + mic + send) ─────────────────────────────────────

  void _submitTypedMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty || _botTyping) return;
    _textController.clear();
    _handleVoiceInput(text);
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _submitTypedMessage(),
                      style: const TextStyle(fontSize: 14, color: _kDark),
                      decoration: InputDecoration(
                        hintText: _botSpeaking
                            ? 'Tap mic to interrupt'
                            : 'Type a message...',
                        hintStyle: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade500,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _voiceAvailable ? _onMicTap : null,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _voiceAvailable
                          ? Icon(
                              _botSpeaking
                                  ? Icons.stop_circle_rounded
                                  : Icons.mic_none_rounded,
                              size: 20,
                              color: _isRecording
                                  ? _kRed
                                  : (_botSpeaking ? _kRed : _kBlue),
                            )
                          : const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _kBlue,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _hasDraftText
                ? _submitTypedMessage
                : (_voiceAvailable ? _onMicTap : null),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isRecording ? _kRed : _kBlue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? _kRed : _kBlue)
                        .withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
