import 'package:claim_ai/core/services/plate_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlateNormalizer — bare alphanumeric', () {
    test('already-canonical plate passes through uppercased', () {
      final r = PlateNormalizer.normalize('GJ01AB99', 'en');
      expect(r.plate, 'GJ01AB99');
      expect(r.confidence, 1.0);
    });

    test('spaced plate is concatenated', () {
      final r = PlateNormalizer.normalize('gj 01 ab 99', 'en');
      expect(r.plate, 'GJ01AB99');
      expect(r.confidence, 1.0);
    });
  });

  group('PlateNormalizer — English phonetic letters', () {
    test('"gee jay zero one ay bee nine nine"', () {
      final r = PlateNormalizer.normalize(
        'gee jay zero one ay bee nine nine',
        'en',
      );
      expect(r.plate, 'GJ01ABNN'.replaceAll('N', '9'));
      expect(r.confidence, 1.0);
    });

    test('NATO alphabet recognised', () {
      final r = PlateNormalizer.normalize(
        'golf juliet zero one alpha bravo nine nine',
        'en',
      );
      expect(r.plate, 'GJ01AB99');
    });

    test('fillers are ignored', () {
      final r = PlateNormalizer.normalize(
        'gee jay zero one and ay bee nine nine',
        'en',
      );
      expect(r.plate, 'GJ01AB99');
      expect(r.confidence, 1.0);
    });
  });

  group('PlateNormalizer — German', () {
    test('"gé jot null eins ah bé neun neun"', () {
      final r = PlateNormalizer.normalize(
        'ge jot null eins ah be neun neun',
        'de',
      );
      expect(r.plate, 'GJ01AB99');
      expect(r.confidence, 1.0);
    });

    test('handles "und" filler', () {
      final r = PlateNormalizer.normalize(
        'ge jot null eins und ah be neun neun',
        'de',
      );
      expect(r.plate, 'GJ01AB99');
    });
  });

  group('PlateNormalizer — Italian', () {
    test('"gi i zero uno a bi nove nove"', () {
      final r = PlateNormalizer.normalize(
        'gi i zero uno a bi nove nove',
        'it',
      );
      // Italian "i" is the letter I, so position 2 becomes I → "GI"
      // followed by 01 → "GI01" + a bi → "AB" + 99
      // We accept either GI01AB99 (correct) or GIIO1AB99 depending on tokens.
      // Here input is exactly the canonical mapping.
      expect(r.plate, 'GI01ABNN'.replaceAll('N', '9'));
    });
  });

  group('PlateNormalizer — French', () {
    test('"ge ji zero un a be neuf neuf"', () {
      final r = PlateNormalizer.normalize(
        'ge ji zero un a be neuf neuf',
        'fr',
      );
      expect(r.plate, 'GJ01AB99');
    });
  });

  group('PlateNormalizer — Spanish', () {
    test('"ge jota cero uno a be nueve nueve"', () {
      final r = PlateNormalizer.normalize(
        'ge jota cero uno a be nueve nueve',
        'es',
      );
      expect(r.plate, 'GJ01AB99');
    });
  });

  group('PlateNormalizer — Polish', () {
    test('"gie jot zero jeden a be dziewiec dziewiec"', () {
      final r = PlateNormalizer.normalize(
        'gie jot zero jeden a be dziewiec dziewiec',
        'pl',
      );
      expect(r.plate, 'GJ01AB99');
    });
  });

  group('PlateNormalizer — Lithuanian', () {
    test('"ge jot nulis vienas a be devyni devyni"', () {
      final r = PlateNormalizer.normalize(
        'ge jot nulis vienas a be devyni devyni',
        'lt',
      );
      expect(r.plate, 'GJ01AB99');
    });
  });

  group('PlateNormalizer — Latvian', () {
    test('"ge jot nulle viens a be devini devini"', () {
      final r = PlateNormalizer.normalize(
        'ge jot nulle viens a be devini devini',
        'lv',
      );
      expect(r.plate, 'GJ01AB99');
    });

    test('handles "un" filler', () {
      final r = PlateNormalizer.normalize(
        'ge jot nulle viens un a be devini devini',
        'lv',
      );
      expect(r.plate, 'GJ01AB99');
    });
  });

  group('PlateNormalizer — diacritic-insensitive match', () {
    test('German with é accent on "bé"', () {
      final r = PlateNormalizer.normalize('bé', 'de');
      expect(r.plate, 'B');
      expect(r.confidence, 1.0);
    });

    test('Latvian with ē on "ē" letter sounds', () {
      final r = PlateNormalizer.normalize('ē', 'lv');
      // Bare "e" → letter E via the bare-alphanumeric path
      expect(r.plate, 'E');
    });
  });

  group('PlateNormalizer — non-plate input', () {
    test('empty string returns 0 confidence', () {
      final r = PlateNormalizer.normalize('', 'en');
      expect(r.plate, '');
      expect(r.confidence, 0.0);
    });

    test('non-plate sentence yields a too-long result the caller can reject',
        () {
      // The caller (voice_mode_screen) rejects anything not matching
      // `^[A-Z0-9]{4,12}$`. A normal sentence produces a much longer string,
      // so the caller passes the raw transcript through unchanged.
      final r = PlateNormalizer.normalize(
        'I do not remember my plate number sorry',
        'en',
      );
      expect(r.plate.length, greaterThan(12));
    });
  });
}
