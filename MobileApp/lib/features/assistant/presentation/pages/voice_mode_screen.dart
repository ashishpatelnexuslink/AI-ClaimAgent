import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart' hide ServiceStatus;
import 'package:uuid/uuid.dart';

import 'package:claim_ai/core/l10n/app_locales.dart';
import 'package:claim_ai/core/l10n/generated/app_localizations.dart';
import 'package:claim_ai/core/l10n/locale_cubit.dart';
import 'package:claim_ai/core/navigation/app_routes.dart';
import 'package:claim_ai/core/services/domain_corrector.dart';
import 'package:claim_ai/core/services/plate_normalizer.dart';
import 'package:claim_ai/core/services/voice_service.dart';
import 'package:claim_ai/core/storage/chat_transcript_writer.dart';
import 'package:claim_ai/core/utils/request_context.dart';
import 'package:claim_ai/features/assistant/presentation/widgets/sample_images_dialog.dart';
import 'package:claim_ai/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:claim_ai/features/claims/presentation/cubit/claims_cubit.dart';
import 'package:claim_ai/features/claims/data/datasources/claims_remote_datasource.dart';
import 'package:claim_ai/injection_container.dart' as di;
import 'package:claim_ai/features/assistant/data/datasources/chat_service.dart';
import 'package:claim_ai/features/assistant/presentation/widgets/voice_mode/bot_avatar.dart';
import 'package:claim_ai/features/assistant/presentation/widgets/voice_mode/chat_chips.dart';
import 'package:claim_ai/features/assistant/presentation/widgets/voice_mode/formatted_text.dart';
import 'package:claim_ai/features/assistant/presentation/widgets/voice_mode/user_bubble.dart';
import 'package:claim_ai/features/assistant/presentation/widgets/voice_mode/listening_banner.dart';
import 'package:claim_ai/features/assistant/presentation/widgets/voice_mode/pill_button.dart';
import 'package:claim_ai/features/assistant/presentation/widgets/voice_mode/state_avatar.dart';
import 'package:claim_ai/features/assistant/presentation/widgets/voice_mode/typing_indicator.dart';
import 'package:claim_ai/features/assistant/presentation/widgets/voice_mode/voice_mode_colors.dart';
import 'package:claim_ai/features/assistant/presentation/widgets/voice_mode/voice_mode_header.dart';
import 'package:claim_ai/features/assistant/presentation/widgets/voice_mode/voice_mode_input_bar.dart';
import 'package:claim_ai/features/assistant/presentation/widgets/voice_mode/voice_mode_models.dart';
import 'package:claim_ai/features/assistant/presentation/widgets/voice_mode/triggers/date_time_trigger.dart';
import 'package:claim_ai/features/assistant/presentation/widgets/voice_mode/triggers/document_trigger.dart';
import 'package:claim_ai/features/assistant/presentation/widgets/voice_mode/triggers/final_summary_card.dart';
import 'package:claim_ai/features/assistant/presentation/widgets/voice_mode/triggers/policy_card.dart';
import 'package:claim_ai/features/assistant/presentation/widgets/voice_mode/triggers/image_trigger.dart';
import 'package:claim_ai/features/assistant/presentation/widgets/voice_mode/triggers/image_validation_card.dart';
import 'package:claim_ai/features/assistant/presentation/widgets/voice_mode/triggers/location_trigger.dart';
import 'package:claim_ai/features/assistant/presentation/widgets/voice_mode/triggers/submit_claim_trigger.dart';

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
  final List<ChatMessage> _messages = [];
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
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'doc',
    'docx',
  ];
  final List<String> _uploadedDocumentIds = [];

  // Per-GET_DOCUMENT-trigger upload progress. Lets the user satisfy
  // `min_count` across multiple separate uploads instead of picking everything
  // at once. Cleared once the min is reached and the bot advances.
  final Map<ChatMessage, _DocTriggerProgress> _docTriggerProgress = {};
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
  // True after the bot streams `final_summary` (the review-claim card); the
  // very next outgoing message (typically "Yes Confirm") is what triggers
  // save_summary on the bot side, so we attach device_id / ip_address /
  // app_version on that message so the AI has the context when it saves.
  // Single-shot: flips back to false once the params have been sent.
  bool _attachContextOnNextSend = false;
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

  // ─── Selected app language (drives both TTS and STT) ────────────────────
  /// BCP-47 tag for flutter_tts, e.g. `it-IT`, `hi-IN`, `en-US`.
  String _ttsLanguageTag = 'en-US';
  /// Language code (`'lv'`, `'de'`, …) used for plate normalisation and the
  /// pack-missing banner copy. Stays in sync with the LocaleCubit.
  String _currentLanguageCode = 'en';
  StreamSubscription<Locale>? _localeSub;

  /// True when the device doesn't ship an STT pack for the selected app
  /// language and we had to fall back to a different language (typically
  /// English). The mic still works in degraded mode; a banner prompts the
  /// user to install the missing pack.
  bool _sttPackMissing = false;
  /// Same idea, for the TTS voice. When true, the bot speaks in English
  /// instead of staying silent.
  bool _ttsPackMissing = false;

  // ─── Speech-synced typewriter ──────────────────────────────────────────
  // Bot bubbles reveal their text progressively, in sync with TTS playback,
  // so reading and listening stay aligned. We queue an entry per utterance
  // because flutter_tts queues replies and only fires the start handler
  // when each one actually begins.
  final List<SpeechEntry> _pendingSpeech = [];
  SpeechEntry? _currentSpeech;
  int _spokenChars = 0;

  // Bot replies arrive (via SSE stream) faster than TTS can speak them. Rather
  // than render every bubble immediately and have later ones sit fully formed
  // until TTS catches up, we hold them here and promote one at a time as each
  // utterance completes. Keeps the gradual reveal in sync with the audio.
  final List<ChatMessage> _pendingBotReplies = [];

  // Android binds com.google.android.tts asynchronously after the plugin is
  // created. If we call _tts.speak() before the binder is fully connected,
  // the call fails silently ("speak failed: not bound to TTS engine") — no
  // audio, and no setStartHandler/setCompletionHandler ever fire. We complete
  // this signal once init is verified ready, and _speakBotReply awaits it.
  final Completer<void> _ttsReady = Completer<void>();

  // ─── Auto-listen after bot finishes speaking ───────────────────────────
  Timer? _autoListenTimer;
  // Wait long enough for the TTS audio session / focus to release before we
  // start the recognizer. 600ms was too short on Android — the engine would
  // start "listening" while audio routing was still owned by TTS, so the mic
  // was deaf until the user manually re-tapped. 1500ms reliably hands over.
  static const Duration _autoListenDelay = Duration(milliseconds: 1500);

  // ─── Controllers ────────────────────────────────────────────────────────
  final TextEditingController _textController = TextEditingController();
  final FocusNode _inputFocus = FocusNode();
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

    _textController.addListener(() {
      final hasText = _textController.text.trim().isNotEmpty;
      if (hasText != _hasDraftText) {
        setState(() => _hasDraftText = hasText);
      }
      // User is composing → don't auto-listen over them.
      if (hasText) _cancelAutoListen();
    });

    // Repaint the input pill when focus changes so the border can switch
    // between idle (grey) and focused (blue) states.
    _inputFocus.addListener(() {
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Capture the currently-selected app locale *after* the first frame so
      // context.read<LocaleCubit>() is safe to call. TTS/STT need this to
      // speak and recognize in the user's chosen language rather than English.
      final cubit = context.read<LocaleCubit>();
      _currentLanguageCode = cubit.state.languageCode;
      _ttsLanguageTag = _bcp47ForLocale(cubit.state);
      _initVoice(cubit.state);
      _initTts();
      // Re-apply if the user switches language while voice mode is open.
      _localeSub = cubit.stream.listen(_onLocaleChanged);
      _streamBotReply('hello');
    });
  }

  /// Build a BCP-47 tag (`it-IT`, `en-US`, …) from a Flutter [Locale],
  /// filling in the language's default country when none is set.
  String _bcp47ForLocale(Locale locale) {
    final cc = (locale.countryCode == null || locale.countryCode!.isEmpty)
        ? AppLocales.defaultCountryFor(locale.languageCode)
        : locale.countryCode!;
    return cc.isEmpty ? locale.languageCode : '${locale.languageCode}-$cc';
  }

  /// Sets the flutter_tts engine language to [tag] (BCP-47, e.g. `it-IT`).
  /// Falls back to `en-US` when the device's TTS engine doesn't ship a voice
  /// for the requested language — better to hear English than silence.
  ///
  /// Android: the TTS service binds asynchronously. setLanguage internally
  /// calls Android's isLanguageAvailable, and on a dead binder Android
  /// returns LANG_NOT_SUPPORTED *without throwing*. flutter_tts then resolves
  /// setLanguage with status 0 — a silent "didn't actually set the language"
  /// result that leaves the engine unconfigured, and the first speak()
  /// produces no audio. We poll until the binder reports success.
  Future<void> _applyTtsLanguage(String tag) async {
    String target = tag;
    bool missing = false;
    try {
      final available = await _tts.isLanguageAvailable(tag);
      if (available != true) {
        target = 'en-US';
        missing = true;
      }
    } catch (_) {
      // Some engines don't implement isLanguageAvailable — just try the tag.
    }
    if (mounted && _ttsPackMissing != missing) {
      setState(() => _ttsPackMissing = missing);
    } else {
      _ttsPackMissing = missing;
    }
    if (Platform.isAndroid) {
      for (int attempt = 0; attempt < 30; attempt++) {
        final result = await _tts.setLanguage(target);
        if (result == 1) break;
        await Future.delayed(const Duration(milliseconds: 200));
      }
    } else {
      await _tts.setLanguage(target);
    }
  }

  /// Asymmetric-pack guard. If STT has fallen back to English but TTS still
  /// speaks the user's chosen language, the user hears Italian (etc.) and
  /// then dictates Italian into an English recognizer — accuracy collapses.
  /// Force TTS to English in that case so the user mirrors the language the
  /// recognizer can actually understand. The pack-missing banner already
  /// tells them why.
  Future<void> _alignTtsToSttIfDegraded() async {
    if (_sttPackMissing && !_ttsLanguageTag.toLowerCase().startsWith('en')) {
      _ttsLanguageTag = 'en-US';
      await _applyTtsLanguage(_ttsLanguageTag);
    }
  }

  Future<void> _onLocaleChanged(Locale locale) async {
    if (!mounted) return;
    _currentLanguageCode = locale.languageCode;
    _ttsLanguageTag = _bcp47ForLocale(locale);
    await _applyTtsLanguage(_ttsLanguageTag);
    final res = await _voice.resolveLocale(
      locale.languageCode,
      locale.countryCode,
    );
    final newLocaleId = res.localeId ?? _localeId;
    final wasListening = _voice.isListening;
    if (mounted) {
      setState(() {
        _localeId = newLocaleId;
        _sttPackMissing = !res.exactMatch;
      });
    }
    await _alignTtsToSttIfDegraded();
    // If the user switched language while the mic was open, the in-flight
    // native session is still bound to the *previous* locale and will keep
    // recognising in the wrong language until its next natural restart. Drop
    // anything captured so far (it would be in the old language) and restart
    // with the new locale so the next utterance is recognised correctly.
    if (wasListening && newLocaleId != null) {
      await _voice.cancel();
      await _voice.start(localeId: newLocaleId);
    }
  }

  Future<void> _initVoice(Locale locale) async {
    _voice
      ..onTextUpdate = _onVoiceTextUpdate
      ..onFinalText = _onVoiceFinalText
      ..onFinalAlternates = _onVoiceFinalAlternates
      ..onError = _onVoiceError
      ..onListeningChange = _onVoiceListeningChange;

    final ok = await _voice.initialize();
    _voiceAvailable = ok;
    bool packMissing = false;
    if (ok) {
      // Prefer the user's selected language; fall back to English if the
      // device doesn't have an STT pack for it, so the mic still works.
      // Dump locales once so we can confirm pack availability from the logs
      // when debugging "Latvian doesn't recognise anything" reports.
      await _voice.dumpLocales();
      final res = await _voice.resolveLocale(
        locale.languageCode,
        locale.countryCode,
      );
      if (res.exactMatch && res.localeId != null) {
        _localeId = res.localeId;
        // Synthesized = the engine did not list this locale; we're passing
        // the BCP-47 tag and hoping online recognition handles it. Surface
        // the banner so users on engines that silently fall back to English
        // (Samsung Voice Input, some OEM stacks) understand why the live
        // transcript looks like garbled English.
        if (res.synthesized) packMissing = true;
      } else {
        packMissing = true;
        // Smart fallback: device system locale (if English) → en_US → en_GB
        // → en_AU/en_CA/en_IE → en_IN → any en_*. Replaces the previous
        // hard-coded en_IN, which gave Indian-English acoustic models to
        // European users and tanked perceived accuracy.
        _localeId = await _voice.resolveEnglishFallback();
      }
    }
    if (mounted) {
      setState(() {
        _sttPackMissing = packMissing;
      });
    }
    await _alignTtsToSttIfDegraded();
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
    final l = AppLocalizations.of(context);
    if (error == 'permission_denied') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.voice_micPermissionRequired),
          action: SnackBarAction(
            label: l.voice_settingsAction,
            onPressed: () => openAppSettings(),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.voice_error(error))));
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

  static const MethodChannel _audioRouteChannel = MethodChannel(
    'com.claimai/audio_route',
  );

  /// Force TTS output to the built-in speaker on iOS. Without this, the
  /// `playAndRecord` category routes audio to the receiver (earpiece) — so
  /// users hear the bot only when holding the phone to their ear.
  ///
  /// `flutter_tts`'s `defaultToSpeaker` category option is set up at init,
  /// but SFSpeechRecognizer flips the audio route back to the receiver
  /// whenever it activates the mic. The only reliable iOS API to undo that
  /// is `AVAudioSession.overrideOutputAudioPort(.speaker)`, which is exposed
  /// via the native `AudioRoutePlugin`. Re-applied before every `speak()`.
  Future<void> _applyIosSpeakerRoute() async {
    if (!Platform.isIOS) return;
    try {
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playAndRecord,
        [
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
        ],
        IosTextToSpeechAudioMode.voicePrompt,
      );
    } catch (_) {
      // Older flutter_tts builds may lack one of these APIs — fall through
      // and accept whatever the default session is.
    }
    try {
      await _audioRouteChannel.invokeMethod<bool>('routeToSpeaker');
    } catch (_) {
      // Native channel may not be registered (debug hot-restart edge case).
      // The flutter_tts category set above is the fallback.
    }
  }

  Future<void> _initTts() async {
    // iOS-only: opt into a shared `playAndRecord` audio session so the mic
    // stays usable after TTS playback. flutter_tts defaults to `playback`,
    // which is exclusive — once it has been activated, SFSpeechRecognizer
    // can't acquire the input route, so on iPhone the listening UI silently
    // does nothing after the first bot reply.
    await _applyIosSpeakerRoute();
    await _applyTtsLanguage(_ttsLanguageTag);
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    // Keep speak() fire-and-forget. awaitSpeakCompletion(true) seemed
    // attractive (await would mark "done"), but on Android it caused
    // speak() to resolve immediately without producing audio — no sound,
    // and both bubbles flushed through the queue instantly.
    await _tts.awaitSpeakCompletion(false);
    // Queue replies so back-to-back bot messages are spoken sequentially.
    // setQueueMode is Android-only; iOS queues utterances by default and
    // throws MissingPluginException if called.
    if (Platform.isAndroid) {
      await _tts.setQueueMode(1);
    }

    _tts.setStartHandler(() {
      if (!mounted) return;
      _cancelAutoListen();
      setState(() {
        _botSpeaking = true;
        _currentSpeech = _pendingSpeech.isNotEmpty
            ? _pendingSpeech.removeAt(0)
            : null;
        _spokenChars = 0;
      });
      _speakController.repeat(reverse: true);
      _scrollToBottom();
    });
    _tts.setProgressHandler((text, start, end, word) {
      if (!mounted || _currentSpeech == null) return;
      setState(() => _spokenChars = end);
      _followGrowth();
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
      // Drain the next queued bot reply, if any. Auto-listen only kicks in
      // once the whole batch has finished.
      if (_pendingBotReplies.isNotEmpty) {
        _pumpBotReplies();
      } else {
        _scheduleAutoListen();
      }
    });
    _tts.setCancelHandler(() {
      if (!mounted) return;
      setState(() {
        _botSpeaking = false;
        _currentSpeech = null;
        _spokenChars = 0;
        _pendingSpeech.clear();
        _pendingBotReplies.clear();
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
        _pendingBotReplies.clear();
      });
      _speakController.stop();
      _speakController.reset();
    });

    // Init complete — let any pending _speakBotReply calls proceed. On
    // Android this is reached only after setLanguage stopped throwing (i.e.
    // the TTS service is bound and ready to accept speak()).
    if (!_ttsReady.isCompleted) _ttsReady.complete();
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
    // Wait for the TTS engine to finish binding before speaking. On Android,
    // calling speak() before the binder is connected fails silently — no
    // audio plays and no completion handler ever fires, which leaves the
    // bot-reply queue permanently stuck.
    if (!_ttsReady.isCompleted) {
      await _ttsReady.future;
    }
    if (!mounted) return;
    final spoken = _sanitizeForSpeech(text);
    if (spoken.isEmpty) return;
    if (messageIndex != null) {
      _pendingSpeech.add(SpeechEntry(messageIndex, spoken.length));
    }
    // Force speaker output before each utterance. SFSpeechRecognizer can flip
    // the iOS audio route to the receiver while listening, so without this the
    // bot's voice plays out of the earpiece instead of the speaker.
    await _applyIosSpeakerRoute();
    await _tts.speak(spoken);
  }

  /// Hold a bot reply until its TTS turn comes. If nothing is being spoken,
  /// the next pump promotes it into [_messages] right away; otherwise it sits
  /// in [_pendingBotReplies] until [setCompletionHandler] drains the queue.
  /// Avoids the "bubble #2 appears fully formed, then empties when TTS
  /// catches up" flash on both iOS and Android.
  void _enqueueBotReply(ChatMessage reply) {
    _pendingBotReplies.add(reply);
    _pumpBotReplies();
  }

  /// Promote the next queued bot reply (if any) into the visible chat list and
  /// kick off its TTS. Bails out if speech is already in flight — the
  /// completion handler will call us again once TTS frees up. Bot messages
  /// with no speakable text don't block the queue; we keep dequeuing until we
  /// find one that needs spoken or run out.
  void _pumpBotReplies() {
    if (_currentSpeech != null || _pendingSpeech.isNotEmpty || _botSpeaking) {
      return;
    }
    if (_pendingBotReplies.isEmpty) return;

    String? speechText;
    int speechIndex = -1;
    setState(() {
      while (_pendingBotReplies.isNotEmpty) {
        final next = _pendingBotReplies.removeAt(0);
        _messages.add(next);
        _messageTimestamps.add(DateTime.now());
        final spoken = _sanitizeForSpeech(next.text);
        if (spoken.isEmpty) continue;
        speechText = spoken;
        speechIndex = _messages.length - 1;
        break;
      }
      // Eagerly enter the "revealing" state in the same setState that adds
      // the bubble. Without this, _visibleBotText sees _currentSpeech == null
      // for the few frames before setStartHandler fires and renders the full
      // text — then the handler resets _spokenChars to 0 and the bubble
      // visibly snaps back to empty before revealing. setStartHandler will
      // re-assign _currentSpeech to the same entry; the assignment is
      // idempotent so the redundancy is harmless.
      if (speechText != null) {
        _currentSpeech = SpeechEntry(speechIndex, speechText!.length);
        _spokenChars = 0;
      }
    });
    _scrollToBottom();

    if (speechText != null) {
      unawaited(_speakBotReply(speechText!, messageIndex: speechIndex));
    }
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
    var n = (text.length * ratio).ceil().clamp(0, text.length);
    // Avoid splitting a UTF-16 surrogate pair (e.g. emoji), which produces a
    // malformed string and crashes ParagraphBuilder.addText.
    if (n > 0 && n < text.length) {
      final unit = text.codeUnitAt(n - 1);
      if (unit >= 0xD800 && unit <= 0xDBFF) n -= 1;
    }
    return text.substring(0, n);
  }

  @override
  void dispose() {
    _cancelAutoListen();
    _localeSub?.cancel();
    _voice.dispose();
    _tts.stop();
    // Stop the iOS route-change observer from force-routing audio to the
    // speaker once the user leaves voice mode (other screens may want the
    // receiver, e.g. a phone-call-style UI).
    if (Platform.isIOS) {
      unawaited(
        _audioRouteChannel
            .invokeMethod<bool>('releaseSpeakerRoute')
            .catchError((_) => false),
      );
    }
    _textController.dispose();
    _inputFocus.dispose();
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
    _pendingBotReplies.clear();
    _cancelAutoListen();
    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          type: 'user',
          imagePaths: imagePaths,
          documentNames: documentNames,
        ),
      );
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
    // Drop any queued-but-not-yet-shown bot replies for the same reason.
    // _tts.stop() triggers the cancel handler only when something is actually
    // speaking, so clear the dart-side queue here unconditionally.
    _pendingBotReplies.clear();
    _cancelAutoListen();
    setState(() {
      _messages.add(ChatMessage(text: text, type: 'user'));
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

  /// Snap to bottom while the bot bubble grows during TTS playback. Uses
  /// `jumpTo` (not `animateTo`) so rapid progress callbacks don't queue
  /// conflicting animations, and only follows when the user is already near
  /// the bottom so scrolling up to read history doesn't get yanked back down.
  void _followGrowth() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final pos = _scrollController.position;
      if (pos.maxScrollExtent - pos.pixels < 200) {
        pos.jumpTo(pos.maxScrollExtent);
      }
    });
  }

  // ─── Flow Logic (API-based) ──────────────────────────────────────────────

  Future<void> _streamBotReply(String userMessage) async {
    setState(() {
      _botTyping = true;
      _messages.add(const ChatMessage(text: '', type: 'bot', isTyping: true));
    });
    _scrollToBottom();

    // `AUTO_GET_LOCATION` is delivered mid-stream, while `_botTyping` is
    // still true. `_onUseCurrentLocation` bails on that flag, so we defer
    // the fetch until after the stream finishes.
    bool autoFetchLocation = false;

    try {
      final locale = Localizations.localeOf(context);
      final contactPhone = context.read<AuthCubit>().state.user?.phone;

      // Single-shot context attach: when the previous bot turn streamed
      // `save_summary`, this outgoing message carries device_id / ip_address /
      // app_version. Resolved up-front so a slow public-IP lookup doesn't
      // block message dispatch indefinitely (ChatRequestContext.gather caps
      // the IP call at ~5s and tolerates failure).
      final attachContext = _attachContextOnNextSend;
      ChatRequestContext? ctx;
      if (attachContext) {
        ctx = await ChatRequestContext.gather();
        _attachContextOnNextSend = false;
      }

      await for (final msg in ChatService.sendMessage(
        userMessage,
        threadId: _threadId,
        language: locale.languageCode,
        deviceId: ctx?.deviceId,
        ipAddress: ctx?.ipAddress,
        appVersion: ctx?.appVersion,
        contactPhone: contactPhone,
      )) {
        if (!mounted) return;
        setState(() {
          _messages.removeWhere((m) => m.isTyping);
        });
        _enqueueBotReply(
          ChatMessage(
            text: msg.content,
            type: 'bot',
            chips: msg.suggestions.isNotEmpty ? msg.suggestions : null,
            messageType: msg.messageType,
            triggers: msg.triggers,
            claimData: msg.claimData,
            payloadType: msg.payloadType,
            payload: msg.payload,
            enPayload: msg.enPayload,
          ),
        );
        // Claim row is inserted when the bot streams `claim_reference` — the
        // payload carries the AI-assigned reference number that becomes the
        // claim's ClaimNumber. `save_summary` is intentionally not used to
        // insert anymore; the Close button still acts as a fallback if
        // `claim_reference` never arrives.
        //
        // Prefer en_payload (English-keyed twin) but fall back to payload —
        // the bot sometimes streams only the localized payload, and chat
        // mode handles this with the same `enPayload ?? payload` pattern at
        // [claim_chat_screen.dart:254]. Keep both screens aligned so a
        // backend change can't regress one and not the other.
        if (msg.payloadType == 'claim_reference') {
          unawaited(_applyClaimReferencePayload(msg.enPayload ?? msg.payload));
        }
        // `final_summary` is the bot's "Review Your Claim" card. The user's
        // reply to it (typically "Yes Confirm") is the message that triggers
        // save_summary on the bot side, so we tag that outgoing message with
        // device_id / ip_address / app_version.
        if (msg.payloadType == 'final_summary') {
          _attachContextOnNextSend = true;
        }
        if (msg.triggers.contains('AUTO_GET_LOCATION')) {
          autoFetchLocation = true;
        }
      }
    } catch (_) {
      if (!mounted) return;
      // Drop any pending replies that haven't surfaced yet — the stream
      // failed, so they're stale. The error message becomes the next thing
      // the user hears/sees.
      _pendingBotReplies.clear();
      setState(() {
        _messages.removeWhere((m) => m.isTyping);
      });
      _enqueueBotReply(
        ChatMessage(
          text: AppLocalizations.of(context).voice_genericError,
          type: 'bot',
        ),
      );
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
    // Tapping a suggestion is a deliberate user action — kill any in-progress
    // mic session and pending auto-listen timer so the recognizer doesn't keep
    // listening (or fire later) while we process the tap.
    _cancelAutoListen();
    if (_voice.isListening) {
      unawaited(_voice.cancel());
    }
    _addUserMessage(value);
    _streamBotReply(value);
  }

  /// Alternates from the most recent STT finalResult, captured *before* the
  /// finalText callback fires (see [VoiceService.stop] ordering). Consumed
  /// once in [_handleVoiceInput] and cleared, so a subsequent typed message
  /// doesn't accidentally inherit them.
  List<String> _pendingAlternates = const [];

  void _onVoiceFinalAlternates(List<String> alternates) {
    _pendingAlternates = alternates;
  }

  void _handleVoiceInput(String transcript) {
    if (_botTyping) return;
    // Each candidate goes through the same correction pipeline; we score them
    // and send the best. For typed input [_pendingAlternates] is empty, so
    // the pipeline reduces to the previous single-candidate path.
    final alts = _pendingAlternates.isEmpty ? [transcript] : _pendingAlternates;
    _pendingAlternates = const [];
    final userName = context.read<AuthCubit>().state.user?.fullName ?? '';
    final extras = <String>[
      if (userName.isNotEmpty) ...userName.split(RegExp(r'\s+')),
    ];
    final best = _pickBestCandidate(alts, extras);
    _addUserMessage(best);
    _streamBotReply(best);
  }

  /// Run every STT alternate through plate normalization + domain correction
  /// and pick the highest-scoring result. Scoring:
  ///   * Plate prompts: prefer the candidate whose [PlateNormalizer] match
  ///     hits the regex / confidence gate. Top engine pick wins ties.
  ///   * Otherwise: prefer the candidate where [DomainCorrector] rewrote the
  ///     most tokens — that means the alternate aligned best with our
  ///     domain vocabulary, which is the same heuristic a human reviewer
  ///     would use ("this one mentions 'polizza', the other says 'polisia'").
  ///   * Ties always fall back to the first (engine-confidence-best) entry.
  String _pickBestCandidate(List<String> candidates, List<String> extras) {
    String? best;
    int bestRewrites = -1;
    String? bestPlate;
    final lastBotIdx = _lastBotIndex();
    final isPlatePrompt = lastBotIdx >= 0 &&
        _PlatePromptDetector.matches(
          _messages[lastBotIdx].text,
          _currentLanguageCode,
        );

    for (final raw in candidates) {
      // Plate normalization runs first because it owns its own prompt-context
      // gate and returns the transcript unchanged when the previous bot turn
      // wasn't a plate question — so it's a no-op for non-plate turns.
      final plateCorrected = _maybeNormalizePlate(raw);
      final corrected = DomainCorrector.correct(
        plateCorrected,
        _currentLanguageCode,
        extraPhrases: extras,
      );
      if (isPlatePrompt) {
        // _maybeNormalizePlate returns the bare plate when its confidence /
        // regex gate passed — short uppercase alphanumeric. First such hit
        // wins (candidates are ordered by engine confidence).
        if (RegExp(r'^[A-Z0-9]{4,12}$').hasMatch(plateCorrected) &&
            bestPlate == null) {
          bestPlate = corrected;
        }
      }
      final rewrites = _countRewrites(raw, corrected);
      if (rewrites > bestRewrites) {
        bestRewrites = rewrites;
        best ??= corrected;
        if (rewrites > 0) best = corrected;
      }
    }
    return bestPlate ?? best ?? candidates.first;
  }

  /// Cheap "how different is [corrected] from [raw]" metric, used to detect
  /// which alternate the domain corrector engaged with most. Token-level so
  /// punctuation / casing differences don't dominate.
  int _countRewrites(String raw, String corrected) {
    final a = raw.toLowerCase().split(RegExp(r'\s+'))..removeWhere((s) => s.isEmpty);
    final b = corrected.toLowerCase().split(RegExp(r'\s+'))..removeWhere((s) => s.isEmpty);
    int diff = (a.length - b.length).abs();
    final n = a.length < b.length ? a.length : b.length;
    for (int i = 0; i < n; i++) {
      if (a[i] != b[i]) diff++;
    }
    return diff;
  }

  /// When the previous bot turn was asking for a vehicle registration number,
  /// run the raw STT transcript through [PlateNormalizer]. The recogniser
  /// returns letter/digit names in the active language ("gi i zero uno a bi
  /// nove nove") that the AI service can't parse — we reconstruct the
  /// canonical plate before sending. Only triggered for plate prompts so we
  /// don't garble normal sentences.
  String _maybeNormalizePlate(String transcript) {
    final lastBotIdx = _lastBotIndex();
    if (lastBotIdx < 0) return transcript;
    final last = _messages[lastBotIdx];
    if (!_PlatePromptDetector.matches(last.text, _currentLanguageCode)) {
      return transcript;
    }
    final candidate = PlateNormalizer.normalize(
      transcript,
      _currentLanguageCode,
    );
    // Require at least 4 alphanumeric chars and ≥70% of input tokens matched
    // before overwriting — otherwise the user probably wasn't dictating a
    // plate (e.g. "I don't remember") and the raw text should pass through.
    if (candidate.confidence >= 0.7 &&
        RegExp(r'^[A-Z0-9]{4,12}$').hasMatch(candidate.plate)) {
      return candidate.plate;
    }
    return transcript;
  }

  /// Time the TTS audio session needs to fully release after `_tts.stop()`
  /// before we can reliably grab the mic. Without this brief gap, Android
  /// hands the recognizer an engine that's nominally listening but receives
  /// no audio (TTS still owns audio focus).
  static const Duration _postTtsStopDelay = Duration(milliseconds: 300);

  Future<void> _onMicTap() async {
    if (_botTyping) return;

    _cancelAutoListen();

    // Capture before any await — context.read across async gaps is unsafe.
    final selectedLocale = context.read<LocaleCubit>().state;

    if (_botSpeaking) {
      await _tts.stop();
      await Future.delayed(_postTtsStopDelay);
    }

    if (_voice.isListening) {
      await _voice.stop();
      return;
    }

    if (!_voiceAvailable) {
      await _initVoice(selectedLocale);
      if (!_voiceAvailable) {
        if (!mounted) return;
        final l = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.voice_micPermissionRequired),
            action: SnackBarAction(
              label: l.voice_settingsAction,
              onPressed: () => openAppSettings(),
            ),
          ),
        );
        return;
      }
    }

    await _voice.start(
      localeId: _localeId ?? 'en_IN',
      mode: _promptModeForLastBot(),
    );
  }

  /// Picks the STT prompt mode from the most recent bot message: chips ⇒
  /// confirmation; plate / VIN / numeric-id prompts ⇒ shortAnswer; everything
  /// else ⇒ free dictation. Wrong here is recoverable — the engine still
  /// recognises the same words, just with a slightly different language
  /// model bias. Right here meaningfully improves accuracy on short replies
  /// (yes/no, plates) where the dictation model over-segments.
  VoicePromptMode _promptModeForLastBot() {
    final idx = _lastBotIndex();
    if (idx < 0) return VoicePromptMode.dictation;
    final last = _messages[idx];
    if (last.chips != null && last.chips!.isNotEmpty) {
      return VoicePromptMode.confirmation;
    }
    if (_PlatePromptDetector.matches(last.text, _currentLanguageCode)) {
      return VoicePromptMode.shortAnswer;
    }
    // messageType signals from the bot: claim_reference, plate, vin, date,
    // odometer all expect a short alphanumeric / numeric token.
    const shortAnswerTypes = {
      'plate', 'vin', 'claim_number', 'reference', 'odometer', 'mileage',
      'date', 'time', 'phone', 'policy_number',
    };
    if (shortAnswerTypes.contains(last.messageType)) {
      return VoicePromptMode.shortAnswer;
    }
    return VoicePromptMode.dictation;
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

  Map<String, String>? _tableFields(ChatMessage msg) {
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
    final l = AppLocalizations.of(context);
    switch (payloadType) {
      case 'initial_summary':
        return l.voice_initialSummary;
      case 'final_summary':
        return l.voice_claimSummary;
      case 'save_summary':
        return l.voice_savedClaimSummary;
      case 'verified_summary':
      default:
        return l.voice_policyVerified;
    }
  }

  String _formatFieldValue(String key, dynamic value) {
    final raw = value.toString().trim();
    if (raw.isEmpty) return '';
    final iso = RegExp(r'^\d{4}-\d{2}-\d{2}').firstMatch(raw);
    if (iso != null) {
      final parsed = DateTime.tryParse(raw);
      if (parsed != null) {
        return DateFormat.yMMMd(
                Localizations.localeOf(context).languageCode)
            .format(parsed);
      }
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
      initialDate: initial.isAfter(now) ? now : initial,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(colorScheme: const ColorScheme.light(primary: kVmBlue)),
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
        data: Theme.of(
          context,
        ).copyWith(colorScheme: const ColorScheme.light(primary: kVmBlue)),
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
    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final locale = Localizations.localeOf(context).languageCode;
    final formatted =
        '${DateFormat.yMMMd(locale).format(selected)}, ${DateFormat.jm(locale).format(selected)}';
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
    final l = AppLocalizations.of(context);
    setState(() => _fetchingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.voice_locationEnableGps)),
        );
        // Send the user to settings, then wait (with a timeout) for the OS
        // to broadcast that location services are now enabled. Without this,
        // `openLocationSettings()` returns immediately and the fetch silently
        // gives up.
        await Geolocator.openLocationSettings();
        try {
          await Geolocator.getServiceStatusStream()
              .firstWhere((s) => s == ServiceStatus.enabled)
              .timeout(const Duration(seconds: 60));
        } on TimeoutException {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l.voice_locationNotEnabled)),
          );
          return;
        }
        if (!mounted) return;
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.voice_locationPermissionRequired)),
        );
        return;
      }
      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.voice_locationPermissionDeniedForever)),
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
        SnackBar(content: Text(l.voice_locationServicesDisabled)),
      );
    } on PermissionDeniedException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.voice_locationPermissionDenied)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l.voice_locationError(e.toString()))));
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
    setState(() {
      _angleImages[angle] = File(picked.path);
      _failedAnglePaths.remove(angle);
    });
    _scrollToBottom();
  }

  void _onRemoveAngleImage(String angle) {
    setState(() => _angleImages.remove(angle));
  }

  Future<void> _onSubmitAngleImages({ChatMessage? originatingMsg}) async {
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

    // Stale failure cards are guarded at the UI layer (their Submit button is
    // disabled when the group is in `_uploadedGroupKeys`). The fresh GET_IMAGE
    // trigger card must remain submittable because the AI can re-ask for the
    // same group after a "No, re-upload" — so no early return here.

    // Scope the entries to the full allowed-angles set for this card. On a
    // retry, the failure card carries `validationAllowedAngles` (forwarded
    // from the original GET_IMAGE trigger) so we always send the complete
    // batch — newly replaced angles + previously valid ones — to
    // `/validate-images`. Sending only failed angles would have the AI
    // re-validate a partial set, which the agent rejects.
    final List<String> allowedAngles =
        (originatingMsg?.validationAllowedAngles.isNotEmpty ?? false)
        ? originatingMsg!.validationAllowedAngles
        : (originatingMsg != null
              ? _allowedAnglesOf(originatingMsg)
              : const []);
    final List<String>? scopedAngles = allowedAngles.isEmpty
        ? null
        : allowedAngles;
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
    // `vehicle_photos`, `damage_photos`, and `driver_license` go through
    // `/validate-images` — every other group (supporting_docs, …) uploads
    // directly.
    // Only forward the originating msg for removal if it's a failure card
    // (not the original GET_IMAGE trigger card — that one stays in chat).
    final ChatMessage? failureCardToReplace =
        (originatingMsg != null &&
            (originatingMsg.validationFailedAngles.isNotEmpty ||
                originatingMsg.validationFailedLegacy))
        ? originatingMsg
        : null;
    // TEMP: `/validate-images` is currently scoped to `vehicle_photos` only.
    // `damage_photos` and `driver_license` validation is disabled and falls
    // through to a direct upload until the AI side is ready again.
    if (category == 'vehicle_photos' /* ||
        category == 'damage_photos' ||
        category == 'driver_license' */) {
      final validation = await _runImageValidation(
        questionLabel: category,
        images: {for (final p in prepared) p.angle: base64Encode(p.bytes)},
        allowedAngles: allowedAngles,
        previousFailureMsg: failureCardToReplace,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
            content: Text(
                AppLocalizations.of(context).voice_imageUploadFailed(e.toString()))));
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
      text: AppLocalizations.of(context).chat_photosUploaded(count),
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
    ChatMessage? previousFailureMsg,
  }) async {
    final l = AppLocalizations.of(context);
    final waitingMsg = ChatMessage(
      text: l.voice_validatingImages,
      type: 'bot',
    );
    setState(() => _messages.add(waitingMsg));
    _scrollToBottom();

    ImageValidationResult result;
    try {
      final locale = Localizations.localeOf(context);
      result = await ChatService.validateImages(
        groupKey: questionLabel,
        threadId: _threadId,
        images: images,
        language: locale.languageCode,
      );
    } on TimeoutException catch (e) {
      debugPrint('[Validate] image validation timed out: $e');
      if (!mounted) {
        return ImageValidationResult(valid: false, failureReason: '');
      }
      setState(() {
        _messages.remove(waitingMsg);
        if (previousFailureMsg != null) {
          _messages.remove(previousFailureMsg);
        }
        _messages.add(
          ChatMessage(
            text: l.voice_imageValidationRetry,
            type: 'bot',
            validationTimeoutRetry: true,
            validationRetryImages: Map<String, String>.from(images),
            validationRetryQuestion: questionLabel,
            validationRetryIsLegacy: isLegacy,
            validationAllowedAngles: allowedAngles,
          ),
        );
      });
      _scrollToBottom();
      return ImageValidationResult(valid: false, failureReason: '');
    } catch (e) {
      debugPrint('[Validate] image validation failed: $e');
      result = ImageValidationResult(
        valid: false,
        failureReason: l.voice_imageValidationCouldNot,
      );
    }

    if (!mounted) return result;

    final failedAngles = result.invalidAngles;

    setState(() {
      _messages.remove(waitingMsg);
      // Drop the previous failure card for this group so retries don't stack
      // multiple "Some images need to be re-uploaded" cards in the chat.
      if (previousFailureMsg != null) {
        _messages.remove(previousFailureMsg);
      }
      if (!result.valid) {
        // When the API didn't return any invalid_angles (e.g., timeout or
        // network failure caught above), fall back to flagging every angle
        // we sent so the angle-wise re-upload card still renders instead of
        // the single-button legacy widget.
        final effectiveFailedAngles =
            (failedAngles.isEmpty && !isLegacy && allowedAngles.isNotEmpty)
            ? allowedAngles
            : failedAngles;
        // Snapshot the rejected paths so the failure card can detect when
        // the user picks a replacement (re-enabling Submit). The picked
        // images themselves stay in `_angleImages` so their thumbnails
        // remain visible alongside the per-angle error status.
        _failedAnglePaths.clear();
        for (final a in effectiveFailedAngles) {
          final f = _angleImages[a];
          if (f != null) _failedAnglePaths[a] = f.path;
        }
        final useLegacy = isLegacy || effectiveFailedAngles.isEmpty;
        _messages.add(
          ChatMessage(
            text: result.failureReason?.trim().isNotEmpty == true
                ? result.failureReason!
                : l.voice_imageValidationFailedReupload,
            type: 'bot',
            validationFailedAngles: useLegacy
                ? const []
                : List<String>.from(effectiveFailedAngles),
            validationFailedLegacy: useLegacy,
            validationGroupKey: result.groupKey,
            validationAllowedAngles: allowedAngles,
          ),
        );
      } else {
        _failedAnglePaths.clear();
      }
    });
    return result;
  }

  Future<void> _onValidationTimeoutRetry(ChatMessage msg) async {
    final images = msg.validationRetryImages;
    final question = msg.validationRetryQuestion;
    if (images == null || question == null) return;
    setState(() => _messages.remove(msg));
    await _runImageValidation(
      questionLabel: question,
      images: images,
      isLegacy: msg.validationRetryIsLegacy,
      allowedAngles: msg.validationAllowedAngles,
    );
  }

  Future<void> _onSubmitImages() async {
    debugPrint(
      '[Upload] _onSubmitImages enter '
      'picked=${_pickedImages.length} '
      'botTyping=$_botTyping uploading=$_uploadingFiles',
    );
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

    // `vehicle_photos`, `damage_photos`, and `driver_license` run through
    // AI validation; every other group uploads directly.
    // TEMP: `/validate-images` is currently scoped to `vehicle_photos` only.
    // `damage_photos` and `driver_license` validation is disabled and falls
    // through to a direct upload until the AI side is ready again.
    if (category == 'vehicle_photos' /* ||
        category == 'damage_photos' ||
        category == 'driver_license' */) {
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
            content: Text(
                AppLocalizations.of(context).voice_imageUploadFailed(e.toString()))));
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
    debugPrint(
      '[Upload] images submit → uploadedCount=$uploadedCount '
      'fallbackCount=${files.length} sending="${count.toString()}"',
    );
    _addUserAttachmentMessage(
      text: AppLocalizations.of(context).chat_photosUploaded(count),
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

  Future<void> _onSubmitDocuments(ChatMessage msg) async {
    debugPrint(
      '[Upload] _onSubmitDocuments enter '
      'picked=${_pickedDocuments.length} '
      'botTyping=$_botTyping uploading=$_uploadingFiles',
    );
    if (_pickedDocuments.isEmpty || _botTyping || _uploadingFiles) {
      debugPrint('[Upload] _onSubmitDocuments BAILED (guard)');
      return;
    }

    final docs = List<PlatformFile>.from(_pickedDocuments);
    final progress = _docTriggerProgress.putIfAbsent(
      msg,
      () => _DocTriggerProgress(),
    );
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)
                .voice_documentUploadFailed(e.toString()))));
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
    debugPrint(
      '[Upload] docs submit → uploadedCount=$uploadedCount '
      'fallbackCount=${docs.length} sending="${total.toString()}"',
    );
    _addUserAttachmentMessage(
      text: '$total document${total > 1 ? 's' : ''} uploaded',
      imagePaths: imagePaths,
      documentNames: docNames,
    );
    _streamBotReply(total.toString());
  }

  void _onSkipDocuments() {
    if (_botTyping) return;
    _cancelAutoListen();
    if (_voice.isListening) {
      unawaited(_voice.cancel());
    }
    setState(() => _pickedDocuments.clear());
    _addUserMessage('Skip');
    _streamBotReply('Skip');
  }

  // ── Confirm & Submit Claim (final_summary card) ─────────────────────────
  /// User tapped the "Confirm & Submit Claim" CTA on the review card.
  ///
  /// The claim row is intentionally NOT created here. The bot's response to
  /// "Yes Confirm" includes a `payload_type == "claim_reference"` SSE
  /// message; `_applyClaimReferencePayload` performs the single INSERT with
  /// the AI-assigned reference as `ClaimNumber`. This matches chat mode's
  /// working behaviour: one INSERT per claim, sourced from the AI, never
  /// overwritten.
  ///
  /// If the bot never streams `claim_reference` (network drop, AI failure),
  /// no row is created and `_onCloseConversation` surfaces an error — by
  /// design, per product call: no backend-generated fallback number, the
  /// user must retry the conversation.
  Future<void> _onConfirmFinalSummary(ChatMessage msg) async {
    if (_confirmingFinalSummary || _botTyping) return;
    setState(() => _confirmingFinalSummary = true);
    final reply = AppLocalizations.of(context).voice_yesConfirm;
    _addUserMessage(reply);
    _streamBotReply(reply);
    if (!mounted) return;
    setState(() => _confirmingFinalSummary = false);
  }

  // ── SUBMIT_CLAIM ─────────────────────────────────────────────────────────
  Future<void> _onSubmitClaim(Map<String, dynamic> claimData) async {
    if (_submittingClaim) return;
    setState(() => _submittingClaim = true);

    try {
      final payload = {...claimData, 'chatThreadId': _threadId};
      final dataSource = di.sl<ClaimsRemoteDataSource>();
      final response = await dataSource.createClaim(payload);

      if (!mounted) return;
      final claimNumber = response['claimNumber'] as String? ?? '';
      _submittedClaimId = (response['id'] ?? response['claimId'] ?? claimNumber)
          .toString();

      final l = AppLocalizations.of(context);
      setState(() {
        _messages.add(
          ChatMessage(
            text: l.voice_claimSubmittedMd(claimNumber),
            type: 'bot',
          ),
        );
        _messageTimestamps.add(DateTime.now());
        _submittingClaim = false;
      });
      _scrollToBottom();
      unawaited(
        _speakBotReply(l.voice_claimSubmittedSpoken(claimNumber)),
      );
      _refreshClaimsList();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(
            text: AppLocalizations.of(context).voice_failedToSubmitClaim,
            type: 'bot',
          ),
        );
        _messageTimestamps.add(DateTime.now());
        _submittingClaim = false;
      });
      _scrollToBottom();
    }
  }

  // ── Close conversation (message_type == 'done') ─────────────────────────

  /// Walks `_messages` then `_pendingBotReplies` (newest → oldest). The pending
  /// queue is gated on TTS completion, so an auto-save that fires synchronously
  /// when `save_summary` streams in would otherwise miss earlier `claim_data` /
  /// `final_summary` bubbles that haven't been spoken yet.
  Iterable<ChatMessage> _allBotMessagesNewestFirst() sync* {
    for (int i = _messages.length - 1; i >= 0; i--) {
      yield _messages[i];
    }
    for (int i = _pendingBotReplies.length - 1; i >= 0; i--) {
      yield _pendingBotReplies[i];
    }
  }

  Map<String, dynamic>? _latestClaimData() {
    for (final m in _allBotMessagesNewestFirst()) {
      final data = m.claimData;
      if (data != null && data.isNotEmpty) return data;
    }
    return null;
  }

  Map<String, dynamic>? _latestSaveSummaryPayload() {
    for (final m in _allBotMessagesNewestFirst()) {
      if (m.messageType == 'done' && m.payloadType == 'save_summary') {
        // English-only — `_mapSaveSummaryToDto` only matches English keys, so
        // returning the localized `m.payload` would pass German/Italian keys
        // through verbatim into the request body and leave DB columns null.
        if (m.enPayload != null && m.enPayload!.isNotEmpty) return m.enPayload;
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic>? _latestFinalSummaryEnPayload() {
    for (final m in _allBotMessagesNewestFirst()) {
      if (m.payloadType == 'final_summary') {
        if (m.enPayload != null && m.enPayload!.isNotEmpty) return m.enPayload;
        return null;
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
      // Keys arrive via `en_payload` in stable English (e.g. "Policy Number",
      // "Vin Number"), so a single-language switch is enough — case-insensitive
      // match handles cosmetic casing differences.
      switch (key.toLowerCase().trim()) {
        case 'policy number':
          mapped['policyNumber'] = value;
          break;
        case 'policy holder':
        case 'policyholder':
        case 'full name':
        case 'name':
          mapped['fullName'] = value;
          break;
        case 'claimant type':
        case 'claimant':
          mapped['claimantType'] = value.toString();
          break;
        case 'plat number':
        case 'plate number':
        case 'vehicle number':
        case 'vehicle registration number':
        case 'registration number':
          mapped['vehicleRegistrationNumber'] = value;
          break;
        case 'vin':
        case 'vin number':
        case 'vehicle identification number':
          mapped['vinNumber'] = value;
          break;
        case 'vehicle':
        case 'vehicle model':
          mapped['vehicleModel'] = value;
          break;
        case 'status':
        case 'policy status':
          mapped['policyStatus'] = value;
          break;
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
        case 'claim type':
          mapped['claimType'] = value.toString();
          break;
        case 'incident date':
        case 'date':
          incidentDateRaw = value.toString();
          break;
        case 'incident time':
        case 'time':
          incidentTimeRaw = value.toString();
          break;
        case 'incident location':
        case 'location':
          mapped['incidentLocation'] = value;
          break;
        case 'incident description':
        case 'damage details':
        case 'description':
          mapped['incidentDescription'] = value;
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
        default:
          mapped[key] = value;
      }
    });

    final combinedIncident = _combineIncidentDateTime(
      incidentDateRaw,
      incidentTimeRaw,
    );
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
    // `supporting` must be checked first: the supporting-docs prompt enumerates
    // examples ("insurance policy, accident photos, or police reports") that
    // would otherwise match the police_report / bill_invoice branches and route
    // the upload to the wrong groupKey, leaving the Claim Summary's
    // "Supporting Documents" section empty.
    if (text.contains('supporting')) return 'supporting_docs';
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

  /// Handles a streaming message with `payload_type == "claim_reference"`.
  /// Inserts the claim row directly using the AI-supplied reference number as
  /// the ClaimNumber. Idempotent — only the first claim_reference message per
  /// session does any work. Failures are logged; the Close button retries.
  Future<void> _applyClaimReferencePayload(
    Map<String, dynamic>? payload,
  ) async {
    final ref = payload?['claim_reference']?.toString().trim();
    if (ref == null || ref.isEmpty) return;
    if (_savedOnSummary || _autoSaveFuture != null) return;
    if (_submittedClaimId != null && _submittedClaimId!.isNotEmpty) return;

    final future = _runSaveClaimAndConversation(claimNumber: ref);
    _autoSaveFuture = future;
    try {
      await future;
      _savedOnSummary = true;
      debugPrint('[ClaimRef] inserted claim with ClaimNumber $ref');
    } catch (e) {
      _autoSaveFuture = null;
      debugPrint('[ClaimRef] insert failed (will retry on Close): $e');
    }
  }

  /// Performs the full server-side save: create claim row (if not already
  /// created via SUBMIT_CLAIM) and attach uploaded documents. Throws on any
  /// step failure.
  Future<void> _runSaveClaimAndConversation({
    Map<String, dynamic>? saveSummaryPayload,
    String? externalRef,
    String? claimNumber,
  }) async {
    String? finalClaimId = _submittedClaimId;

    if (finalClaimId == null || finalClaimId.isEmpty) {
      final claimData = _latestClaimData() ?? <String, dynamic>{};
      // Merge order (lowest → highest precedence):
      //  1. claim_data — the bot's structured snapshot streamed earlier.
      //  2. final_summary.en_payload — rich "Review Your Claim" data; the bot
      //     sometimes ships a thin save_summary while the review card carries
      //     the full structured fields.
      //  3. save_summary — the AI's authoritative confirmation payload, so it
      //     wins over earlier sources when present.
      final finalSummary = _latestFinalSummaryEnPayload();
      final finalSummaryFields = finalSummary != null
          ? _mapSaveSummaryToDto(finalSummary)
          : <String, dynamic>{};
      final saveSummary = saveSummaryPayload ?? _latestSaveSummaryPayload();
      final summaryFields = saveSummary != null
          ? _mapSaveSummaryToDto(saveSummary)
          : <String, dynamic>{};
      final payload = <String, dynamic>{
        ...claimData,
        ...finalSummaryFields,
        ...summaryFields,
        'chatThreadId': _threadId,
        'externalReference': ?externalRef,
        'claimNumber': ?claimNumber,
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

  Future<void> _onCloseConversation(ChatMessage doneMsg) async {
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

      // Wait for any in-flight save triggered by a streaming
      // `claim_reference` so the local _submittedClaimId is up to date
      // before we decide whether to warn.
      if (_autoSaveFuture != null) {
        try {
          await _autoSaveFuture;
        } catch (_) {}
      }

      // No fallback INSERT on Close. The single source of truth for the
      // claim row is the bot's `claim_reference` SSE message, which is
      // applied by `_applyClaimReferencePayload`. If the bot never streamed
      // it (network drop, AI failure), surface an error — by design, per
      // product call: no backend-generated ClaimNumber fallback, the user
      // must retry the conversation. Filters out the case where the user
      // ended the session early (rejecting policy at `verified_summary`),
      // in which case there is no claim_data and nothing to warn about.
      final hadClaimData = _latestSaveSummaryPayload() != null ||
          (_latestClaimData()?.isNotEmpty ?? false);
      final claimWasSaved = _submittedClaimId != null && _savedOnSummary;
      if (hadClaimData && !claimWasSaved && mounted) {
        errorMessage = AppLocalizations.of(context)
            .voice_failedToSaveClaim('claim_reference not received');
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

  Future<void> _showEndSessionDialog() async {
    final navigator = Navigator.of(context);
    if (await _confirmLeave()) {
      if (mounted) navigator.pop();
    }
  }

  /// True while a voice conversation is in flight — at least one bot/user
  /// exchange beyond the initial greeting and the bot hasn't streamed a
  /// terminal `done` message. Fresh / completed sessions skip the dialog.
  bool _isMidConversation() {
    if (_messages.length <= 1) return false;
    final last = _messages.last;
    if (last.type == 'bot' && last.messageType == 'done') return false;
    return true;
  }

  /// Confirmation dialog shown before tearing down the voice session. Used
  /// by the Close pill, the header back button, and the Android system
  /// back gesture (via [PopScope]). Returns true when the user confirms.
  Future<bool> _confirmLeave() async {
    if (!_isMidConversation()) return true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final l = AppLocalizations.of(ctx);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            l.voice_endSessionTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, color: kVmDark),
          ),
          content: Text(l.voice_endSessionBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l.common_cancel,
                  style: const TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                l.voice_endSessionAction,
                style: const TextStyle(color: kVmRed, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
    return confirmed == true;
  }

  // ═════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final navigator = Navigator.of(context);
    return PopScope(
      // Mid-conversation: block direct pop and route through the confirm
      // dialog. After a clean exit (or no conversation yet), allow the pop
      // and refresh the claims list as before.
      canPop: !_isMidConversation(),
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          _refreshClaimsList();
          return;
        }
        if (await _confirmLeave()) {
          if (!mounted) return;
          _refreshClaimsList();
          navigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: kVmBg,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 390),
              child: Column(
                children: [
                  VoiceModeHeader(
                    onBack: () async {
                      if (await _confirmLeave()) {
                        if (mounted) navigator.pop();
                      }
                    },
                    onEndSession: _showEndSessionDialog,
                  ),
                  if (_sttPackMissing || _ttsPackMissing)
                    _buildLanguagePackBanner(),
                  StateAvatar(
                    isRecording: _isRecording,
                    botSpeaking: _botSpeaking,
                    blinkController: _blinkController,
                    speakController: _speakController,
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: _messages.length,
                      itemBuilder: (_, index) {
                        final msg = _messages[index];
                        if (msg.isTyping) {
                          return TypingIndicator(
                            typingController: _typingController,
                          );
                        }
                        if (msg.type == 'bot') {
                          return _buildBotBubble(msg, index);
                        }
                        return UserBubble(msg: msg);
                      },
                    ),
                  ),
                  if (_isRecording)
                    ListeningBanner(
                      blinkController: _blinkController,
                      liveTranscript: _liveTranscript,
                      onDeleteTranscript: _onDeleteTranscript,
                      onStop: _stopRecordingAndSubmit,
                    ),
                  VoiceModeInputBar(
                    textController: _textController,
                    inputFocus: _inputFocus,
                    isRecording: _isRecording,
                    botSpeaking: _botSpeaking,
                    voiceAvailable: _voiceAvailable,
                    hasDraftText: _hasDraftText,
                    onSubmitText: _submitTypedMessage,
                    onMicTap: _onMicTap,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _lastBotIndex() {
    for (int i = _messages.length - 1; i >= 0; i--) {
      final m = _messages[i];
      if (m.type == 'bot' && !m.isTyping) {
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

  Widget _buildBotBubble(ChatMessage msg, int index) {
    final isLastBot = index == _lastBotIndex();
    final visibleText = _visibleBotText(index, msg.text);
    // Skip is offered exclusively as a suggestion chip — the per-trigger
    // Skip pill was removed from DocumentTrigger so we no longer need to
    // dedup. Show every chip as-is.
    final List<String> visibleChips = List<String>.from(msg.chips ?? const []);

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
        title: AppLocalizations.of(context).voice_policyVerified,
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
              const BotAvatar(),
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
                      // Suppress the bot text on validation-failure cards —
                      // the card itself shows the failure reason, so rendering
                      // `visibleText` here would duplicate it.
                      if (!(msg.validationFailedAngles.isNotEmpty ||
                          msg.validationFailedLegacy))
                        FormattedText(
                          text: visibleText,
                          baseStyle: const TextStyle(
                            fontSize: 14,
                            color: kVmDark,
                            height: 1.4,
                          ),
                        ),
                      if (_showSampleOf(msg))
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: GestureDetector(
                            onTap: () => _openSampleImagesViewer(msg),
                            child: Text(
                              AppLocalizations.of(context).chat_seeSample,
                              style: const TextStyle(
                                fontSize: 13,
                                color: kVmBlue,
                                decoration: TextDecoration.underline,
                                decorationColor: kVmBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (msg.validationFailedAngles.isNotEmpty)
                        ImageValidationFailureList(
                          angles: msg.validationFailedAngles,
                          angleImages: _angleImages,
                          failedAnglePaths: _failedAnglePaths,
                          failureReason: msg.text,
                          uploadingFiles: _uploadingFiles,
                          botTyping: _botTyping,
                          groupAlreadyUploaded:
                              msg.validationGroupKey != null &&
                              _uploadedGroupKeys.contains(
                                msg.validationGroupKey,
                              ),
                          onPickAngleImage: _onPickAngleImage,
                          onSubmit: () =>
                              _onSubmitAngleImages(originatingMsg: msg),
                        ),
                      if (msg.validationTimeoutRetry)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: ElevatedButton.icon(
                              onPressed: _botTyping || _uploadingFiles
                                  ? null
                                  : () => _onValidationTimeoutRetry(msg),
                              icon: const Icon(Icons.refresh, size: 16),
                              label: Text(AppLocalizations.of(context).voice_tryAgain),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kVmBlue,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (msg.validationFailedLegacy)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: ImageTrigger(
                            angles: const [],
                            minCount: 0,
                            maxCount: _maxImages,
                            angleImages: _angleImages,
                            onPickAngleImage: _onPickAngleImage,
                            onRemoveAngleImage: _onRemoveAngleImage,
                            onSubmitAngleImages: () =>
                                _onSubmitAngleImages(originatingMsg: msg),
                            legacyImages: _pickedImages,
                            legacyMaxImages: _maxImages,
                            onPickImages: _onPickImages,
                            onRemoveImage: _onRemoveImage,
                            onSubmitImages: _onSubmitImages,
                            uploadingFiles: _uploadingFiles,
                            botTyping: _botTyping,
                          ),
                        ),
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
              child: ChatChips(
                options: visibleChips,
                onSelect: _handleChipSelection,
              ),
            ),
          ],

          // Trigger widgets — only on the latest bot message, after speech.
          if (isLastBot &&
              !_botTyping &&
              !_isCurrentlySpeaking(index) &&
              (msg.triggers.isNotEmpty || _isSkippable(msg))) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 46),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _effectiveTriggers(msg)
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
              child: PillButton(
                icon: Icons.check_circle_outline,
                label: AppLocalizations.of(context).common_close,
                onTap: () => _onCloseConversation(msg),
                isLoading: _closingConversation,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // TRIGGER WIDGETS
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildTriggerButton(String trigger, ChatMessage msg) {
    switch (trigger) {
      case 'GET_DATE_TIME':
        return DateTimeTrigger(
          selectedDate: _dtDate,
          selectedTime: _dtTime,
          onPickDate: _pickIncidentDate,
          onPickTime: _pickIncidentTime,
          onConfirm: _confirmIncidentDateTime,
        );
      case 'GET_LOCATION':
        return LocationTrigger(
          controller: _locationController,
          onSubmit: _onSubmitLocation,
          onUseCurrent: _onUseCurrentLocation,
          fetchingLocation: _fetchingLocation,
        );
      case 'GET_IMAGE':
        final angles = _allowedAnglesOf(msg);
        return ImageTrigger(
          angles: angles,
          minCount: _payloadInt(msg, 'min_count') ?? angles.length,
          maxCount: _payloadInt(msg, 'max_count') ?? angles.length,
          angleImages: _angleImages,
          onPickAngleImage: _onPickAngleImage,
          onRemoveAngleImage: _onRemoveAngleImage,
          onSubmitAngleImages: () => _onSubmitAngleImages(originatingMsg: msg),
          legacyImages: _pickedImages,
          legacyMaxImages: _maxImages,
          onPickImages: _onPickImages,
          onRemoveImage: _onRemoveImage,
          onSubmitImages: _onSubmitImages,
          uploadingFiles: _uploadingFiles,
          botTyping: _botTyping,
        );
      case 'GET_DOCUMENT':
        return DocumentTrigger(
          minCount: _payloadInt(msg, 'min_count') ?? 1,
          maxCount: _payloadInt(msg, 'max_count') ?? _maxDocuments,
          alreadyUploaded: _docTriggerProgress[msg]?.count ?? 0,
          pickedDocuments: _pickedDocuments,
          maxDocuments: _maxDocuments,
          uploadingFiles: _uploadingFiles,
          onPickDocuments: _onPickDocuments,
          onRemoveDocument: _onRemoveDocument,
          onSubmitDocuments: () => _onSubmitDocuments(msg),
          onSkipDocuments: _onSkipDocuments,
        );
      case 'SUBMIT_CLAIM':
        final claimMsg = _messages.lastWhere(
          (m) => m.claimData != null && m.claimData!.isNotEmpty,
          orElse: () => const ChatMessage(text: '', type: 'bot'),
        );
        return SubmitClaimTrigger(
          claimData: claimMsg.claimData,
          onSubmit: _onSubmitClaim,
          isSubmitting: _submittingClaim,
        );
      case 'SKIP':
        return GestureDetector(
          onTap: () => _handleChipSelection('Skip'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kVmBlue),
            ),
            child: const Text(
              'Skip',
              style: TextStyle(
                fontSize: 13,
                color: kVmBlue,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  // Helpers to read GET_IMAGE constraints from a message payload.
  List<String> _allowedAnglesOf(ChatMessage msg) {
    final raw = msg.payload?['allowed_angles'];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList(growable: false);
    }
    return const [];
  }

  /// Whether the bot's `GET_IMAGE` payload requested showing the bundled
  /// Whether the bot's payload marks this question as skippable
  /// (`payload.is_skippable == true`). Drives an inline Skip pill alongside
  /// trigger cards when the AI didn't already emit a standalone `SKIP`
  /// trigger.
  bool _isSkippable(ChatMessage msg) {
    final raw = msg.payload?['is_skippable'];
    if (raw is bool && raw) return true;
    if (raw is num && raw != 0) return true;
    if (raw is String) {
      final v = raw.trim().toLowerCase();
      if (v == 'true' || v == '1' || v == 'yes') return true;
    }
    // Some AI turns advertise skippability only via a "Skip" suggestion
    // chip (e.g. GET_DOCUMENT for supporting_docs). Treat that as skippable
    // so the inline Skip pill renders alongside the trigger card.
    final chips = msg.chips;
    if (chips != null && chips.any((s) => s.trim().toLowerCase() == 'skip')) {
      return true;
    }
    return false;
  }

  /// Returns `msg.triggers` plus an implicit `SKIP` when `is_skippable` is
  /// set on the payload but `SKIP` isn't already in triggers. De-duplicated.
  ///
  /// `GET_DOCUMENT` renders its own Skip pill via [DocumentTrigger], so we
  /// strip any sibling `SKIP` to avoid showing two Skip controls on the
  /// same turn.
  List<String> _effectiveTriggers(ChatMessage msg) {
    if (msg.triggers.contains('GET_DOCUMENT')) {
      return msg.triggers.where((t) => t != 'SKIP').toList(growable: false);
    }
    // If a "Skip" suggestion chip is already rendered, don't also add a
    // SKIP trigger pill — that produced two Skip controls on the same turn.
    final hasSkipChip = (msg.chips ?? const [])
        .any((s) => s.trim().toLowerCase() == 'skip');
    if (hasSkipChip) {
      return msg.triggers.where((t) => t != 'SKIP').toList(growable: false);
    }
    if (!_isSkippable(msg) || msg.triggers.contains('SKIP')) {
      return msg.triggers;
    }
    return [...msg.triggers, 'SKIP'];
  }

  /// sample-photos affordance (`payload.show_sample == true`).
  bool _showSampleOf(ChatMessage msg) {
    if (!msg.triggers.contains('GET_IMAGE')) return false;
    final raw = msg.payload?['show_sample'];
    if (raw is bool) return raw;
    if (raw is String) return raw.toLowerCase() == 'true';
    return false;
  }

  void _openSampleImagesViewer(ChatMessage msg) {
    if (!_showSampleOf(msg)) return;
    showSampleImagesDialog(
      context: context,
      assetPaths: const ['assets/images/damage_photos_sample.png'],
      labels: const [],
    );
  }

  int? _payloadInt(ChatMessage msg, String key) {
    final raw = msg.payload?[key];
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
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
    final l = AppLocalizations.of(context);
    switch (k) {
      case 'vehicle photos':
      case 'vehicle photos count':
        return l.voice_group_vehiclePhotos;
      case 'damage photos':
      case 'damage photos count':
        return l.voice_group_damageVehiclePhotos;
      case 'driver license':
      case 'driving license':
      case 'license photos':
      case 'license photos count':
        return l.voice_group_drivingLicense;
      case 'supporting docs':
      case 'supporting documents':
        return l.voice_group_uploadedDocuments;
      case 'police report':
      case 'police report count':
        return l.voice_group_policeReport;
      case 'bill invoice':
      case 'invoice':
      case 'invoice count':
        return l.voice_group_invoice;
      case 'repair bill':
      case 'repair bill count':
        return l.voice_group_repairBill;
      default:
        return key.replaceAll(' Count', '');
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
    required ChatMessage msg,
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

    return FinalSummaryCard(
      introVisibleText: _visibleBotText(index, msg.text),
      hasIntroText: msg.text.trim().isNotEmpty,
      basicFields: basic,
      incidentFields: incident,
      documentFields: documents,
      isCurrentlySpeaking: _isCurrentlySpeaking(index),
      isLastBot: isLastBot,
      botTyping: _botTyping,
      confirming: _confirmingFinalSummary,
      onConfirm: () => _onConfirmFinalSummary(msg),
    );
  }

  // ─── Policy / Summary Card ──────────────────────────────────────────────
  Widget _buildPolicyCard({
    required ChatMessage msg,
    required String title,
    required Map<String, String> fields,
    required String introText,
    required bool isLastBot,
    required int index,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row with avatar + intro text bubble (intro is what we speak).
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BotAvatar(),
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
                    child: FormattedText(
                      text: introText,
                      baseStyle: const TextStyle(
                        fontSize: 14,
                        color: kVmDark,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Card itself (indented under the avatar). Hidden while the intro
          // bubble is still being read aloud.
          if (!_isCurrentlySpeaking(index))
            Padding(
              padding: const EdgeInsets.only(left: 46, top: 10),
              child: PolicyCard(title: title, fields: fields),
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
              child: ChatChips(
                options: msg.chips!,
                onSelect: _handleChipSelection,
              ),
            ),
          ],

          // Trigger widgets on last bot message.
          if (isLastBot &&
              !_botTyping &&
              !_isCurrentlySpeaking(index) &&
              (msg.triggers.isNotEmpty || _isSkippable(msg))) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 46),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _effectiveTriggers(msg)
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
              child: PillButton(
                icon: Icons.check_circle_outline,
                label: AppLocalizations.of(context).common_close,
                onTap: () => _onCloseConversation(msg),
                isLoading: _closingConversation,
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

  /// Yellow info banner shown above the chat when the device is missing the
  /// STT or TTS pack for the active app language. The mic still works — STT
  /// has fallen back to English — but the user needs to know so they can
  /// either install the pack or expect English recognition.
  Widget _buildLanguagePackBanner() {
    final l = AppLocalizations.of(context);
    final langName =
        AppLocales.displayNames[_currentLanguageCode] ?? _currentLanguageCode;
    final copy = _PackMissingCopy.forLanguage(_currentLanguageCode);
    final message = _sttPackMissing && _ttsPackMissing
        ? copy.both(langName)
        : _sttPackMissing
            ? copy.stt(langName)
            : copy.tts(langName);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6DC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE5C46B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Color(0xFF8A6D1A), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  color: Color(0xFF5A4708), fontSize: 12, height: 1.3),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(0, 28),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => openAppSettings(),
            child: Text(l.voice_settingsAction,
                style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

/// Localised copy for the pack-missing banner. Inlined here (rather than added
/// to the .arb files) because the banner is diagnostic-only — touching every
/// generated localisation file for three strings would be heavy churn for the
/// purpose. Falls back to English for languages we don't have copy for.
class _PackMissingCopy {
  final String Function(String lang) stt;
  final String Function(String lang) tts;
  final String Function(String lang) both;
  const _PackMissingCopy(this.stt, this.tts, this.both);

  static _PackMissingCopy forLanguage(String code) {
    final lang = code.toLowerCase().split(RegExp(r'[-_]')).first;
    return _map[lang] ?? _map['en']!;
  }

  static final Map<String, _PackMissingCopy> _map = {
    'en': _PackMissingCopy(
      (l) => 'Speech recognition pack for $l is not installed — '
          'voice input will fall back to English.',
      (l) => 'Voice for $l is not installed — the assistant will reply '
          'in English audio.',
      (l) => 'Voice packs for $l are not installed — voice will use English.',
    ),
    'de': _PackMissingCopy(
      (l) => 'Spracherkennungspaket für $l ist nicht installiert – '
          'Spracheingabe wechselt auf Englisch.',
      (l) => 'Sprachausgabe für $l ist nicht installiert – Antworten werden '
          'auf Englisch gesprochen.',
      (l) => 'Sprachpakete für $l fehlen – Englisch wird verwendet.',
    ),
    'it': _PackMissingCopy(
      (l) => 'Il pacchetto di riconoscimento vocale per $l non è installato — '
          'l\'input vocale userà l\'inglese.',
      (l) => 'La voce per $l non è installata — l\'assistente parlerà in '
          'inglese.',
      (l) => 'I pacchetti vocali per $l non sono installati — verrà usato '
          'l\'inglese.',
    ),
    'fr': _PackMissingCopy(
      (l) => 'Le pack de reconnaissance vocale pour $l n\'est pas installé — '
          'la saisie vocale utilisera l\'anglais.',
      (l) => 'La voix $l n\'est pas installée — l\'assistant répondra en '
          'anglais.',
      (l) => 'Les packs vocaux pour $l ne sont pas installés — l\'anglais '
          'sera utilisé.',
    ),
    'es': _PackMissingCopy(
      (l) => 'El paquete de reconocimiento de voz para $l no está instalado — '
          'la entrada por voz usará inglés.',
      (l) => 'La voz para $l no está instalada — el asistente responderá en '
          'inglés.',
      (l) => 'Los paquetes de voz para $l no están instalados — se usará '
          'inglés.',
    ),
    'pl': _PackMissingCopy(
      (l) => 'Pakiet rozpoznawania mowy dla $l nie jest zainstalowany — '
          'wejście głosowe użyje języka angielskiego.',
      (l) => 'Głos $l nie jest zainstalowany — asystent odpowie po '
          'angielsku.',
      (l) => 'Brak pakietów głosowych dla $l — zostanie użyty angielski.',
    ),
    'lt': _PackMissingCopy(
      (l) => '$l kalbos atpažinimo paketas neįdiegtas — balso įvestis bus '
          'anglų kalba.',
      (l) => '$l balsas neįdiegtas — asistentas atsakys angliškai.',
      (l) => '$l balso paketai neįdiegti — bus naudojama anglų kalba.',
    ),
    'lv': _PackMissingCopy(
      (l) => '$l runas atpazīšanas pakotne nav instalēta — balss ievade '
          'pārslēgsies uz angļu valodu.',
      (l) => '$l balss nav instalēta — asistents atbildēs angliski.',
      (l) => '$l balss pakotnes nav instalētas — tiks lietota angļu valoda.',
    ),
  };
}

/// Keyword-based detector for "is the bot asking for a vehicle registration
/// number right now?". The bot text is generated by an external AI service in
/// the user's selected language; there is no structured `triggers` value for
/// the plate prompt, so we look for the localised noun stem ("plate" / "targa"
/// / "Kennzeichen" / "reģistrācijas numuru" / …) in the most recent bot
/// message. False positives would mis-rewrite normal sentences, so the list
/// is intentionally narrow.
class _PlatePromptDetector {
  // Each language's list covers the noun stems the bot has been observed to
  // use when asking for a plate. Keep this loose enough to catch wording
  // variants (the bot doesn't always pick the same noun across turns) but
  // narrow enough that ordinary sentences in the same language don't trip
  // it. Matching is substring + case-insensitive, so a stem like "fahrzeug"
  // alone would mis-fire on unrelated vehicle questions — prefer compounds.
  static const Map<String, List<String>> _keywords = {
    'en': [
      'plate', 'license plate', 'registration number', 'vehicle number',
      'vehicle registration', 'reg number',
    ],
    'de': [
      'kennzeichen', 'nummernschild', 'amtliches kennzeichen',
      // Compounds the bot uses for "vehicle registration number".
      'fahrzeugregistrierungsnummer', 'fahrzeugkennzeichen',
      'fahrzeugnummer', 'kfz-kennzeichen', 'kfz kennzeichen',
      'autokennzeichen', 'registrierungsnummer',
    ],
    'it': [
      'targa', 'numero di targa', 'numero della targa',
      'numero di immatricolazione', 'immatricolazione',
    ],
    'fr': [
      'immatriculation', 'plaque', 'plaque d\'immatriculation',
      'numéro d\'immatriculation', 'numero d\'immatriculation',
    ],
    'es': [
      'matricula', 'matrícula', 'placa', 'número de matrícula',
      'numero de matricula', 'número de placa',
    ],
    'pl': [
      'tablica rejestracyjna', 'numer rejestracyjny', 'rejestracyjny',
      'numer tablicy', 'rejestracja pojazdu',
    ],
    'lt': [
      'valstybinis numeris', 'registracijos numer', 'numerio',
      'transporto priemones numer',
    ],
    'lv': [
      'reģistrācijas numur', 'registracijas numur', 'numura zīme',
      'valsts numur', 'transportlīdzekļa numur',
    ],
  };

  static bool matches(String botText, String languageCode) {
    if (botText.isEmpty) return false;
    final hay = botText.toLowerCase();
    final lang = languageCode.toLowerCase().split(RegExp(r'[-_]')).first;
    final list = _keywords[lang] ?? _keywords['en']!;
    for (final kw in list) {
      if (hay.contains(kw.toLowerCase())) return true;
    }
    // Always also check English keywords — the bot occasionally falls back
    // to English snippets even when the active language is set.
    for (final kw in _keywords['en']!) {
      if (hay.contains(kw)) return true;
    }
    return false;
  }
}
