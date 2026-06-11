/// Post-STT domain-vocabulary corrector.
///
/// `speech_to_text` 7.x does not expose iOS `SFSpeechRecognitionRequest`
/// `contextualStrings` or Android `RecognizerIntent` hint extras, so we
/// can't bias the recognizer up-front. Instead, we run the raw transcript
/// through a fuzzy match against a per-language list of claim-domain terms
/// (policy, VIN, registration, deductible, bumper, claim number, ...) plus
/// any dynamic phrases the caller supplies (typically the authenticated
/// user's full name). Tokens within a small edit distance of a known phrase
/// are replaced with the canonical phrase.
///
/// Conservative by design: the threshold scales with phrase length and a
/// single-character word will never be "corrected" (too many false
/// positives). The original text is returned unchanged when no high-
/// confidence match is found, so this is safe to run on every transcript.
library;

class DomainCorrector {
  /// Corrects domain vocabulary in [raw] for the given BCP-47 [languageCode].
  /// [extraPhrases] is appended to the per-language list — pass the user's
  /// full name, policy holder name, or any other session-specific proper
  /// nouns the recognizer would otherwise mangle.
  static String correct(
    String raw,
    String languageCode, {
    List<String> extraPhrases = const [],
  }) {
    if (raw.trim().isEmpty) return raw;
    final lang = languageCode.toLowerCase().split(RegExp(r'[-_]')).first;
    final phrases = <String>[
      ..._phrases[lang] ?? const [],
      ..._phrases['en']!,
      ...extraPhrases.where((p) => p.trim().isNotEmpty),
    ];
    if (phrases.isEmpty) return raw;

    // Sort longest-first so multi-word phrases ("claim number") match before
    // their single-word substrings ("number") and the longer correction wins.
    phrases.sort((a, b) {
      final ac = _wordCount(a);
      final bc = _wordCount(b);
      if (ac != bc) return bc - ac;
      return b.length - a.length;
    });

    // Tokenize once. Whitespace split is enough — we preserve original
    // punctuation by stitching it back from the source slice when emitting.
    final tokens = _tokenize(raw);
    if (tokens.isEmpty) return raw;

    final corrected = List<_Token>.from(tokens);
    final replaced = List<bool>.filled(corrected.length, false);

    for (final phrase in phrases) {
      final pWords = phrase
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .toList();
      if (pWords.isEmpty) continue;
      final pNorm = pWords.map(_normalize).toList();

      for (int i = 0; i + pWords.length <= corrected.length; i++) {
        if (_anyReplaced(replaced, i, pWords.length)) continue;
        final windowNorm = <String>[];
        for (int k = 0; k < pWords.length; k++) {
          windowNorm.add(_normalize(corrected[i + k].word));
        }
        if (_fuzzyMatches(windowNorm, pNorm)) {
          // Replace the first window token with the canonical phrase and
          // blank the rest so the join step skips them.
          corrected[i] = _Token(phrase, corrected[i].trailing);
          for (int k = 1; k < pWords.length; k++) {
            corrected[i + k] = _Token('', corrected[i + k].trailing);
          }
          for (int k = 0; k < pWords.length; k++) {
            replaced[i + k] = true;
          }
        }
      }
    }

    final buf = StringBuffer();
    for (int i = 0; i < corrected.length; i++) {
      final t = corrected[i];
      if (t.word.isEmpty) {
        // Preserve a single space between surrounding kept tokens; drop
        // trailing punctuation that was attached to the consumed token.
        continue;
      }
      if (buf.isNotEmpty &&
          !buf.toString().endsWith(' ') &&
          !_isPunctuationLead(t.word)) {
        buf.write(' ');
      }
      buf.write(t.word);
      buf.write(t.trailing);
    }
    return buf.toString().trim();
  }

  // ─── Internals ────────────────────────────────────────────────────────

  static bool _anyReplaced(List<bool> replaced, int start, int len) {
    for (int k = 0; k < len; k++) {
      if (replaced[start + k]) return true;
    }
    return false;
  }

  static int _wordCount(String s) =>
      s.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

  /// Whitespace-tokenize while preserving any trailing punctuation
  /// (`,`, `.`, `?`, `!`, `;`, `:`) attached to each word, so the corrector
  /// can re-emit punctuation without absorbing it into the match window.
  static List<_Token> _tokenize(String raw) {
    final out = <_Token>[];
    for (final piece in raw.split(RegExp(r'\s+'))) {
      if (piece.isEmpty) continue;
      final m = RegExp(r'^(.*?)([,.?!;:]+)$').firstMatch(piece);
      if (m != null) {
        out.add(_Token(m.group(1)!, m.group(2)!));
      } else {
        out.add(_Token(piece, ''));
      }
    }
    return out;
  }

  static final RegExp _letterOrDigit = RegExp(r'[\p{L}\p{N}]', unicode: true);

