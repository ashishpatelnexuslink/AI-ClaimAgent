/// Locale-aware vehicle-registration-plate normaliser.
///
/// Speech-to-text engines transcribe spelled-out plates phonetically in the
/// active locale — Italian "gi i zero uno a bi nove nove" instead of
/// "GJ01AB99", German "gé jot null eins ah bé neun neun", etc. The recogniser
/// has no idea the user is dictating a plate, so it produces sentences whose
/// individual tokens have to be mapped back to A-Z / 0-9.
///
/// This is only safe to run when the previous bot turn was *explicitly*
/// asking for a registration number — the caller is responsible for that
/// check. Running it on arbitrary user input would corrupt normal sentences.
library;

class PlateCandidate {
  /// Canonical alphanumeric uppercase plate, e.g. "GJ01AB99". Empty when the
  /// normaliser couldn't recover anything usable.
  final String plate;

  /// Fraction of input tokens that were recognised as a letter / digit /
  /// alphanumeric chunk — `1.0` means everything mapped cleanly. Filler
  /// words ("and", "und", "un") are not counted in the denominator.
  final double confidence;

  const PlateCandidate(this.plate, this.confidence);
}

class PlateNormalizer {
  /// `languageCode` is the BCP-47 language tag (`'en'`, `'de'`, `'it'`,
  /// `'fr'`, `'es'`, `'pl'`, `'lt'`, `'lv'`). Unknown languages fall back to
  /// the English map plus the raw-alphanumeric path, which still handles
  /// plates the engine happened to transcribe with bare letters/digits.
  static PlateCandidate normalize(String raw, String languageCode) {
    if (raw.trim().isEmpty) return const PlateCandidate('', 0.0);
    final lang = languageCode.toLowerCase().split(RegExp(r'[-_]')).first;
    final letters = _lettersFor(lang);
    final digits = _digitsFor(lang);
    final fillers = _fillersFor(lang);

    final tokens = _tokenize(raw);
    final buf = StringBuffer();
    int considered = 0;
    int matched = 0;

    for (final token in tokens) {
      final t = _stripDiacritics(token.toLowerCase());
      if (t.isEmpty) continue;
      if (fillers.contains(t)) continue;
      considered++;

      // 1) Letter name in the active language. Must be tried BEFORE the
      //    bare-alphanumeric path: "gee" / "ge" / "jot" / "null" are all
      //    valid a-z tokens and would otherwise be written out verbatim
      //    instead of being mapped to G/J/0.
      final letter = letters[t];
      if (letter != null) {
        buf.write(letter);
        matched++;
        continue;
      }
      // 2) Digit name in the active language.
      final digit = digits[t];
      if (digit != null) {
        buf.write(digit);
        matched++;
        continue;
      }
      // 3) Bare alphanumeric token (e.g. "gj01ab99" or "GJ" or "99") — what
      //    the engine produces when it recognised the plate as a single
      //    chunk rather than dictated letter-by-letter.
      if (RegExp(r'^[a-z0-9]+$').hasMatch(t)) {
        buf.write(t.toUpperCase());
        matched++;
        continue;
      }
      // 4) Last resort: pick up embedded digits inside a noisy token
      //    ("99," "01."). Mark as partial — counts as matched only if at
      //    least one alphanumeric char came out.
      final inner = t.replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (inner.isNotEmpty) {
        buf.write(inner.toUpperCase());
        matched++;
      }
    }

    final plate = buf.toString();
    final confidence = considered == 0 ? 0.0 : matched / considered;
    return PlateCandidate(plate, confidence);
  }

  static List<String> _tokenize(String s) =>
      s.split(RegExp(r'[\s,.;:/\-]+')).where((t) => t.isNotEmpty).toList();

