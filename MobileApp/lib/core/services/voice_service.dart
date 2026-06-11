import 'dart:async';

import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Hint to the recognizer about the shape of the expected utterance.
///
/// Maps to `taskHint` on iOS (`SFSpeechRecognitionTaskHint`) and to
/// [ListenMode] on Android. Picking the right mode meaningfully improves
/// accuracy because the engine swaps in a different language model.
enum VoicePromptMode { dictation, shortAnswer, confirmation }

/// Outcome of resolving an app language code to an installed STT locale on
/// the device. [exactMatch] is true when a locale for the requested language
/// was found; false means we either returned null or had to fall back to
/// some other language, and the UI should tell the user the pack is missing.
class LocaleResolution {
  final String? localeId;

  /// True when the engine *or* our synthesized fallback claims support for
  /// the requested language. False only when neither path produced a tag,
  /// in which case the caller should fall back to English.
  final bool exactMatch;

  /// True when [localeId] was not in `_speech.locales()` and we synthesized
  /// it from `<lang>_<defaultCountry>`. Engines often accept synthesized
  /// tags via online recognition, but some don't — when this is true, the
  /// UI should warn the user that recognition may silently use English.
  final bool synthesized;

  final List<String> availableForLanguage;
  final List<String> allAvailable;
  const LocaleResolution._(
    this.localeId,
    this.exactMatch,
    this.availableForLanguage,
    this.allAvailable, {
    this.synthesized = false,
  });
}

/// Production-grade speech-to-text wrapper that survives the platform's
/// hardcoded mid-sentence cutoff.
///
/// Both iOS `SFSpeechRecognizer` and Android `SpeechRecognizer` endpoint
/// after ~2s of silence regardless of the `pauseFor` parameter. Rather than
/// fight that, this service:
///   1. Lets the native engine cut off naturally.
///   2. Restarts it within [restartDelay] (150ms).
///   3. Accumulates text across restarts with overlap dedup ([_mergeText]).
///   4. Detects "real" silence ourselves via the partial-result stream.
///   5. Only stops when the user has been actually silent for
///      [_activeRealSilenceTimeout] (per prompt mode).
class VoiceService {
  // ─── Tunables ──────────────────────────────────────────────────────────
  static const Duration restartDelay = Duration(milliseconds: 150);

  /// Post-speech silence timeout for short answers (plate, VIN, date).
  /// Dictation gets [_dictationSilenceTimeout]; confirmation gets
  /// [_confirmationSilenceTimeout].
  static const Duration realSilenceTimeout = Duration(seconds: 5);
  static const Duration _dictationSilenceTimeout = Duration(seconds: 10);
  static const Duration _confirmationSilenceTimeout = Duration(seconds: 3);

  /// Grace window before *any* speech is heard. Some locales (Latvian,
  /// Lithuanian, Polish on Android OEM engines) take 1.5–2s before the first
  /// partial arrives, plus the user themselves may pause to gather thoughts.
  static const Duration initialSilenceTimeout = Duration(seconds: 10);

  /// Per-language override for [initialSilenceTimeout]. Keyed by the bare
  /// language code (e.g. `'lv'`).
  static const Map<String, Duration> _initialSilenceByLang = {
    'lv': Duration(seconds: 14),
    'lt': Duration(seconds: 14),
    'pl': Duration(seconds: 12),
    'de': Duration(seconds: 12),
  };

  /// Languages whose Google / Apple acoustic models reliably support
  /// auto-punctuation. For everything else, the flag is silently ignored on
  /// iOS and disables on-device recognition on some Android OEM engines.
  static const Set<String> _autoPunctuationLangs = {
    'en', 'es', 'fr', 'de', 'it', 'pt', 'ja', 'ko', 'zh',
  };

  /// If a final result arrived AND the user has been silent for at least
  /// this long, skip the restart on the next `done` status — *except* in
  /// dictation mode, where multi-second thinking pauses are normal.
  static const Duration _postFinalSilenceSkipRestart = Duration(seconds: 2);
  static const Duration maxListenDuration = Duration(minutes: 5);
  static const Duration maxPauseDuration = Duration(seconds: 30);
  static const Duration silenceWatcherInterval = Duration(milliseconds: 500);

  /// Errors that do not warrant tearing down the session — restart instead.
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

  /// Fires alongside [onFinalText] with the alternate transcripts of the
  /// last finalResult, ordered best→worst with the primary first. Used by
  /// the screen to pick a better candidate via plate / domain corrections.
  void Function(List<String> alternates)? onFinalAlternates;

