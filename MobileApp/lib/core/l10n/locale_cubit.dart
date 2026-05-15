import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:claim_ai/core/l10n/app_locales.dart';
import 'package:claim_ai/core/storage/local_storage.dart';

/// Holds the currently-selected app Locale, including the country code
/// (e.g. `Locale('it', 'CH')`). Persisted via [LocalStorage] so both choices
/// survive restarts.
///
/// Reads:
/// - `state.languageCode` → BCP-47 language ('en', 'it', ...) — used by
///   AppLocalizations and as `language` param for the chat API.
/// - `state.countryCode` → ISO-3166 country ('IN', 'IT', ...) — used as
///   `country_code` param for the chat API and as the region in
///   `Accept-Language` (e.g. 'it-IT').
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit({required LocalStorage localStorage})
      : _localStorage = localStorage,
        super(AppLocales.resolve(
          localStorage.getLocaleCode(),
          localStorage.getCountryCode(),
        ));

  final LocalStorage _localStorage;

  /// Switch to a new language. The country defaults to the language's primary
  /// country (e.g. it → IT, en → IN) unless [countryCode] is explicitly given
  /// and valid for that language.
  Future<void> setLocale(Locale locale, {String? countryCode}) async {
    if (!AppLocales.isSupportedLanguage(locale.languageCode)) return;
    final resolved =
        AppLocales.resolve(locale.languageCode, countryCode ?? locale.countryCode);
    if (state.languageCode == resolved.languageCode &&
        state.countryCode == resolved.countryCode) {
      return;
    }
    await _localStorage.setLocaleCode(resolved.languageCode);
    await _localStorage.setCountryCode(resolved.countryCode ?? '');
    emit(resolved);
  }

  /// Change only the country (the language is unchanged).
  Future<void> setCountry(String countryCode) async {
    if (!AppLocales.isValidCountryFor(state.languageCode, countryCode)) return;
    if (state.countryCode == countryCode) return;
    final next = Locale(state.languageCode, countryCode);
    await _localStorage.setCountryCode(countryCode);
    emit(next);
  }

  Future<void> setLanguageCode(String code) =>
      setLocale(AppLocales.resolve(code));
}