  /// Lowercase + strip non-letter/non-digit + remove common diacritics so
  /// "polizza" matches "Polizza," and "vin" matches "VIN". Unicode-aware
  /// for de/pl/it/fr/lt/lv/es.
  static String _normalize(String s) {
    final buf = StringBuffer();
    for (final r in s.runes) {
      final c = String.fromCharCode(r);
      if (_letterOrDigit.hasMatch(c)) buf.write(c.toLowerCase());
    }
    return _foldDiacritics(buf.toString());
  }

  /// Cheap diacritic folding for the European languages we ship. Not a full
  /// NFD pass (Dart's stdlib doesn't expose one), but covers every char in
  /// our domain lists and in typical user names.
  static const Map<String, String> _diacriticFold = {
    'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a', 'ą': 'a',
    'ā': 'a',
    'ç': 'c', 'ć': 'c', 'č': 'c',
    'ď': 'd',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e', 'ę': 'e', 'ė': 'e', 'ē': 'e',
    'ě': 'e',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i', 'į': 'i', 'ī': 'i',
    'ñ': 'n', 'ń': 'n', 'ň': 'n',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o', 'ő': 'o', 'ō': 'o',
    'ø': 'o',
    'ř': 'r',
    'ś': 's', 'š': 's', 'ş': 's', 'ß': 'ss',
    'ť': 't',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u', 'ů': 'u', 'ű': 'u', 'ū': 'u',
    'ų': 'u',
    'ý': 'y', 'ÿ': 'y',
    'ź': 'z', 'ż': 'z', 'ž': 'z',
    'ł': 'l',
  };

  static String _foldDiacritics(String s) {
    final buf = StringBuffer();
    for (final r in s.runes) {
      final c = String.fromCharCode(r);
      buf.write(_diacriticFold[c] ?? c);
    }
    return buf.toString();
  }

  static bool _isPunctuationLead(String s) =>
      s.isNotEmpty && RegExp(r'^[,.?!;:]').hasMatch(s);

  /// True when [window] matches [phrase] within an edit-distance budget that
  /// scales with phrase length. A single 1- or 2-character token never
  /// fuzzy-matches — we require exact for those (otherwise "in" → "vin"
  /// would rewrite every English sentence).
  static bool _fuzzyMatches(List<String> window, List<String> phrase) {
    if (window.length != phrase.length) return false;
    for (int i = 0; i < window.length; i++) {
      final w = window[i];
      final p = phrase[i];
      if (w.isEmpty || p.isEmpty) return false;
      if (w == p) continue;
      if (p.length <= 2) return false;
      final budget = _editBudget(p.length);
      if (_levenshtein(w, p, budget + 1) > budget) return false;
    }
    return true;
  }

  /// Edit budget per word length. Tighter than typical Levenshtein
  /// thresholds because false positives on short tokens corrupt sentences
  /// faster than missed corrections cost.
  static int _editBudget(int phraseLen) {
    if (phraseLen <= 4) return 1;
    if (phraseLen <= 7) return 2;
    return 3;
  }

  /// Bounded Levenshtein with an early-exit cap. Returns [cap] if the true
  /// distance is ≥ [cap]; otherwise returns the exact distance.
  static int _levenshtein(String a, String b, int cap) {
    if ((a.length - b.length).abs() >= cap) return cap;
    if (a == b) return 0;
    final m = a.length;
    final n = b.length;
    if (m == 0) return n >= cap ? cap : n;
    if (n == 0) return m >= cap ? cap : m;

    var prev = List<int>.generate(n + 1, (i) => i);
    var curr = List<int>.filled(n + 1, 0);
    for (int i = 1; i <= m; i++) {
      curr[0] = i;
      int rowMin = curr[0];
      for (int j = 1; j <= n; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        final del = prev[j] + 1;
        final ins = curr[j - 1] + 1;
        final sub = prev[j - 1] + cost;
        curr[j] = del < ins ? del : ins;
        if (sub < curr[j]) curr[j] = sub;
        if (curr[j] < rowMin) rowMin = curr[j];
      }
      if (rowMin >= cap) return cap;
      final tmp = prev;
      prev = curr;
      curr = tmp;
    }
    return prev[n] >= cap ? cap : prev[n];
  }

  // ─── Per-language domain phrases ──────────────────────────────────────
  //
  // Keep these focused on words STT commonly mangles in claim flows:
  // insurance terminology, vehicle parts the user might describe in a
  // collision, and ID-style nouns ("VIN", "policy number"). Generic verbs
  // are intentionally absent — fuzzy correction is most valuable on rare
  // domain nouns where the recognizer's acoustic prior is weakest.

