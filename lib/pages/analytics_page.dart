import 'package:flutter/material.dart';

import '../services/analytics_service.dart';
import '../services/app_time_service.dart';
import '../services/notification_service.dart';
import '../services/stability_service.dart';
import '../ui/app_theme.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  AnalyticsSnapshot? analytics;
  StabilitySnapshot? stability;
  NotificationSettingsSnapshot? notifications;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    AppAnalyticsService.instance.trackScreen('analytics_page');
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => loading = true);

    final analyticsSnapshot = await AppAnalyticsService.instance.getSnapshot();
    final stabilitySnapshot = await AppStabilityService.instance.getSnapshot();
    final notificationSnapshot = await AppNotificationService.instance
        .getSnapshot();

    if (!mounted) return;
    setState(() {
      analytics = analyticsSnapshot;
      stability = stabilitySnapshot;
      notifications = notificationSnapshot;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final analyticsData = analytics;
    final stabilityData = stability;
    final notificationData = notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Analytics"),
        actions: [
          IconButton(
            onPressed: _loadDashboard,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading || analyticsData == null || stabilityData == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: "Usage Events",
                        value: analyticsData.totalEvents.toString(),
                        subtitle:
                            "${analyticsData.uniqueEventTypes} event types",
                        icon: Icons.insights,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        title: "Screen Views",
                        value: analyticsData.screenViews.toString(),
                        subtitle: "Captured in-app",
                        icon: Icons.smart_display,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        title: "Pending Reminders",
                        value: notificationData?.pendingCount.toString() ?? '0',
                        subtitle: notificationData?.enabled == true
                            ? "Notifications enabled"
                            : "Notifications disabled",
                        icon: Icons.notifications_active,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        title: "Crash-Free Baseline",
                        value: stabilityData.crashFreeSessions.toString(),
                        subtitle: stabilityData.totalIssues == 0
                            ? "No captured crashes"
                            : "${stabilityData.totalIssues} issues captured",
                        icon: Icons.health_and_safety,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  "Activity Trend",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _DailyActivityChart(items: analyticsData.dailyCounts),
                const SizedBox(height: 20),
                Text(
                  "Top Events",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (analyticsData.topEvents.isEmpty)
                  const _EmptyCard(label: "No usage events captured yet.")
                else
                  for (final item in analyticsData.topEvents)
                    _DataRowCard(label: item.key, value: item.value.toString()),
                const SizedBox(height: 20),
                Text(
                  "Performance",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _DataRowCard(
                  label: "Average latency",
                  value: "${stabilityData.averageLatencyMs} ms",
                ),
                if (stabilityData.slowestOperations.isEmpty)
                  const _EmptyCard(label: "No performance metrics yet.")
                else
                  for (final item in stabilityData.slowestOperations)
                    _DataRowCard(label: item.key, value: "${item.value} ms"),
                const SizedBox(height: 20),
                Text(
                  "Recent Activity",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (analyticsData.recentEvents.isEmpty)
                  const _EmptyCard(label: "No recent activity yet.")
                else
                  for (final event in analyticsData.recentEvents)
                    _EventCard(event: event),
                const SizedBox(height: 20),
                Text(
                  "Stability Feed",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (stabilityData.recentIssues.isEmpty)
                  const _EmptyCard(label: "No stability issues recorded.")
                else
                  for (final issue in stabilityData.recentIssues)
                    _IssueCard(issue: issue),
              ],
            ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.plum),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _DailyActivityChart extends StatelessWidget {
  const _DailyActivityChart({required this.items});

  final List<DailyEventCount> items;

  @override
  Widget build(BuildContext context) {
    final maxCount = items.isEmpty
        ? 1
        : items.map((item) => item.count).reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadows,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: items
            .map(
              (item) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.count.toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height:
                            (maxCount == 0
                                    ? 6
                                    : ((item.count / maxCount) * 96).clamp(
                                        6,
                                        96,
                                      ))
                                .toDouble(),
                        decoration: BoxDecoration(
                          color: AppTheme.plum,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.label,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _DataRowCard extends StatelessWidget {
  const _DataRowCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadows,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final AnalyticsEvent event;

  @override
  Widget build(BuildContext context) {
    final firstProperty = event.properties.entries.isEmpty
        ? null
        : event.properties.entries.first;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(event.name, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            AppTime.formatDateTime(event.timestamp),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (firstProperty != null) const SizedBox(height: 4),
          if (firstProperty != null)
            Text(
              '${firstProperty.key}: ${firstProperty.value}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({required this.issue});

  final StabilityIssue issue;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(issue.source, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            AppTime.formatDateTime(issue.timestamp),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Text(issue.message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadows,
      ),
      child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
