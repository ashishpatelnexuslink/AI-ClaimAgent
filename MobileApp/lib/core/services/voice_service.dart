import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Production-grade speech-to-text wrapper that survives the platform's
/// hardcoded mid-sentence cutoff.
///
/// Both iOS `SFSpeechRecognizer` and Android `SpeechRecognizer` endpoint
/// after ~2s of silence regardless of the `pauseFor` parameter. Rather than
/// fight that, this service:
///   1. Lets the native engine cut off naturally.
///   2. Restarts it within [restartDelay] (50ms).
///   3. Accumulates text across restarts with overlap dedup ([_mergeText]).
///   4. Detects "real" silence ourselves via the sound-level stream.
///   5. Only stops when the user has been actually silent for
///      [realSilenceTimeout].
class VoiceService {
  // ─── Tunables ──────────────────────────────────────────────────────────
  static const Duration restartDelay = Duration(milliseconds: 50);
  static const Duration realSilenceTimeout = Duration(seconds: 5);
  static const Duration maxListenDuration = Duration(minutes: 5);
  static const Duration maxPauseDuration = Duration(seconds: 30);
  static const Duration silenceWatcherInterval = Duration(milliseconds: 500);

  /// Errors that do not warrant tearing down the session — restart instead.
  static const Set<String> _transientErrors = {
    'error_no_match',
    'error_speech_timeout',
    'error_busy',
    'error_recognizer_busy',
  };

  // ─── Callbacks ─────────────────────────────────────────────────────────
  void Function(String liveText)? onTextUpdate;
  void Function(String finalText)? onFinalText;
  void Function(String error)? onError;
  void Function(double level)? onSoundLevel;
  void Function(bool isActive)? onListeningChange;

  // ─── Internal state ───────────────────────────────────────────────────
  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;
  bool _userWantsToListen = false;

  /// Banked, merged text from completed native sessions.
  String _accumulatedText = '';

  /// Live text from the in-progress native session.
  String _currentSessionText = '';

  /// Longest `recognizedWords` value seen *during* the current session's
  /// partial stream. Android sometimes returns richer text in partials than
  /// in the final, so we keep the longer one as a fallback.
  String _segmentLongestPartial = '';

  String? _activeLocaleId;
  DateTime _lastSoundActivity = DateTime.now();
  Timer? _restartTimer;
  Timer? _silenceWatcher;
  Timer? _maxListenTimer;

  bool get isListening => _userWantsToListen;
  bool get isInitialized => _initialized;

