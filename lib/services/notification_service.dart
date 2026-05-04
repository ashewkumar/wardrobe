import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;

import 'analytics_service.dart';
import 'app_time_service.dart';
import 'calendar_service.dart';
import 'stability_service.dart';

class NotificationSettingsSnapshot {
  const NotificationSettingsSnapshot({
    required this.enabled,
    required this.pendingCount,
  });

  final bool enabled;
  final int pendingCount;
}

@pragma('vm:entry-point')
void onDidReceiveNotificationResponse(NotificationResponse response) {
  AppAnalyticsService.instance.track(
    'notification_opened',
    properties: <String, dynamic>{'payload': response.payload ?? ''},
  );
}

class AppNotificationService {
  AppNotificationService._();

  static final AppNotificationService instance = AppNotificationService._();

  static const String _enabledKey = 'notifications_enabled_v1';
  static const String _scheduledIdsKey = 'scheduled_notification_ids_v1';
  static const String _channelId = 'wardrobe_events';
  static const String _channelName = 'Wardrobe reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  SharedPreferences? _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _prefs ??= await SharedPreferences.getInstance();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
      onDidReceiveBackgroundNotificationResponse:
          onDidReceiveNotificationResponse,
    );

    await _configureTimeZone();
    _initialized = true;
  }

  Future<void> _configureTimeZone() async {
    try {
      await AppTime.init();
      tz.setLocalLocation(AppTime.location);
    } catch (error) {
      await AppStabilityService.instance.recordError(
        'notification_timezone',
        error.toString(),
      );
    }
  }

  Future<bool> get isEnabled async {
    await init();
    return _prefs?.getBool(_enabledKey) ?? true;
  }

  Future<NotificationSettingsSnapshot> getSnapshot() async {
    await init();
    final pending = await _plugin.pendingNotificationRequests();
    return NotificationSettingsSnapshot(
      enabled: await isEnabled,
      pendingCount: pending.length,
    );
  }

  Future<bool> requestPermissions() async {
    await init();

    bool granted = true;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final macos = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();

    final androidGranted =
        await android?.requestNotificationsPermission() ?? true;
    final iosGranted =
        await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
        true;
    final macosGranted =
        await macos?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        ) ??
        true;

    granted = androidGranted && iosGranted && macosGranted;

    await AppAnalyticsService.instance.track(
      'notification_permission_updated',
      properties: <String, dynamic>{'granted': granted},
    );

    return granted;
  }

  Future<void> setEnabled(bool enabled) async {
    await init();
    await _prefs!.setBool(_enabledKey, enabled);
    await AppAnalyticsService.instance.track(
      'notification_toggle_updated',
      properties: <String, dynamic>{'enabled': enabled},
    );

    if (!enabled) {
      await clearScheduledReminders();
    }
  }

  Future<void> syncImportantDateReminders(List<ImportantDate> dates) async {
    await init();
    if (!await isEnabled) {
      await clearScheduledReminders();
      return;
    }

    final permissionGranted = await requestPermissions();
    if (!permissionGranted) {
      await setEnabled(false);
      return;
    }

    await clearScheduledReminders();

    final scheduledIds = <int>[];
    final sortedDates = [...dates]..sort((a, b) => a.date.compareTo(b.date));

    for (final date in sortedDates) {
      final sameDay = _buildSchedule(date.date, hour: 8);
      if (sameDay != null) {
        final id = _notificationId(date.id, 'same_day');
        scheduledIds.add(id);
        await _plugin.zonedSchedule(
          id: id,
          title: date.title,
          body: _eventBody(date, sameDay: true),
          scheduledDate: sameDay,
          notificationDetails: _details(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: jsonEncode(<String, dynamic>{
            'type': 'same_day',
            'id': date.id,
          }),
        );
      }

      final reminder = _buildSchedule(
        date.date.subtract(const Duration(days: 1)),
        hour: 18,
      );
      if (reminder != null) {
        final id = _notificationId(date.id, 'reminder');
        scheduledIds.add(id);
        await _plugin.zonedSchedule(
          id: id,
          title: 'Tomorrow: ${date.title}',
          body: _eventBody(date, sameDay: false),
          scheduledDate: reminder,
          notificationDetails: _details(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: jsonEncode(<String, dynamic>{
            'type': 'reminder',
            'id': date.id,
          }),
        );
      }
    }

    await _prefs!.setStringList(
      _scheduledIdsKey,
      scheduledIds.map((id) => id.toString()).toList(),
    );

    await AppAnalyticsService.instance.track(
      'reminders_synced',
      properties: <String, dynamic>{
        'events': dates.length,
        'notifications': scheduledIds.length,
      },
    );
  }

  Future<void> clearScheduledReminders() async {
    await init();
    final ids = (_prefs?.getStringList(_scheduledIdsKey) ?? const <String>[])
        .map(int.tryParse)
        .whereType<int>();
    for (final id in ids) {
      await _plugin.cancel(id: id);
    }
    await _prefs?.remove(_scheduledIdsKey);
  }

  NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Event and reminder notifications',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );
  }

  tz.TZDateTime? _buildSchedule(DateTime date, {required int hour}) {
    final candidate = tz.TZDateTime(
      AppTime.location,
      date.year,
      date.month,
      date.day,
      hour,
    );
    if (candidate.isBefore(AppTime.tzNow())) {
      return null;
    }
    return candidate;
  }

  int _notificationId(String sourceId, String type) {
    return (sourceId.hashCode ^ type.hashCode).abs() % 2147483647;
  }

  String _eventBody(ImportantDate date, {required bool sameDay}) {
    final detail = date.occasion.isNotEmpty ? date.occasion : 'Wardrobe event';
    return sameDay
        ? '$detail is happening today. Review your look and notes.'
        : '$detail is coming up tomorrow. Time to prep your outfit.';
  }
}
