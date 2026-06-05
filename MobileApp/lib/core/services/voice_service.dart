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
  static const Duration restartDelay = Duration(milliseconds: 150);
  static const Duration realSilenceTimeout = Duration(seconds: 5);

  /// If a final result arrived AND the user has been silent for at least this
  /// long, skip the restart on the next `done` status. The silence watcher
  /// will stop the session shortly after via [realSilenceTimeout]; restarting
  /// in this window just produces an extra native session (and an extra mic
  /// chime pair) for no captured speech.
  static const Duration _postFinalSilenceSkipRestart = Duration(seconds: 2);
  static const Duration maxListenDuration = Duration(minutes: 5);
  static const Duration maxPauseDuration = Duration(seconds: 30);
  static const Duration silenceWatcherInterval = Duration(milliseconds: 500);

  /// Errors that do not warrant tearing down the session — restart instead.
  /// `error_client` is the Android ERROR_CLIENT race that fires intermittently
  /// when listen() is invoked before the previous native session has fully
  /// released, or on OEM ASR hiccups. We restart with the same tight delay
  /// used for the natural mid-sentence cutoff so the platform doesn't get a
  /// chance to play the mic end/start sounds between sessions.
  static const Set<String> _transientErrors = {
    'error_no_match',
    'error_speech_timeout',
    'error_busy',
    'error_recognizer_busy',
    'error_client',
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

  /// True once the engine has emitted at least one `finalResult` in the
  /// current user-listen session. Used to decide whether a `done` status that
  /// follows extended silence should restart the engine or just let the
  /// silence watcher stop us.
  bool _hadFinalThisSession = false;

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

  /// Picks the best STT locale available on the device for [languageCode]
  /// (e.g. `'it'`, `'hi'`, `'en'`). Preference:
  ///   1. exact `lang_COUNTRY` match (case-insensitive, `-` or `_` separator)
  ///   2. device system locale if it starts with [languageCode]
  ///   3. any available locale starting with `<lang>_` (or matching the bare
  ///      language code)
  /// Returns null if the engine isn't initialized or no matching locale is
  /// available; the caller can fall back to a default in [start].
  Future<String?> resolveLocaleFor(
    String languageCode, [
    String? countryCode,
  ]) async {
    if (!_initialized) return null;
    final lang = languageCode.toLowerCase();
    try {
      final available = await _speech.locales();
      final ids = available.map((l) => l.localeId).toList();

      // 1) Exact lang+country, tolerating `_` vs `-` separators.
      if (countryCode != null && countryCode.isNotEmpty) {
        final cc = countryCode.toUpperCase();
        final wantU = '${lang}_$cc';
        final wantD = '$lang-$cc';
        for (final id in ids) {
          final n = id.replaceAll('-', '_');
          if (n.toLowerCase() == wantU.toLowerCase() ||
              id.toLowerCase() == wantD.toLowerCase()) {
            return id;
          }
        }
      }

      // 2) System locale, if it speaks the requested language.
      final system = await _speech.systemLocale();
      final sysId = system?.localeId;
      if (sysId != null &&
          sysId.toLowerCase().startsWith(lang) &&
          ids.contains(sysId)) {
        return sysId;
      }

      // 3) Any locale starting with the requested language code.
      for (final id in ids) {
        final n = id.toLowerCase().replaceAll('-', '_');
        if (n == lang || n.startsWith('${lang}_')) return id;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[voice] resolveLocaleFor failed: $e');
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
    _hadFinalThisSession = false;
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
      _hadFinalThisSession = true;
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
      // If a final result already arrived in this session and the user has
      // been quiet for ≥ [_postFinalSilenceSkipRestart], the user is done
      // talking — the silence watcher will stop us shortly via
      // [realSilenceTimeout]. Skipping the restart here avoids an extra
      // native session that produces a second mic chime pair and re-emits
      // tail-buffer text (the source of "GJ 01 ab GJ 0 1 ab" duplicates).
      final silentFor = DateTime.now().difference(_lastSoundActivity);
      if (_hadFinalThisSession && silentFor >= _postFinalSilenceSkipRestart) {
        if (kDebugMode) {
          debugPrint('[voice] skipping restart: had final, silent '
              '${silentFor.inMilliseconds}ms');
        }
        return;
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

  /// Collapse a string to lowercase alphanumerics only — used to compare
  /// suffix/slice in [_mergeText] so that tokenization or punctuation
  /// differences across a restart boundary (e.g. `"01"` vs `"0 1"`,
  /// `"hello"` vs `"hello,"`, `"GJ01AB"` vs `"gj 01 ab"`) still count as a
  /// match. Only used for comparison — the original text is preserved in
  /// the merged output.
  String _normalizeForMatch(String s) {
    final buf = StringBuffer();
    for (final r in s.runes) {
      final c = String.fromCharCode(r);
      if (RegExp(r'[A-Za-z0-9]').hasMatch(c)) {
        buf.write(c.toLowerCase());
      }
    }
    return buf.toString();
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

    // Search for the longest prev-suffix that matches a slice near the start
    // of `next`. `k` is the number of leading `next` words skipped — k=0 is
    // the strict prefix match (handles ordinary engine re-emission); k>0
    // tolerates a short hallucinated/noise prefix the recognizer sometimes
    // inserts on restart (e.g. "jije" before re-emitting "01 ab 998").
    const maxNoisePrefix = 3;
    final kLimit = nextWords.length <= 1
        ? 0
        : (nextWords.length - 1 < maxNoisePrefix
            ? nextWords.length - 1
            : maxNoisePrefix);

    int bestK = -1;
    int bestOverlap = 0;
    for (int k = 0; k <= kLimit; k++) {
      final remaining = nextWords.length - k;
      final maxCheck =
          prevWords.length < remaining ? prevWords.length : remaining;
      for (int i = maxCheck; i > 0; i--) {
        // Single-word coincidences are too noisy once we're skipping prefix
        // words — only the strict k=0 path accepts a one-word overlap.
        if (k > 0 && i < 2) break;
        final prevSuffix = prevWords.sublist(prevWords.length - i).join(' ');
        final nextSlice = nextWords.sublist(k, k + i).join(' ');
        // Normalized compare so "01" matches "0 1", "hello" matches "hello,"
        // etc. Only the *comparison* is normalized — the words appended back
        // into the merged transcript are still the original `nextWords`
        // slice with their original spacing and punctuation.
        if (_normalizeForMatch(prevSuffix) == _normalizeForMatch(nextSlice)) {
          if (i > bestOverlap) {
            bestOverlap = i;
            bestK = k;
          }
          break;
        }
      }
    }

    if (bestOverlap > 0) {
      final remaining = nextWords.sublist(bestK + bestOverlap).join(' ');
      return remaining.isEmpty ? p : '$p $remaining'.trim();
    }
    return '$p $n';
  }
}