  // ─── Public API ────────────────────────────────────────────────────────
  Future<bool> initialize() async {
    if (_initialized) return true;
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) return false;
    _initialized = await _speech.initialize(
      onError: _onSpeechError,
      onStatus: _onSpeechStatus,
      debugLogging: kDebugMode,
    );
    return _initialized;
  }

  /// Picks the best English locale available on the device. Preference:
  /// device system locale (if English) → en_IN (best for South Asian names)
  /// → en_US → first available `en_*`. Returns null if the engine isn't
  /// initialized or no English locale is available; caller can fall back to
  /// the default in [start].
  Future<String?> resolveBestEnglishLocale() async {
    if (!_initialized) return null;
    try {
      final system = await _speech.systemLocale();
      final available = await _speech.locales();
      final ids = available.map((l) => l.localeId).toList();

      final sysId = system?.localeId;
      if (sysId != null &&
          sysId.toLowerCase().startsWith('en') &&
          ids.contains(sysId)) {
        return sysId;
      }
      if (ids.contains('en_IN')) return 'en_IN';
      if (ids.contains('en_US')) return 'en_US';
      for (final id in ids) {
        if (id.toLowerCase().startsWith('en')) return id;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[voice] resolveLocale failed: $e');
    }
    return null;
  }

  Future<void> start({String localeId = 'en_IN'}) async {
    if (!_initialized) {
      final ok = await initialize();
      if (!ok) {
        onError?.call('permission_denied');
        return;
      }
    }
    if (_userWantsToListen) return;

    _userWantsToListen = true;
    _accumulatedText = '';
    _currentSessionText = '';
    _segmentLongestPartial = '';
    _activeLocaleId = localeId;
    _lastSoundActivity = DateTime.now();

    onListeningChange?.call(true);
    onTextUpdate?.call('');

    _startSilenceWatcher();
    _startMaxListenGuard();
    await _startNativeListen(localeId);
  }

  /// Stop listening and emit the accumulated transcript via [onFinalText].
  Future<void> stop() async {
    if (!_userWantsToListen) return;
    _userWantsToListen = false;
    _cancelTimers();
    if (_currentSessionText.isNotEmpty) {
      _accumulatedText = _mergeText(_accumulatedText, _currentSessionText);
      _currentSessionText = '';
    }
    if (_speech.isListening) {
      try {
        await _speech.stop();
      } catch (_) {}
    }
    final finalText = _accumulatedText.trim();
    onListeningChange?.call(false);
    onFinalText?.call(finalText);
  }

  /// Wipe everything captured so far without stopping the session. The
  /// silence clock is also reset so the user has the full
  /// [realSilenceTimeout] window to start speaking again. Emits an empty
  /// [onTextUpdate] so the UI can clear its banner.
  void resetTranscript() {
    if (!_userWantsToListen) return;
    _accumulatedText = '';
    _currentSessionText = '';
    _segmentLongestPartial = '';
    _lastSoundActivity = DateTime.now();
    onTextUpdate?.call('');
  }

  /// Stop listening and discard everything captured so far. No emission.
  Future<void> cancel() async {
    _userWantsToListen = false;
    _cancelTimers();
    _accumulatedText = '';
    _currentSessionText = '';
    _segmentLongestPartial = '';
    if (_speech.isListening) {
      try {
        await _speech.cancel();
      } catch (_) {}
    }
    onListeningChange?.call(false);
  }

  void dispose() {
    _userWantsToListen = false;
    _cancelTimers();
    onTextUpdate = null;
    onFinalText = null;
    onError = null;
    onSoundLevel = null;
    onListeningChange = null;
    try {
      _speech.cancel();
    } catch (_) {}
  }

  // ─── Native session management ────────────────────────────────────────
  Future<void> _startNativeListen(String localeId) async {
    if (!_userWantsToListen) return;
    if (_speech.isListening) return;
    _segmentLongestPartial = '';
    try {
      await _speech.listen(
        onResult: _onSpeechResult,
        onSoundLevelChange: _onSoundLevelInternal,
        localeId: localeId,
        listenFor: maxListenDuration,
        pauseFor: maxPauseDuration,
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenMode: ListenMode.dictation,
          autoPunctuation: true,
          enableHapticFeedback: false,
        ),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[voice] listen() threw: $e');
      _scheduleRestart(localeId);
    }
  }

  void _scheduleRestart(String localeId) {
    _restartTimer?.cancel();
    _restartTimer = Timer(restartDelay, () async {
      if (!_userWantsToListen) return;
      if (_speech.isListening) return;
      await _startNativeListen(localeId);
    });
  }

  // ─── Engine callbacks ─────────────────────────────────────────────────
  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!_userWantsToListen) return;
    final words = result.recognizedWords;

    if (kDebugMode) {
      debugPrint(
        '[voice] partial="$words" final=${result.finalResult} '
        'alts=${result.alternates.length}',
      );
    }

    if (_isLongerByWords(words, _segmentLongestPartial)) {
      _segmentLongestPartial = words;
    }
    for (final alt in result.alternates) {
      if (_isLongerByWords(alt.recognizedWords, _segmentLongestPartial)) {
        _segmentLongestPartial = alt.recognizedWords;
      }
    }

    final best = _isLongerByWords(_segmentLongestPartial, words)
        ? _segmentLongestPartial
        : words;

    if (result.finalResult) {
      if (best.trim().isNotEmpty) {
        _accumulatedText = _mergeText(_accumulatedText, best);
        _lastSoundActivity = DateTime.now();
      }
      _currentSessionText = '';
      _segmentLongestPartial = '';
      onTextUpdate?.call(_accumulatedText);
      // Don't restart here — the status callback will follow with `done`
      // and trigger the restart from a single, canonical place.
    } else {
      _currentSessionText = best;
      if (best.trim().isNotEmpty) {
        _lastSoundActivity = DateTime.now();
      }
      onTextUpdate?.call(_mergeText(_accumulatedText, _currentSessionText));
    }
  }

  void _onSpeechStatus(String status) {
    if (kDebugMode) debugPrint('[voice] status=$status');
    if (!_userWantsToListen) return;
    if (status == 'done' || status == 'notListening') {
      // Bank any partial that hadn't been finalized by the engine.
      if (_currentSessionText.isNotEmpty) {
        _accumulatedText = _mergeText(_accumulatedText, _currentSessionText);
        _currentSessionText = '';
        _segmentLongestPartial = '';
        onTextUpdate?.call(_accumulatedText);
      }
      _scheduleRestart(_activeLocaleId ?? 'en_IN');
    }
  }

  void _onSpeechError(SpeechRecognitionError err) {
    if (kDebugMode) {
      debugPrint('[voice] error=${err.errorMsg} permanent=${err.permanent}');
    }
    final transient = _transientErrors.contains(err.errorMsg);
    if (transient || !err.permanent) {
      if (_userWantsToListen) {
        _scheduleRestart(_activeLocaleId ?? 'en_IN');
      }
      return;
    }
    onError?.call(err.errorMsg);
    _userWantsToListen = false;
    _cancelTimers();
    onListeningChange?.call(false);
  }

  void _onSoundLevelInternal(double level) {
    if (!_userWantsToListen) return;
    onSoundLevel?.call(level);
    // Intentionally do NOT reset the silence clock on raw amplitude. The
    // platform recognizer already does speech-vs-noise discrimination and
    // only emits partial/final results when it hears actual speech, so we
    // rely on those callbacks alone (in [_onSpeechResult]) to mark activity.
    // Using sound level here was pinning the clock open via mic hiss /
    // ambient noise, especially on Android where levels rarely drop below
    // the previous -2.0 threshold even in silence.
  }

  // ─── Silence + safety watchers ────────────────────────────────────────
  void _startSilenceWatcher() {
    _silenceWatcher?.cancel();
    _silenceWatcher = Timer.periodic(silenceWatcherInterval, (_) {
      if (!_userWantsToListen) return;
      final since = DateTime.now().difference(_lastSoundActivity);
      if (kDebugMode && since.inSeconds >= 2) {
        debugPrint('[voice] silence ${since.inSeconds}s / '
            '${realSilenceTimeout.inSeconds}s');
      }
      if (since >= realSilenceTimeout) {
        if (kDebugMode) debugPrint('[voice] silence timeout → stop()');
        stop();
      }
    });
  }

  void _startMaxListenGuard() {
    _maxListenTimer?.cancel();
    _maxListenTimer = Timer(maxListenDuration, () {
      if (_userWantsToListen) {
        if (kDebugMode) debugPrint('[voice] max listen duration reached');
        stop();
      }
    });
  }

  void _cancelTimers() {
    _restartTimer?.cancel();
    _restartTimer = null;
    _silenceWatcher?.cancel();
    _silenceWatcher = null;
    _maxListenTimer?.cancel();
    _maxListenTimer = null;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────
  bool _isLongerByWords(String a, String b) {
    final ac = a.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    final bc = b.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    if (ac != bc) return ac > bc;
    return a.trim().length > b.trim().length;
  }

  /// Merges previously-accumulated text with new session text, deduping any
  /// trailing-suffix / leading-prefix overlap. The native engine sometimes
  /// resends words across a restart boundary; without this, phrases like
  /// "hit by another car" would become "hit by another car by another car".
  String _mergeText(String prev, String next) {
    final p = prev.trim();
    final n = next.trim();
    if (p.isEmpty) return n;
    if (n.isEmpty) return p;

    final prevWords = p.split(RegExp(r'\s+'));
    final nextWords = n.split(RegExp(r'\s+'));
    final maxCheck = prevWords.length < nextWords.length
        ? prevWords.length
        : nextWords.length;

    int overlap = 0;
    for (int i = maxCheck; i > 0; i--) {
      final prevSuffix =
          prevWords.sublist(prevWords.length - i).join(' ').toLowerCase();
      final nextPrefix = nextWords.sublist(0, i).join(' ').toLowerCase();
      if (prevSuffix == nextPrefix) {
        overlap = i;
        break;
      }
    }

    if (overlap > 0) {
      return '$p ${nextWords.sublist(overlap).join(' ')}'.trim();
    }
    return '$p $n';
  }
}
