import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../services/analytics_service.dart';
import '../services/app_time_service.dart';
import '../services/calendar_service.dart';
import '../services/notification_service.dart';
import '../services/stability_service.dart';
import '../ui/app_theme.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  String? token;
  String? userId;
  bool loading = false;

  final List<_PlanItem> _plans = [];

  @override
  void initState() {
    super.initState();
    AppAnalyticsService.instance.trackScreen('calendar_page');
    _loadAuthAndFetch();
  }

  Future<void> _loadAuthAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token");
    userId = prefs.getString("user_id");

    if (token == null || userId == null) {
      return;
    }

    await _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    if (token == null || userId == null) return;
    setState(() => loading = true);

    final dates = await AppStabilityService.instance.monitor(
      'calendar_fetch_plans',
      () => CalendarService().getImportantDates(token: token!, userId: userId!),
    );
    await AppNotificationService.instance.syncImportantDateReminders(dates);

    final mapped =
        dates
            .map(
              (d) => _PlanItem(
                id: d.id,
                title: d.title,
                date: d.date,
                occasion: d.occasion,
                notes: d.notes,
              ),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    setState(() {
      _plans
        ..clear()
        ..addAll(mapped);
      loading = false;
    });
  }

  Future<void> _openPlanDialog({int? editIndex}) async {
    final isEditing = editIndex != null;
    final existing = isEditing ? _plans[editIndex] : null;
    final titleController = TextEditingController(text: existing?.title ?? "");
    final occasionController = TextEditingController(
      text: existing?.occasion ?? "",
    );
    final notesController = TextEditingController(text: existing?.notes ?? "");
    DateTime selectedDate = existing?.date ?? AppTime.now();

    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? "Edit Plan" : "Add Plan"),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: "Title"),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return "Enter title";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final now = AppTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 5),
                          );
                          if (picked != null) {
                            setDialogState(() => selectedDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: "Date",
                            border: OutlineInputBorder(),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(_formatDate(selectedDate)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: occasionController,
                        decoration: const InputDecoration(
                          labelText: "Occasion",
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: "Notes"),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (token == null || userId == null) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Session expired. Please login again.",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          if (!formKey.currentState!.validate()) return;

                          setDialogState(() => saving = true);
                          final dateLabel = _formatDate(selectedDate);

                          final res = isEditing
                              ? await ApiService.updateImportantDate(
                                  token!,
                                  existing!.id,
                                  userId: userId,
                                  title: titleController.text.trim(),
                                  date: dateLabel,
                                  occasion: occasionController.text.trim(),
                                  notes: notesController.text.trim(),
                                )
                              : await ApiService.createImportantDate(
                                  token!,
                                  userId: userId!,
                                  title: titleController.text.trim(),
                                  date: dateLabel,
                                  occasion: occasionController.text.trim(),
                                  notes: notesController.text.trim(),
                                );

                          setDialogState(() => saving = false);

                          if (res != null && res["status"] == true) {
                            await AppAnalyticsService.instance.track(
                              isEditing
                                  ? 'calendar_plan_updated'
                                  : 'calendar_plan_created',
                              properties: <String, dynamic>{
                                'title': titleController.text.trim(),
                              },
                            );
                            if (!mounted) return;
                            Navigator.of(context).pop();
                            await _fetchPlans();
                          } else {
                            if (!mounted) return;
                            final msg = res != null && res["message"] != null
                                ? res["message"].toString()
                                : "Failed to save plan";
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(msg),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEditing ? "Save" : "Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeletePlan(int index) async {
    if (token == null) return;
    final plan = _plans[index];

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Plan?"),
        content: Text("Delete '${plan.title}' on ${_formatDate(plan.date)}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final res = await ApiService.deleteImportantDate(token!, plan.id);
    if (res != null && res["status"] == true) {
      await AppAnalyticsService.instance.track(
        'calendar_plan_deleted',
        properties: <String, dynamic>{'id': plan.id},
      );
      await _fetchPlans();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calendar & Planner"),
        actions: [
          IconButton(
            onPressed: () => _openPlanDialog(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppTheme.softShadows,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "April 2026",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(
                    14,
                    (index) => Container(
                      height: 40,
                      width: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: index == 2 ? AppTheme.mint : AppTheme.cloud,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "${index + 10}",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text("Upcoming Plans", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (loading)
            const Center(child: CircularProgressIndicator())
          else if (_plans.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppTheme.softShadows,
              ),
              child: const Text("No upcoming plans yet."),
            )
          else
            for (int i = 0; i < _plans.length; i++)
              _PlanCard(
                title: _plans[i].title,
                date: _formatDate(_plans[i].date),
                detail: _plans[i].detailLabel,
                onEdit: () => _openPlanDialog(editIndex: i),
                onDelete: () => _confirmDeletePlan(i),
              ),
        ],
      ),
    );
  }
}

class _PlanItem {
  _PlanItem({
    required this.id,
    required this.title,
    required this.date,
    required this.occasion,
    required this.notes,
  });

  final String id;
  final String title;
  final DateTime date;
  final String occasion;
  final String notes;

  String get detailLabel {
    if (occasion.isNotEmpty && notes.isNotEmpty) {
      return "$occasion - $notes";
    }
    if (occasion.isNotEmpty) return occasion;
    if (notes.isNotEmpty) return notes;
    return "No details";
  }
}

String _formatDate(DateTime date) {
  final y = date.year.toString().padLeft(4, "0");
  final m = date.month.toString().padLeft(2, "0");
  final d = date.day.toString().padLeft(2, "0");
  return "$y-$m-$d";
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.date,
    required this.detail,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final String date;
  final String detail;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadows,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.cloud,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.event_note, color: AppTheme.plum),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  "$date - $detail",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: "Edit",
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 20),
          ),
          IconButton(
            tooltip: "Delete",
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 20),
          ),
        ],
      ),
    );
  }
}