  /// Strips Latin-1 diacritics so we can match `bé` ≈ `be`, `tsé` ≈ `tse`,
  /// `nulle` (lv) ≈ `nulle`. Falls back to identity for code points outside
  /// the basic map — full Unicode normalisation isn't available in core
  /// Dart without an extra dep, and this covers every letter-name we ship.
  static String _stripDiacritics(String s) {
    const map = {
      'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ā': 'a', 'ã': 'a', 'å': 'a',
      'ą': 'a',
      'ç': 'c', 'ć': 'c', 'č': 'c',
      'ď': 'd',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', 'ē': 'e', 'ė': 'e', 'ę': 'e',
      'ě': 'e',
      'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', 'ī': 'i', 'į': 'i',
      'ñ': 'n', 'ń': 'n', 'ň': 'n', 'ņ': 'n',
      'ó': 'o', 'ò': 'o', 'ô': 'o', 'ö': 'o', 'ō': 'o', 'õ': 'o', 'ø': 'o',
      'ś': 's', 'š': 's', 'ş': 's',
      'ť': 't',
      'ú': 'u', 'ù': 'u', 'û': 'u', 'ü': 'u', 'ū': 'u', 'ų': 'u', 'ů': 'u',
      'ý': 'y', 'ÿ': 'y',
      'ź': 'z', 'ż': 'z', 'ž': 'z',
      'ł': 'l', 'ľ': 'l',
      'ß': 'ss',
    };
    final buf = StringBuffer();
    for (final r in s.runes) {
      final c = String.fromCharCode(r);
      buf.write(map[c] ?? c);
    }
    return buf.toString();
  }

  static Map<String, String> _lettersFor(String lang) {
    return _letterMaps[lang] ?? _letterMaps['en']!;
  }

  static Map<String, String> _digitsFor(String lang) {
    return _digitMaps[lang] ?? _digitMaps['en']!;
  }

  static Set<String> _fillersFor(String lang) {
    return _fillerWords[lang] ?? _fillerWords['en']!;
  }

  // ─── Per-language letter maps ─────────────────────────────────────────
  // Keys must already be lowercase, diacritic-stripped. Multiple aliases per
  // letter are common because STT engines transcribe the same sound in
  // different ways across users (German "ka" ≈ "kah", Italian "i" ≈ "ay",
  // English "ay" ≈ "a" ≈ "eh").