  void Function(String error)? onError;
  void Function(double level)? onSoundLevel;
  void Function(bool isActive)? onListeningChange;

  // ─── Internal state ───────────────────────────────────────────────────
  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;
  bool _userWantsToListen = false;

  String _accumulatedText = '';
  String _currentSessionText = '';
  String _segmentLongestPartial = '';

  String? _activeLocaleId;
  DateTime _lastSoundActivity = DateTime.now();

  bool _hadFinalThisSession = false;

  /// True once we have seen any non-empty partial / final from the engine in
  /// this user-listen session. Drives the "initial grace" branch of the
  /// silence watcher.
  bool _firstSpeechSeen = false;

  /// Alternates from the most recent `finalResult` in this session.
  List<String> _lastFinalAlternates = const [];

  VoicePromptMode _promptMode = VoicePromptMode.dictation;

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

  /// Picks the best STT locale available on the device for [languageCode].
  /// Returns just the id; use [resolveLocale] when you need the full
  /// resolution (pack-missing banner state).
  Future<String?> resolveLocaleFor(
    String languageCode, [
    String? countryCode,
  ]) async {
    final r = await resolveLocale(languageCode, countryCode);
    return r.localeId;
  }

  /// Like [resolveLocaleFor] but returns the full resolution so callers can
  /// tell whether the device actually has a pack for the requested language.
  Future<LocaleResolution> resolveLocale(
    String languageCode, [
    String? countryCode,
  ]) async {
    if (!_initialized) {
      return const LocaleResolution._(null, false, [], []);
    }
    final lang = languageCode.toLowerCase();
    try {
      final available = await _speech.locales();
      final ids = available.map((l) => l.localeId).toList();
      final forLang = ids
          .where((id) {
            final n = id.toLowerCase().replaceAll('-', '_');
            return n == lang || n.startsWith('${lang}_');
          })
          .toList();

      // 1) Exact lang+country, tolerating `_` vs `-` separators.
      if (countryCode != null && countryCode.isNotEmpty) {
        final cc = countryCode.toUpperCase();
        final wantU = '${lang}_$cc';
        final wantD = '$lang-$cc';
        for (final id in ids) {
          final n = id.replaceAll('-', '_');
          if (n.toLowerCase() == wantU.toLowerCase() ||
              id.toLowerCase() == wantD.toLowerCase()) {
            return LocaleResolution._(id, true, forLang, ids);
          }
        }
      }

      // 2) System locale, if it speaks the requested language.
      final system = await _speech.systemLocale();
      final sysId = system?.localeId;
      if (sysId != null &&
          sysId.toLowerCase().startsWith(lang) &&
          ids.contains(sysId)) {
        return LocaleResolution._(sysId, true, forLang, ids);
      }

      // 3) Any locale starting with the requested language code.
      for (final id in ids) {
        final n = id.toLowerCase().replaceAll('-', '_');
        if (n == lang || n.startsWith('${lang}_')) {
          return LocaleResolution._(id, true, forLang, ids);
        }
      }
      // 4) Engine didn't list a locale for this language, but most Android
      // engines (Google Speech Services in particular) still accept a BCP-47
      // tag like `de_DE` passed directly to listen() — they route to online
      // recognition. `_speech.locales()` only reports the *offline* installed
      // packs on many OEMs, so an absent entry doesn't mean the engine can't
      // recognize the language. Synthesize the tag from the requested code
      // and a default country and return it as an exact match. The recogniser
      // will either accept it (the common case) or surface an error via
      // [_onSpeechError], at which point the caller can fall back.
      final synthesizedCc = (countryCode != null && countryCode.isNotEmpty)
          ? countryCode.toUpperCase()
          : _defaultCountryFor(lang);
      if (synthesizedCc != null) {
        final synth = '${lang}_$synthesizedCc';
        if (kDebugMode) {
          debugPrint('[voice] resolveLocale: synthesizing "$synth" '
              '(not in engine-reported locales)');
        }
        return LocaleResolution._(synth, true, forLang, ids,
            synthesized: true);
      }
      return LocaleResolution._(null, false, forLang, ids);
    } catch (e) {
      if (kDebugMode) debugPrint('[voice] resolveLocale failed: $e');
      return const LocaleResolution._(null, false, [], []);
    }
  }

  /// Default ISO 3166-1 country code per language, mirroring
  /// `AppLocales.defaultCountryFor`. Kept here so the service doesn't take a
  /// dependency on the l10n layer — voice resolution must work even when
  /// `AppLocales` is unavailable (e.g. in unit tests).
  static const Map<String, String> _defaultCountry = {
    'en': 'US',
    'de': 'DE',
    'it': 'IT',
    'fr': 'FR',
    'es': 'ES',
    'pl': 'PL',
    'lt': 'LT',
    'lv': 'LV',
    'pt': 'PT',
    'nl': 'NL',
  };
  String? _defaultCountryFor(String lang) => _defaultCountry[lang];

