import 'api_service.dart';

class ImportantDate {
  final String id;
  final DateTime date;
  final String title;
  final String occasion;
  final String notes;

  const ImportantDate({
    required this.id,
    required this.date,
    required this.title,
    required this.occasion,
    required this.notes,
  });

  bool matches(DateTime other) {
    return other.year == date.year &&
        other.month == date.month &&
        other.day == date.day;
  }

  String get dateLabel {
    final y = date.year.toString().padLeft(4, "0");
    final m = date.month.toString().padLeft(2, "0");
    final d = date.day.toString().padLeft(2, "0");
    return "$y-$m-$d";
  }

  static ImportantDate fromJson(Map<String, dynamic> json) {
    return ImportantDate(
      id: json["id"].toString(),
      date: DateTime.parse(json["date"].toString()),
      title: json["title"] ?? "",
      occasion: json["occasion"] ?? "",
      notes: json["notes"] ?? "",
    );
  }
}

class CalendarService {
  Future<List<ImportantDate>> getImportantDates({
    required String token,
    required String userId,
  }) async {
    final res = await ApiService.getImportantDates(token, userId);
    if (res == null || res["status"] != true) return [];

    final list = res["data"];
    if (list is! List) return [];

    return list
        .map((e) => ImportantDate.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ImportantDate?> getImportantDateFor(
    DateTime date, {
    required String token,
    required String userId,
  }) async {
    final dates = await getImportantDates(token: token, userId: userId);
    for (final d in dates) {
      if (d.matches(date)) return d;
    }
    return null;
  }
}
