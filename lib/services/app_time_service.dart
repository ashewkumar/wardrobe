import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class AppTime {
  AppTime._();

  static const String timeZoneId = 'Asia/Kolkata';

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tzdata.initializeTimeZones();
    tz.setLocalLocation(location);
    _initialized = true;
  }

  static tz.Location get location => tz.getLocation(timeZoneId);

  static DateTime now() => tz.TZDateTime.now(location);

  static DateTime today() {
    final value = now();
    return tz.TZDateTime(location, value.year, value.month, value.day);
  }

  static DateTime toIst(DateTime value) => tz.TZDateTime.from(value, location);

  static DateTime parseApiDate(String raw) {
    final trimmed = raw.trim();
    final dateOnly = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (dateOnly.hasMatch(trimmed)) {
      final parts = trimmed.split('-').map(int.parse).toList();
      return tz.TZDateTime(location, parts[0], parts[1], parts[2]);
    }

    final parsed = DateTime.tryParse(trimmed);
    if (parsed == null) {
      return DateTime(1970);
    }
    return toIst(parsed);
  }

  static String formatDate(DateTime value) {
    final date = toIst(value);
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String formatDateTime(DateTime value) {
    final date = toIst(value);
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm IST';
  }

  static tz.TZDateTime tzNow() => tz.TZDateTime.now(location);
}