  static const Map<String, List<String>> _phrases = {
    'en': [
      'policy', 'policy number', 'claim', 'claim number', 'insurance',
      'insurance company', 'insurer', 'insured', 'VIN', 'chassis',
      'registration', 'registration number', 'license plate', 'plate number',
      'deductible', 'premium', 'liability', 'collision', 'comprehensive',
      'third party', 'no claim bonus', 'reference number',
      'bumper', 'fender', 'windshield', 'windscreen', 'headlight', 'taillight',
      'door', 'mirror', 'tyre', 'tire', 'bonnet', 'hood', 'boot', 'trunk',
      'odometer', 'mileage',
      'driver', 'passenger', 'pedestrian', 'witness',
      'police report', 'incident', 'accident',
    ],
    'de': [
      'Versicherung', 'Versicherungsnummer', 'Schaden', 'Schadensnummer',
      'Schadennummer', 'Police', 'Policennummer', 'Fahrzeugschein',
      'Fahrgestellnummer', 'Kennzeichen', 'Nummernschild',
      'Selbstbeteiligung', 'Haftpflicht', 'Vollkasko', 'Teilkasko',
      'Stoßstange', 'Kotflügel', 'Windschutzscheibe', 'Scheinwerfer',
      'Rücklicht', 'Reifen', 'Motorhaube', 'Kofferraum',
      'Fahrer', 'Beifahrer', 'Fußgänger', 'Zeuge', 'Polizeibericht', 'Unfall',
    ],
    'it': [
      'polizza', 'numero di polizza', 'sinistro', 'numero di sinistro',
      'assicurazione', 'assicurato', 'targa', 'numero di targa',
      'telaio', 'numero di telaio', 'libretto', 'patente', 'franchigia',
      'responsabilità civile', 'kasko',
      'paraurti', 'parafango', 'parabrezza', 'faro', 'fanale', 'specchietto',
      'pneumatico', 'cofano', 'bagagliaio',
      'conducente', 'passeggero', 'pedone', 'testimone', 'verbale', 'incidente',
    ],
    'fr': [
      'police', 'numéro de police', 'sinistre', 'numéro de sinistre',
      'assurance', 'assuré', 'immatriculation', 'plaque',
      'numéro de châssis', 'châssis', 'franchise', 'responsabilité civile',
      'tous risques',
      'pare-chocs', 'aile', 'pare-brise', 'phare', 'feu', 'rétroviseur',
      'pneu', 'capot', 'coffre',
      'conducteur', 'passager', 'piéton', 'témoin', 'constat', 'accident',
    ],
    'es': [
      'póliza', 'número de póliza', 'siniestro', 'número de siniestro',
      'seguro', 'asegurado', 'aseguradora', 'matrícula',
      'número de bastidor', 'bastidor', 'franquicia',
      'responsabilidad civil', 'todo riesgo',
      'parachoques', 'guardabarros', 'parabrisas', 'faro', 'retrovisor',
      'neumático', 'capó', 'maletero',
      'conductor', 'pasajero', 'peatón', 'testigo', 'atestado', 'accidente',
    ],
    'pl': [
      'polisa', 'numer polisy', 'szkoda', 'numer szkody',
      'ubezpieczenie', 'ubezpieczony', 'ubezpieczyciel',
      'rejestracja', 'numer rejestracyjny', 'tablica rejestracyjna',
      'VIN', 'numer VIN', 'numer nadwozia', 'franszyza', 'udział własny',
      'OC', 'AC',
      'zderzak', 'błotnik', 'szyba', 'reflektor', 'lusterko',
      'opona', 'maska', 'bagażnik',
      'kierowca', 'pasażer', 'pieszy', 'świadek', 'protokół', 'wypadek',
    ],
    'lt': [
      'polisas', 'poliso numeris', 'žala', 'žalos numeris',
      'draudimas', 'draudėjas', 'apdraustasis',
      'registracijos numeris', 'valstybinis numeris',
      'VIN', 'kėbulo numeris', 'išskaita', 'civilinė atsakomybė', 'kasko',
      'buferis', 'sparnas', 'priekinis stiklas', 'žibintas', 'veidrodėlis',
      'padanga', 'variklio dangtis', 'bagažinė',
      'vairuotojas', 'keleivis', 'pėsčiasis', 'liudytojas', 'protokolas',
      'avarija',
    ],
    'lv': [
      'polise', 'polises numurs', 'atlīdzība', 'zaudējums', 'apdrošināšana',
      'apdrošinātais', 'apdrošinātājs',
      'reģistrācijas numurs', 'valsts numurs',
      'VIN', 'šasijas numurs', 'pašrisks', 'civiltiesiskā atbildība', 'kasko',
      'buferis', 'spārns', 'vējstikls', 'lukturis', 'spogulis',
      'riepa', 'motora pārsegs', 'bagāžnieks',
      'vadītājs', 'pasažieris', 'gājējs', 'liecinieks', 'protokols', 'avārija',
    ],
  };
}

class _Token {
  final String word;
  final String trailing;
  const _Token(this.word, this.trailing);
}