  /// Picks the best available English STT locale on the device, in
  /// preference order: system locale (if English) → en_US → en_GB → en_AU
  /// → en_CA → en_IE → en_IN → first available `en_*` → null.
  Future<String?> resolveEnglishFallback() async {
    if (!_initialized) return null;
    try {
      final available = await _speech.locales();
      final ids = available.map((l) => l.localeId).toList();
      String norm(String s) => s.toLowerCase().replaceAll('-', '_');
      bool isEnglish(String id) {
        final n = norm(id);
        return n == 'en' || n.startsWith('en_');
      }

      final system = await _speech.systemLocale();
      final sysId = system?.localeId;
      if (sysId != null && isEnglish(sysId) && ids.contains(sysId)) {
        return sysId;
      }

      const preferred = ['en_US', 'en_GB', 'en_AU', 'en_CA', 'en_IE', 'en_IN'];
      for (final want in preferred) {
        for (final id in ids) {
          if (norm(id) == norm(want)) return id;
        }
      }
      for (final id in ids) {
        if (isEnglish(id)) return id;
      }
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('[voice] resolveEnglishFallback failed: $e');
      return null;
    }
  }

  /// One-shot diagnostic dump of every STT locale the device exposes.
  Future<void> dumpLocales() async {
    if (!kDebugMode) return;
    if (!_initialized) {
      debugPrint('[voice] dumpLocales: engine not initialized');
      return;
    }
    try {
      final locales = await _speech.locales();
      final system = await _speech.systemLocale();
      debugPrint('[voice] system locale: ${system?.localeId} (${system?.name})');
      debugPrint('[voice] available STT locales (${locales.length}):');
      for (final l in locales) {
        debugPrint('  - ${l.localeId} : ${l.name}');
      }
    } catch (e) {
      debugPrint('[voice] dumpLocales failed: $e');
    }
  }

  Future<void> start({
    String localeId = 'en_IN',
    VoicePromptMode mode = VoicePromptMode.dictation,
  }) async {
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
    _firstSpeechSeen = false;
    _lastFinalAlternates = const [];
    _activeLocaleId = localeId;
    _promptMode = mode;
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
    // Fire alternates *before* onFinalText so callers that synchronously
    // act on the final transcript can read the alternates from state.
    if (_lastFinalAlternates.isNotEmpty) {
      onFinalAlternates?.call(List.unmodifiable(_lastFinalAlternates));
    }
    onFinalText?.call(finalText);
  }

  /// Wipe everything captured so far without stopping the session. Restarts
  /// the native engine if it's idle (post-final skip-restart path) so the
  /// user's next utterance after tapping delete isn't dropped.
  void resetTranscript() {
    if (!_userWantsToListen) return;
    _accumulatedText = '';
    _currentSessionText = '';
    _segmentLongestPartial = '';
    _lastFinalAlternates = const [];
    _hadFinalThisSession = false;
    _firstSpeechSeen = false;
    _lastSoundActivity = DateTime.now();
    onTextUpdate?.call('');
    if (!_speech.isListening && _activeLocaleId != null) {
      _scheduleRestart(_activeLocaleId!);
    }
  }

