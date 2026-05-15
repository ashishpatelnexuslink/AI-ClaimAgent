import 'package:flutter/widgets.dart';

/// Single source of truth for the languages and countries the app supports.
class AppLocales {
  AppLocales._();

  static const Locale fallback = Locale('en', 'IN');

  /// Supported language codes (BCP 47 primary subtag).
  static const List<String> supportedLanguages = <String>[
    'en', 'de', 'it', 'fr', 'es', 'pl', 'lt', 'lv',
  ];

  /// All supported Locales (language + default country). Used by MaterialApp's
  /// `supportedLocales`. Built from `defaultCountryFor` below.
  static List<Locale> get supported => supportedLanguages
      .map((lang) => Locale(lang, defaultCountryFor(lang)))
      .toList();

  /// Native display name for each supported language (shown in the picker).
  static const Map<String, String> displayNames = <String, String>{
    'en': 'English',
    'de': 'Deutsch',
    'it': 'Italiano',
    'fr': 'Français',
    'es': 'Español',
    'pl': 'Polski',
    'lt': 'Lietuvių',
    'lv': 'Latviešu',
  };

  /// Allowed country ISO codes for each language, in display order. The first
  /// entry is the default when the user hasn't explicitly picked.
  static const Map<String, List<String>> countriesByLanguage =
      <String, List<String>>{
    'en': ['IN', 'US', 'GB', 'AU', 'CA', 'IE'],
    'de': ['DE', 'AT', 'CH', 'LU'],
    'it': ['IT', 'CH', 'SM', 'VA'],
    'fr': ['FR', 'CA', 'BE', 'CH', 'LU'],
    'es': ['ES', 'MX', 'AR', 'CO', 'US'],
    'pl': ['PL'],
    'lt': ['LT'],
    'lv': ['LV'],
  };

  /// Country display names (English) keyed by ISO code.
  static const Map<String, String> countryNames = <String, String>{
    'IN': 'India',
    'US': 'United States',
    'GB': 'United Kingdom',
    'AU': 'Australia',
    'CA': 'Canada',
    'IE': 'Ireland',
    'DE': 'Germany',
    'AT': 'Austria',
    'CH': 'Switzerland',
    'LU': 'Luxembourg',
    'IT': 'Italy',
    'SM': 'San Marino',
    'VA': 'Vatican City',
    'FR': 'France',
    'BE': 'Belgium',
    'ES': 'Spain',
    'MX': 'Mexico',
    'AR': 'Argentina',
    'CO': 'Colombia',
    'PL': 'Poland',
    'LT': 'Lithuania',
    'LV': 'Latvia',
  };

  static bool isSupportedLanguage(String code) =>
      supportedLanguages.contains(code);

  static String defaultCountryFor(String languageCode) {
    final countries = countriesByLanguage[languageCode];
    if (countries == null || countries.isEmpty) return '';
    return countries.first;
  }

  static List<String> countriesFor(String languageCode) =>
      countriesByLanguage[languageCode] ?? const [];

  static bool isValidCountryFor(String languageCode, String? countryCode) {
    if (countryCode == null) return false;
    return countriesFor(languageCode).contains(countryCode);
  }

  /// Resolve a (lang, country) pair into a supported `Locale`, falling back to
  /// the default country for the language, then to English/IN.
  static Locale resolve(String? languageCode, [String? countryCode]) {
    if (languageCode == null || !isSupportedLanguage(languageCode)) {
      return fallback;
    }
    final country = isValidCountryFor(languageCode, countryCode)
        ? countryCode!
        : defaultCountryFor(languageCode);
    return Locale(languageCode, country);
  }
}
