import 'package:intl/intl.dart';

/// Date/number formatting helpers mirroring the Angular pipes used on the web
/// (`date:'fullDate'`, `date:'HH:mm'`, `date:'MMMM yyyy'`…).
abstract final class Formatters {
  static String monthYear(DateTime d, {String locale = 'en'}) => _cap(DateFormat.yMMMM(locale).format(d));
  static String fullDate(DateTime d, {String locale = 'en'}) => DateFormat.yMMMMEEEEd(locale).format(d);
  static String shortDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);
  static String dateTime(DateTime d) => DateFormat('dd/MM/yyyy HH:mm').format(d);
  static String medium(DateTime d) => DateFormat.yMMMd().add_jm().format(d);
  static String time(DateTime d) => DateFormat.Hm().format(d);
  static String timeRange(DateTime a, DateTime b) => '${time(a)} - ${time(b)}';
  static String day(DateTime d) => DateFormat('dd').format(d);
  static String monthShort(DateTime d, {String locale = 'fr'}) => DateFormat.MMM(locale).format(d);
  static String dayMonthYearFr(DateTime d) => DateFormat('dd MMMM yyyy', 'fr').format(d);

  /// "il y a 5 min" style relative time (supervision `timeSince`, feed dates).
  static String relative(DateTime d, {DateTime? now}) {
    final diff = (now ?? DateTime.now()).difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays < 7) return '${diff.inDays} d ago';
    return shortDate(d);
  }

  static String coordinate(double v, [int digits = 5]) => v.toStringAsFixed(digits);
  static String percent(num v, [int digits = 0]) => '${v.toStringAsFixed(digits)}%';

  static String _cap(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

extension DateTimeX on DateTime {
  bool isSameDay(DateTime other) => year == other.year && month == other.month && day == other.day;
  bool get isToday => isSameDay(DateTime.now());
  DateTime get dateOnly => DateTime(year, month, day);
}
