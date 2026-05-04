import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_service.dart';
import 'app_time_service.dart';

class StabilityIssue {
  const StabilityIssue({
    required this.source,
    required this.message,
    required this.timestamp,
  });

  final String source;
  final String message;
  final DateTime timestamp;

  Map<String, dynamic> toJson() {
    return {
      'source': source,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static StabilityIssue fromJson(Map<String, dynamic> json) {
    return StabilityIssue(
      source: json['source']?.toString() ?? 'unknown',
      message: json['message']?.toString() ?? 'Unknown error',
      timestamp:
          DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class PerformanceMetric {
  const PerformanceMetric({
    required this.name,
    required this.durationMs,
    required this.timestamp,
    required this.success,
  });

  final String name;
  final int durationMs;
  final DateTime timestamp;
  final bool success;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'durationMs': durationMs,
      'timestamp': timestamp.toIso8601String(),
      'success': success,
    };
  }

  static PerformanceMetric fromJson(Map<String, dynamic> json) {
    return PerformanceMetric(
      name: json['name']?.toString() ?? 'unknown',
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
      timestamp:
          DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      success: json['success'] == true,
    );
  }
}

class StabilitySnapshot {
  const StabilitySnapshot({
    required this.totalIssues,
    required this.crashFreeSessions,
    required this.recentIssues,
    required this.slowestOperations,
    required this.averageLatencyMs,
  });

  final int totalIssues;
  final int crashFreeSessions;
  final List<StabilityIssue> recentIssues;
  final List<MapEntry<String, int>> slowestOperations;
  final int averageLatencyMs;
}

class AppStabilityService {
  AppStabilityService._();

  static final AppStabilityService instance = AppStabilityService._();

  static const String _issuesKey = 'stability_issues_v1';
  static const String _metricsKey = 'stability_metrics_v1';
  static const String _sessionsKey = 'stability_sessions_v1';
  static const int _maxIssues = 50;
  static const int _maxMetrics = 120;

  SharedPreferences? _prefs;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _prefs ??= await SharedPreferences.getInstance();
    _initialized = true;

    final previous = _prefs!.getInt(_sessionsKey) ?? 0;
    await _prefs!.setInt(_sessionsKey, previous + 1);

    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      recordError('flutter_error', details.exceptionAsString());
      originalOnError?.call(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      recordError('platform_error', '$error\n$stack');
      return true;
    };
  }

  Future<void> recordError(String source, String message) async {
    await init();
    final issues = _loadIssues()
      ..insert(
        0,
        StabilityIssue(
          source: source,
          message: message,
          timestamp: AppTime.now(),
        ),
      );
    if (issues.length > _maxIssues) {
      issues.removeRange(_maxIssues, issues.length);
    }

    await _prefs!.setStringList(
      _issuesKey,
      issues.map((item) => jsonEncode(item.toJson())).toList(),
    );

    await AppAnalyticsService.instance.track(
      'error_captured',
      properties: <String, dynamic>{'source': source},
    );
  }

  Future<T> monitor<T>(String name, Future<T> Function() operation) async {
    final watch = Stopwatch()..start();
    try {
      final result = await operation();
      await recordPerformanceMetric(
        name,
        durationMs: watch.elapsedMilliseconds,
        success: true,
      );
      return result;
    } catch (error) {
      await recordPerformanceMetric(
        name,
        durationMs: watch.elapsedMilliseconds,
        success: false,
      );
      await recordError(name, error.toString());
      rethrow;
    }
  }

  Future<void> recordPerformanceMetric(
    String name, {
    required int durationMs,
    required bool success,
  }) async {
    await init();
    final metrics = _loadMetrics()
      ..insert(
        0,
        PerformanceMetric(
          name: name,
          durationMs: durationMs,
          timestamp: AppTime.now(),
          success: success,
        ),
      );
    if (metrics.length > _maxMetrics) {
      metrics.removeRange(_maxMetrics, metrics.length);
    }

    await _prefs!.setStringList(
      _metricsKey,
      metrics.map((item) => jsonEncode(item.toJson())).toList(),
    );

    await AppAnalyticsService.instance.trackPerformance(
      name,
      durationMs: durationMs,
      success: success,
    );
  }

  Future<StabilitySnapshot> getSnapshot() async {
    await init();
    final issues = _loadIssues();
    final metrics = _loadMetrics();
    final sessions = _prefs!.getInt(_sessionsKey) ?? 0;

    final groupedDurations = <String, List<int>>{};
    for (final metric in metrics) {
      groupedDurations
          .putIfAbsent(metric.name, () => <int>[])
          .add(metric.durationMs);
    }

    final slowestOperations = groupedDurations.entries.map((entry) {
      final values = entry.value;
      final safeLength = values.isEmpty ? 1 : values.length;
      final average = values.reduce((a, b) => a + b) ~/ safeLength;
      return MapEntry(entry.key, average);
    }).toList()..sort((a, b) => b.value.compareTo(a.value));

    final averageLatencyMs = metrics.isEmpty
        ? 0
        : metrics.map((item) => item.durationMs).reduce((a, b) => a + b) ~/
              metrics.length;

    final crashFreeSessions = (sessions - issues.length)
        .clamp(0, sessions)
        .toInt();

    return StabilitySnapshot(
      totalIssues: issues.length,
      crashFreeSessions: crashFreeSessions,
      recentIssues: issues.take(5).toList(),
      slowestOperations: slowestOperations.take(5).toList(),
      averageLatencyMs: averageLatencyMs,
    );
  }

  List<StabilityIssue> _loadIssues() {
    final raw = _prefs?.getStringList(_issuesKey) ?? const <String>[];
    return raw
        .map((item) {
          try {
            final decoded = jsonDecode(item);
            if (decoded is Map<String, dynamic>) {
              return StabilityIssue.fromJson(decoded);
            }
            if (decoded is Map) {
              return StabilityIssue.fromJson(
                decoded.map((key, value) => MapEntry(key.toString(), value)),
              );
            }
          } catch (_) {
            // Ignore corrupt issue records.
          }
          return null;
        })
        .whereType<StabilityIssue>()
        .toList();
  }

  List<PerformanceMetric> _loadMetrics() {
    final raw = _prefs?.getStringList(_metricsKey) ?? const <String>[];
    return raw
        .map((item) {
          try {
            final decoded = jsonDecode(item);
            if (decoded is Map<String, dynamic>) {
              return PerformanceMetric.fromJson(decoded);
            }
            if (decoded is Map) {
              return PerformanceMetric.fromJson(
                decoded.map((key, value) => MapEntry(key.toString(), value)),
              );
            }
          } catch (_) {
            // Ignore corrupt performance records.
          }
          return null;
        })
        .whereType<PerformanceMetric>()
        .toList();
  }
}