  static const Map<String, Map<String, String>> _letterMaps = {
    'en': {
      // NATO
      'alpha': 'A', 'bravo': 'B', 'charlie': 'C', 'delta': 'D', 'echo': 'E',
      'foxtrot': 'F', 'golf': 'G', 'hotel': 'H', 'india': 'I', 'juliet': 'J',
      'juliett': 'J', 'kilo': 'K', 'lima': 'L', 'mike': 'M', 'november': 'N',
      'oscar': 'O', 'papa': 'P', 'quebec': 'Q', 'romeo': 'R', 'sierra': 'S',
      'tango': 'T', 'uniform': 'U', 'victor': 'V', 'whiskey': 'W',
      'xray': 'X', 'x-ray': 'X', 'yankee': 'Y', 'zulu': 'Z',
      // Phonetic spellings
      'ay': 'A', 'aye': 'A', 'eh': 'A',
      'bee': 'B', 'be': 'B',
      'cee': 'C', 'see': 'C', 'sea': 'C',
      'dee': 'D',
      'ee': 'E',
      'ef': 'F', 'eff': 'F',
      'gee': 'G', 'jee': 'G',
      'aitch': 'H', 'haitch': 'H',
      'eye': 'I',
      'jay': 'J',
      'kay': 'K',
      'el': 'L', 'ell': 'L',
      'em': 'M',
      'en': 'N',
      'oh': 'O',
      'pee': 'P', 'pea': 'P',
      'cue': 'Q', 'queue': 'Q',
      'ar': 'R', 'are': 'R',
      'es': 'S', 'ess': 'S',
      'tee': 'T', 'tea': 'T',
      'you': 'U', 'yoo': 'U',
      'vee': 'V',
      'doubleyou': 'W', 'double-u': 'W', 'doubleu': 'W',
      'eks': 'X', 'ex': 'X',
      'why': 'Y', 'wye': 'Y',
      'zee': 'Z', 'zed': 'Z',
    },
    'de': {
      'ah': 'A', 'a': 'A',
      'be': 'B', 'bee': 'B',
      'tse': 'C', 'ce': 'C', 'ze': 'C',
      'de': 'D',
      'e': 'E',
      'ef': 'F', 'eff': 'F',
      'ge': 'G',
      'ha': 'H',
      'i': 'I',
      'jot': 'J', 'yot': 'J',
      'ka': 'K', 'kah': 'K',
      'el': 'L', 'ell': 'L',
      'em': 'M',
      'en': 'N',
      'o': 'O',
      'pe': 'P', 'peh': 'P',
      'ku': 'Q', 'kuh': 'Q',
      'er': 'R',
      'es': 'S', 'ess': 'S',
      'te': 'T', 'teh': 'T',
      'u': 'U',
      'fau': 'V',
      'we': 'W', 'weh': 'W',
      'iks': 'X', 'ix': 'X',
      'ypsilon': 'Y', 'upsilon': 'Y',
      'tset': 'Z', 'zet': 'Z', 'tsett': 'Z',
    },
    'it': {
      'a': 'A',
      'bi': 'B',
      'ci': 'C',
      'di': 'D',
      'e': 'E',
      'effe': 'F',
      'gi': 'G',
      'acca': 'H',
      'i': 'I', 'ilunga': 'I',
      'cappa': 'K', 'kappa': 'K',
      'elle': 'L',
      'emme': 'M',
      'enne': 'N',
      'o': 'O',
      'pi': 'P',
      'cu': 'Q', 'qu': 'Q',
      'erre': 'R',
      'esse': 'S',
      'ti': 'T',
      'u': 'U',
      'vu': 'V', 'vi': 'V',
      'doppiavu': 'W', 'doppia': 'W',
      'ics': 'X',
      'igreca': 'Y', 'ipsilon': 'Y',
      'zeta': 'Z',
    },
    'fr': {
      'a': 'A',
      'be': 'B',
      'ce': 'C', 'se': 'C',
      'de': 'D',
      'eu': 'E', 'e': 'E',
      'ef': 'F', 'effe': 'F',
      'ge': 'G', 'je': 'G',
      'ache': 'H', 'hache': 'H',
      'i': 'I',
      'ji': 'J', 'jee': 'J',
      'ka': 'K',
      'elle': 'L', 'el': 'L',
      'emme': 'M', 'em': 'M',
      'enne': 'N', 'en': 'N',
      'o': 'O',
      'pe': 'P',
      'ku': 'Q', 'cu': 'Q',
      'erre': 'R', 'er': 'R',
      'esse': 'S', 'es': 'S',
      'te': 'T',
      'u': 'U',
      've': 'V',
      'doubleve': 'W', 'double': 'W',
      'iks': 'X', 'ix': 'X',
      'igrec': 'Y', 'igrek': 'Y',
      'zede': 'Z', 'zed': 'Z',
    },
    'es': {
      'a': 'A',
      'be': 'B', 'belarga': 'B',
      'ce': 'C', 'se': 'C',
      'de': 'D',
      'e': 'E',
      'efe': 'F',
      'ge': 'G',
      'hache': 'H', 'ache': 'H',
      'i': 'I', 'ilatina': 'I',
      'jota': 'J',
      'ka': 'K',
      'ele': 'L',
      'eme': 'M',
      'ene': 'N',
      'enie': 'N', // ñ collapses to N for plate matching
      'o': 'O',
      'pe': 'P',
      'cu': 'Q', 'ku': 'Q',
      'ere': 'R', 'erre': 'R',
      'ese': 'S', 'esse': 'S',
      'te': 'T',
      'u': 'U',
      'uve': 'V', 've': 'V',
      'uvedoble': 'W', 'dobleu': 'W', 'doble': 'W',
      'equis': 'X', 'ekis': 'X',
      'igriega': 'Y', 'ye': 'Y',
      'zeta': 'Z',
    },
    'pl': {
      'a': 'A',
      'be': 'B',
      'ce': 'C',
      'de': 'D',
      'e': 'E',
      'ef': 'F',
      'gie': 'G', 'ge': 'G',
      'ha': 'H',
      'i': 'I',
      'jot': 'J', 'iot': 'J',
      'ka': 'K',
      'el': 'L',
      'em': 'M',
      'en': 'N',
      'o': 'O',
      'pe': 'P',
      'ku': 'Q',
      'er': 'R',
      'es': 'S',
      'te': 'T',
      'u': 'U',
      'wu': 'W', 'fau': 'W',
      'iks': 'X', 'ix': 'X',
      'igrek': 'Y',
      'zet': 'Z',
    },
    'lt': {
      'a': 'A',
      'be': 'B',
      'ce': 'C',
      'de': 'D',
      'e': 'E',
      'ef': 'F',
      'ge': 'G',
      'ha': 'H',
      'i': 'I',
      'jot': 'J', 'iot': 'J',
      'ka': 'K',
      'el': 'L',
      'em': 'M',
      'en': 'N',
      'o': 'O',
      'pe': 'P',
      'ku': 'Q',
      'er': 'R',
      'es': 'S',
      'te': 'T',
      'u': 'U',
      've': 'V',
      'dvigubasv': 'W',
      'iks': 'X', 'ix': 'X',
      'igrek': 'Y',
      'ze': 'Z', 'zet': 'Z',
    },
    'lv': {
      'a': 'A',
      'be': 'B',
      'ce': 'C',
      'de': 'D',
      'e': 'E',
      'ef': 'F',
      'ge': 'G',
      'ha': 'H',
      'i': 'I',
      'jot': 'J', 'iot': 'J',
      'ka': 'K',
      'el': 'L',
      'em': 'M',
      'en': 'N',
      'o': 'O',
      'pe': 'P',
      'ku': 'Q',
      'er': 'R',
      'es': 'S',
      'te': 'T',
      'u': 'U',
      've': 'V',
      'dubultve': 'W',
      'iks': 'X', 'ix': 'X',
      'igrek': 'Y',
      'ze': 'Z', 'zet': 'Z',
    },
  };