  /// Stop listening and discard everything captured so far. No emission.
  Future<void> cancel() async {
    _userWantsToListen = false;
    _cancelTimers();
    _accumulatedText = '';
    _currentSessionText = '';
    _segmentLongestPartial = '';
    _lastFinalAlternates = const [];
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
    onFinalAlternates = null;
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
          listenMode: _listenModeFor(_promptMode),
          autoPunctuation: _shouldUseAutoPunctuation(localeId, _promptMode),
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

  bool _shouldUseAutoPunctuation(String localeId, VoicePromptMode mode) {
    if (mode == VoicePromptMode.confirmation) return false;
    final lang = localeId.toLowerCase().split(RegExp(r'[-_]')).first;
    return _autoPunctuationLangs.contains(lang);
  }

  ListenMode _listenModeFor(VoicePromptMode mode) {
    switch (mode) {
      case VoicePromptMode.dictation:
        return ListenMode.dictation;
      case VoicePromptMode.shortAnswer:
        return ListenMode.search;
      case VoicePromptMode.confirmation:
        return ListenMode.confirmation;
    }
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
        _firstSpeechSeen = true;
      }
      // Capture alternates for this final, ordered best→worst with the
      // primary transcript first.
      final alts = <String>[];
      void addAlt(String s) {
        final t = s.trim();
        if (t.isEmpty) return;
        if (alts.any((e) => e.toLowerCase() == t.toLowerCase())) return;
        alts.add(t);
      }
      addAlt(best);
      addAlt(words);
      for (final a in result.alternates) {
        addAlt(a.recognizedWords);
      }
      _lastFinalAlternates = alts;
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
        _firstSpeechSeen = true;
      }
      onTextUpdate?.call(_mergeText(_accumulatedText, _currentSessionText));
    }
  }

  void _onSpeechStatus(String status) {
    if (kDebugMode) debugPrint('[voice] status=$status');
    if (!_userWantsToListen) return;
    if (status == 'done' || status == 'notListening') {
      // Bank any partial that hadn't been finalized by the engine. On some
      // Android OEM engines (Samsung, Huawei, Xiaomi) for certain locales
      // the engine *never* emits a `finalResult` — only partials, then
      // `done`. Treat the banked partial as an implicit final.
      if (_currentSessionText.isNotEmpty) {
        _accumulatedText = _mergeText(_accumulatedText, _currentSessionText);
        _currentSessionText = '';
        _segmentLongestPartial = '';
        _hadFinalThisSession = true;
        onTextUpdate?.call(_accumulatedText);
      }
      // In dictation mode never skip the restart. Free-form descriptions
      // routinely have multi-second thinking pauses after an interim final.
      final canSkip = _promptMode != VoicePromptMode.dictation;
      final silentFor = DateTime.now().difference(_lastSoundActivity);
      if (canSkip &&
          _hadFinalThisSession &&
          silentFor >= _postFinalSilenceSkipRestart) {
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
    // platform recognizer already does speech-vs-noise discrimination.
  }

  // ─── Silence + safety watchers ────────────────────────────────────────
  Duration get _activeRealSilenceTimeout {
    switch (_promptMode) {
      case VoicePromptMode.dictation:
        return _dictationSilenceTimeout;
      case VoicePromptMode.shortAnswer:
        return realSilenceTimeout;
      case VoicePromptMode.confirmation:
        return _confirmationSilenceTimeout;
    }
  }

  Duration get _activeInitialSilenceTimeout {
    final id = _activeLocaleId;
    if (id == null) return initialSilenceTimeout;
    final lang = id.toLowerCase().split(RegExp(r'[-_]')).first;
    return _initialSilenceByLang[lang] ?? initialSilenceTimeout;
  }

  void _startSilenceWatcher() {
    _silenceWatcher?.cancel();
    _silenceWatcher = Timer.periodic(silenceWatcherInterval, (_) {
      if (!_userWantsToListen) return;
      final since = DateTime.now().difference(_lastSoundActivity);
      final timeout = _firstSpeechSeen
          ? _activeRealSilenceTimeout
          : _activeInitialSilenceTimeout;
      if (kDebugMode && since.inSeconds >= 2) {
        debugPrint('[voice] silence ${since.inSeconds}s / '
            '${timeout.inSeconds}s '
            '(firstSpeech=$_firstSpeechSeen)');
      }
      if (since >= timeout) {
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

  /// Unicode-aware collapse to lowercase letters/digits only — used to
  /// compare suffix/slice in [_mergeText]. ASCII-only `[A-Za-z0-9]` silently
  /// drops every diacritic, breaking overlap detection across restart
  /// boundaries in de/it/fr/es/pl/lt/lv.
  static final RegExp _letterOrDigit = RegExp(r'[\p{L}\p{N}]', unicode: true);

  String _normalizeForMatch(String s) {
    final buf = StringBuffer();
    for (final r in s.runes) {
      final c = String.fromCharCode(r);
      if (_letterOrDigit.hasMatch(c)) {
        buf.write(c.toLowerCase());
      }
    }
    return buf.toString();
  }

  /// Merges previously-accumulated text with new session text, deduping any
  /// trailing-suffix / leading-prefix overlap.
  String _mergeText(String prev, String next) {
    final p = prev.trim();
    final n = next.trim();
    if (p.isEmpty) return n;
    if (n.isEmpty) return p;

    final prevWords = p.split(RegExp(r'\s+'));
    final nextWords = n.split(RegExp(r'\s+'));

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
        if (k > 0 && i < 2) break;
        final prevSuffix = prevWords.sublist(prevWords.length - i).join(' ');
        final nextSlice = nextWords.sublist(k, k + i).join(' ');
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
