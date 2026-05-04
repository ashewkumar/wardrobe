import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_time_service.dart';

class AnalyticsEvent {
  const AnalyticsEvent({
    required this.name,
    required this.timestamp,
    required this.properties,
  });

  final String name;
  final DateTime timestamp;
  final Map<String, dynamic> properties;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'timestamp': timestamp.toIso8601String(),
      'properties': properties,
    };
  }

  static AnalyticsEvent fromJson(Map<String, dynamic> json) {
    return AnalyticsEvent(
      name: json['name']?.toString() ?? 'unknown',
      timestamp:
          DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      properties:
          (json['properties'] as Map?)?.map(
            (key, value) => MapEntry(key.toString(), value),
          ) ??
          const <String, dynamic>{},
    );
  }
}

class DailyEventCount {
  const DailyEventCount({required this.label, required this.count});

  final String label;
  final int count;
}

class AnalyticsSnapshot {
  const AnalyticsSnapshot({
    required this.totalEvents,
    required this.screenViews,
    required this.notificationEvents,
    required this.reminderSchedules,
    required this.uniqueEventTypes,
    required this.dailyCounts,
    required this.recentEvents,
    required this.topEvents,
  });

  final int totalEvents;
  final int screenViews;
  final int notificationEvents;
  final int reminderSchedules;
  final int uniqueEventTypes;
  final List<DailyEventCount> dailyCounts;
  final List<AnalyticsEvent> recentEvents;
  final List<MapEntry<String, int>> topEvents;
}

class AppAnalyticsService {
  AppAnalyticsService._();

  static final AppAnalyticsService instance = AppAnalyticsService._();

  static const String _eventsKey = 'analytics_events_v1';
  static const int _maxEvents = 250;

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> track(
    String name, {
    Map<String, dynamic> properties = const <String, dynamic>{},
  }) async {
    await init();
    final event = AnalyticsEvent(
      name: name,
      timestamp: AppTime.now(),
      properties: properties,
    );

    final events = _loadEvents()..insert(0, event);
    if (events.length > _maxEvents) {
      events.removeRange(_maxEvents, events.length);
    }

    await _prefs!.setStringList(
      _eventsKey,
      events.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<void> trackScreen(String screenName) {
    return track(
      'screen_view',
      properties: <String, dynamic>{'screen': screenName},
    );
  }

  Future<void> trackPerformance(
    String name, {
    required int durationMs,
    bool success = true,
  }) {
    return track(
      'performance_metric',
      properties: <String, dynamic>{
        'name': name,
        'durationMs': durationMs,
        'success': success,
      },
    );
  }

  Future<AnalyticsSnapshot> getSnapshot() async {
    await init();
    final events = _loadEvents();
    final counts = <String, int>{};
    final now = AppTime.now();
    final dailyCounts = <DailyEventCount>[];

    for (final event in events) {
      counts.update(event.name, (value) => value + 1, ifAbsent: () => 1);
    }

    for (var offset = 6; offset >= 0; offset--) {
      final day = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: offset));
      final count = events.where((event) {
        final at = event.timestamp;
        return at.year == day.year &&
            at.month == day.month &&
            at.day == day.day;
      }).length;
      dailyCounts.add(
        DailyEventCount(label: '${day.month}/${day.day}', count: count),
      );
    }

    final topEvents = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return AnalyticsSnapshot(
      totalEvents: events.length,
      screenViews: counts['screen_view'] ?? 0,
      notificationEvents:
          (counts['notification_permission_updated'] ?? 0) +
          (counts['notification_opened'] ?? 0),
      reminderSchedules: counts['reminders_synced'] ?? 0,
      uniqueEventTypes: counts.length,
      dailyCounts: dailyCounts,
      recentEvents: events.take(8).toList(),
      topEvents: topEvents.take(5).toList(),
    );
  }

  List<AnalyticsEvent> _loadEvents() {
    final raw = _prefs?.getStringList(_eventsKey) ?? const <String>[];
    return raw
        .map((item) {
          try {
            final decoded = jsonDecode(item);
            if (decoded is Map<String, dynamic>) {
              return AnalyticsEvent.fromJson(decoded);
            }
            if (decoded is Map) {
              return AnalyticsEvent.fromJson(
                decoded.map((key, value) => MapEntry(key.toString(), value)),
              );
            }
          } catch (_) {
            // Ignore invalid events and keep the feed usable.
          }
          return null;
        })
        .whereType<AnalyticsEvent>()
        .toList();
  }
}
