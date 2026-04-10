class AIService {

  static String getSeason(double temp) {

    if (temp >= 30) return "Summer";
    if (temp <= 15) return "Winter";

    return "Spring";
  }

  static String resolveOccasion({
    required DateTime date,
    String? calendarOccasion,
  }) {
    if (calendarOccasion != null && calendarOccasion.isNotEmpty) {
      return calendarOccasion;
    }

    // Weekend vs weekday fallback
    final isWeekend =
        date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;

    return isWeekend ? "Casual" : "Work";
  }
}