  // ─── Per-language digit maps ──────────────────────────────────────────
  // Lower-cased and diacritic-stripped keys.

  static const Map<String, Map<String, String>> _digitMaps = {
    'en': {
      'zero': '0', 'oh': '0', 'naught': '0', 'nought': '0',
      'one': '1', 'two': '2', 'three': '3', 'four': '4', 'five': '5',
      'six': '6', 'seven': '7', 'eight': '8', 'nine': '9',
    },
    'de': {
      'null': '0', 'eins': '1', 'ein': '1', 'eine': '1',
      'zwei': '2', 'zwo': '2', 'drei': '3', 'vier': '4', 'funf': '5',
      'sechs': '6', 'sieben': '7', 'acht': '8', 'neun': '9',
    },
    'it': {
      'zero': '0', 'uno': '1', 'un': '1', 'una': '1', 'due': '2',
      'tre': '3', 'quattro': '4', 'cinque': '5', 'sei': '6',
      'sette': '7', 'otto': '8', 'nove': '9',
    },
    'fr': {
      'zero': '0', 'un': '1', 'une': '1', 'deux': '2', 'trois': '3',
      'quatre': '4', 'cinq': '5', 'six': '6', 'sept': '7', 'huit': '8',
      'neuf': '9',
    },
    'es': {
      'cero': '0', 'uno': '1', 'un': '1', 'una': '1', 'dos': '2',
      'tres': '3', 'cuatro': '4', 'cinco': '5', 'seis': '6', 'siete': '7',
      'ocho': '8', 'nueve': '9',
    },
    'pl': {
      'zero': '0', 'jeden': '1', 'jedna': '1', 'dwa': '2', 'trzy': '3',
      'cztery': '4', 'piec': '5', 'szesc': '6', 'siedem': '7', 'osiem': '8',
      'dziewiec': '9',
    },
    'lt': {
      'nulis': '0', 'vienas': '1', 'viena': '1', 'du': '2', 'dvi': '2',
      'trys': '3', 'keturi': '4', 'penki': '5', 'sesi': '6', 'septyni': '7',
      'astuoni': '8', 'devyni': '9',
    },
    'lv': {
      'nulle': '0', 'viens': '1', 'viena': '1', 'divi': '2', 'divas': '2',
      'tris': '3', 'cetri': '4', 'pieci': '5', 'sesi': '6', 'septini': '7',
      'astoni': '8', 'devini': '9',
    },
  };

  // Words to ignore entirely so they don't inflate the denominator of the
  // confidence ratio. "and" / "und" / "y" / "i" are spoken between groups
  // ("GJ zero one AND ay bee nine nine").
  // Fillers must NOT collide with any letter or digit name above — a token
  // listed here is dropped entirely (not counted in the confidence
  // denominator). Single-letter pronunciations ('ah' = A in de, 'e' = E in
  // it, 'i' = I in pl/it, 'y' = Y in en/es) are deliberately *omitted* from
  // the filler list even when they double as interjections, because losing
  // the letter is worse than failing to drop the filler.
  static const Map<String, Set<String>> _fillerWords = {
    'en': {'and', 'the'},
    'de': {'und'},
    'it': {'ed'},
    'fr': {'et', 'euh'},
    'es': {'eh'},
    'pl': {'oraz', 'eee'},
    'lt': {'ir'},
    'lv': {'un', 'nu'},
  };
}
