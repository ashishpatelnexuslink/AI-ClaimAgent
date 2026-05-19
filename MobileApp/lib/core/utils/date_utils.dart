import 'package:claim_ai/core/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';

/// Date/time helpers. Display formatters take an optional `locale` (BCP 47
/// language code, e.g. 'en', 'de', 'it'). When null they use the system
/// default. Pass `Localizations.localeOf(context).languageCode` from widgets
/// to keep formatting in sync with the selected app locale.
class AppDateUtils {
  AppDateUtils._();

  /// Localized medium date, e.g. "Jan 14, 2026" / "14. Jan. 2026" / "14 gen 2026".
  static String formatDate(DateTime date, [String? locale]) {
    return DateFormat.yMMMd(locale).format(date);
  }

  /// Localized date + 24-hour time.
  static String formatDateTime(DateTime date, [String? locale]) {
    return '${DateFormat.yMMMd(locale).format(date)} '
        '${DateFormat.Hm(locale).format(date)}';
  }

  /// Localized time (12- or 24-hour depending on locale convention).
  static String formatTime(DateTime date, [String? locale]) {
    return DateFormat.jm(locale).format(date);
  }

  static String timeAgo(DateTime date, AppLocalizations l) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 365) {
      return l.timeAgo_yearsAgo((diff.inDays / 365).floor());
    } else if (diff.inDays > 30) {
      return l.timeAgo_monthsAgo((diff.inDays / 30).floor());
    } else if (diff.inDays > 0) {
      return l.timeAgo_daysAgo(diff.inDays);
    } else if (diff.inHours > 0) {
      return l.timeAgo_hoursAgo(diff.inHours);
    } else if (diff.inMinutes > 0) {
      return l.timeAgo_minutesAgo(diff.inMinutes);
    } else {
      return l.timeAgo_justNow;
    }
  }

  /// API serialization — locale-neutral by design (yyyy-MM-dd ISO).
  static String formatApiDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Device UTC offset in minutes. Positive east of UTC.
  /// India = 330, Los Angeles (PST) = -480, UTC = 0.
  static int currentTimezoneOffsetMinutes() =>
      DateTime.now().timeZoneOffset.inMinutes;

  static DateTime? parseApiDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    return DateTime.tryParse(dateStr);
  }
}
