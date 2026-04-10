import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../ui/app_theme.dart';

class TravelPage extends StatefulWidget {
  const TravelPage({super.key});

  @override
  State<TravelPage> createState() => _TravelPageState();
}

class _TravelPageState extends State<TravelPage> {
  String? token;
  String? userId;
  bool loading = false;
  List<TravelPlan> plans = [];

  @override
  void initState() {
    super.initState();
    _loadAuthAndFetch();
  }

  Future<void> _loadAuthAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token");
    userId = prefs.getString("user_id");

    if (token == null || userId == null) return;
    await _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    if (token == null || userId == null) return;
    setState(() => loading = true);

    final res = await ApiService.getTravelPlans(token!, userId!);
    if (res != null && res['status'] == true) {
      final list = res['data'];
      final parsed = <TravelPlan>[];
      if (list is List) {
        for (final item in list) {
          if (item is Map) {
            parsed.add(TravelPlan.fromJson(item));
          }
        }
      }
      setState(() {
        plans = parsed;
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  Future<void> _showPlanDialog({TravelPlan? existing}) async {
    final isEditing = existing != null;
    final destinationController =
        TextEditingController(text: existing?.destination ?? "");
    final weatherController =
        TextEditingController(text: existing?.weather ?? "");
    final notesController = TextEditingController(text: existing?.notes ?? "");
    DateTime startDate = existing?.startDate ?? DateTime.now();
    DateTime endDate = existing?.endDate ?? DateTime.now();
    bool saving = false;

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? "Edit Trip" : "Add Trip"),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: destinationController,
                        decoration: const InputDecoration(labelText: "Destination"),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return "Enter destination";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: DateTime(DateTime.now().year - 1),
                            lastDate: DateTime(DateTime.now().year + 5),
                          );
                          if (picked != null) {
                            setDialogState(() => startDate = picked);
                            if (endDate.isBefore(startDate)) {
                              setDialogState(() => endDate = picked);
                            }
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: "Start date",
                            border: OutlineInputBorder(),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(_formatDate(startDate)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: startDate,
                            lastDate: DateTime(DateTime.now().year + 5),
                          );
                          if (picked != null) {
                            setDialogState(() => endDate = picked);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: "End date",
                            border: OutlineInputBorder(),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(_formatDate(endDate)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: weatherController,
                        decoration: const InputDecoration(labelText: "Weather"),
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
                          if (token == null || userId == null) return;
                          if (!formKey.currentState!.validate()) return;

                          setDialogState(() => saving = true);

                          final startLabel = _formatDate(startDate);
                          final endLabel = _formatDate(endDate);
                          final res = isEditing
                              ? await ApiService.updateTravelPlan(
                                  token!,
                                  existing!.id,
                                  userId: userId,
                                  destination: destinationController.text.trim(),
                                  startDate: startLabel,
                                  endDate: endLabel,
                                  weather: weatherController.text.trim(),
                                  notes: notesController.text.trim(),
                                )
                              : await ApiService.createTravelPlan(
                                  token!,
                                  userId: userId!,
                                  destination: destinationController.text.trim(),
                                  startDate: startLabel,
                                  endDate: endLabel,
                                  weather: weatherController.text.trim(),
                                  notes: notesController.text.trim(),
                                );

                          setDialogState(() => saving = false);

                          if (res != null && res['status'] == true) {
                            if (!mounted) return;
                            Navigator.of(context).pop();
                            await _fetchPlans();
                          } else {
                            if (!mounted) return;
                            final msg = res != null && res['message'] != null
                                ? res['message'].toString()
                                : "Failed to save trip";
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

  Future<void> _confirmDeletePlan(TravelPlan plan) async {
    if (token == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete trip?"),
        content: Text("Delete trip to ${plan.destination}?") ,
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
    final res = await ApiService.deleteTravelPlan(token!, plan.id);
    if (res != null && res['status'] == true) {
      await _fetchPlans();
    }
  }

  Future<void> _showItemDialog({required TravelPlan plan, TravelItem? existing}) async {
    final isEditing = existing != null;
    final labelController = TextEditingController(text: existing?.label ?? "");
    bool checked = existing?.isChecked ?? false;
    bool saving = false;
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? "Edit item" : "Add item"),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: labelController,
                      decoration: const InputDecoration(labelText: "Checklist item"),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return "Enter item";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: checked,
                      onChanged: (value) => setDialogState(() => checked = value),
                      title: const Text("Packed"),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
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
                          if (token == null || userId == null) return;
                          if (!formKey.currentState!.validate()) return;

                          setDialogState(() => saving = true);

                          final res = isEditing
                              ? await ApiService.updateTravelItem(
                                  token!,
                                  existing!.id,
                                  userId: userId,
                                  label: labelController.text.trim(),
                                  isChecked: checked,
                                )
                              : await ApiService.createTravelItem(
                                  token!,
                                  plan.id,
                                  userId: userId!,
                                  label: labelController.text.trim(),
                                  isChecked: checked,
                                );

                          setDialogState(() => saving = false);

                          if (res != null && res['status'] == true) {
                            if (!mounted) return;
                            Navigator.of(context).pop();
                            await _fetchPlans();
                          } else {
                            if (!mounted) return;
                            final msg = res != null && res['message'] != null
                                ? res['message'].toString()
                                : "Failed to save item";
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

  Future<void> _deleteItem(TravelItem item) async {
    if (token == null) return;
    final res = await ApiService.deleteTravelItem(token!, item.id);
    if (res != null && res['status'] == true) {
      await _fetchPlans();
    }
  }

  Future<void> _toggleItem(TravelItem item, bool value) async {
    if (token == null || userId == null) return;
    final res = await ApiService.updateTravelItem(
      token!,
      item.id,
      userId: userId,
      label: item.label,
      isChecked: value,
    );
    if (res != null && res['status'] == true) {
      await _fetchPlans();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Travel Planner"),
        actions: [
          IconButton(
            onPressed: () => _showPlanDialog(),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (plans.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: AppTheme.softShadows,
                    ),
                    child: const Text("No trips yet."),
                  ),
                for (final plan in plans) ...[
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: AppTheme.softShadows,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              plan.destination,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => _showPlanDialog(existing: plan),
                                  icon: const Icon(Icons.edit, size: 20),
                                ),
                                IconButton(
                                  onPressed: () => _confirmDeletePlan(plan),
                                  icon: const Icon(Icons.delete_outline, size: 20),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _TripRow(label: "Dates", value: plan.dateRangeLabel),
                        if (plan.weather.isNotEmpty)
                          _TripRow(label: "Weather", value: plan.weather),
                        if (plan.notes.isNotEmpty)
                          _TripRow(label: "Notes", value: plan.notes),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _showPlanDialog(existing: plan),
                                child: const Text("Edit trip"),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _showItemDialog(plan: plan),
                                child: const Text("Add item"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Packing Checklist",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  if (plan.items.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppTheme.softShadows,
                      ),
                      child: const Text("No items yet."),
                    )
                  else
                    for (final item in plan.items)
                      _ChecklistItem(
                        label: item.label,
                        checked: item.isChecked,
                        onChanged: (v) => _toggleItem(item, v ?? false),
                        onEdit: () => _showItemDialog(plan: plan, existing: item),
                        onDelete: () => _deleteItem(item),
                      ),
                  const SizedBox(height: 24),
                ],
              ],
            ),
    );
  }
}

class TravelPlan {
  TravelPlan({
    required this.id,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.weather,
    required this.notes,
    required this.items,
  });

  final String id;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final String weather;
  final String notes;
  final List<TravelItem> items;

  String get dateRangeLabel {
    final s = _formatDate(startDate);
    final e = _formatDate(endDate);
    return "$s - $e";
  }

  static TravelPlan fromJson(Map data) {
    final itemsRaw = data['items'];
    final items = <TravelItem>[];
    if (itemsRaw is List) {
      for (final item in itemsRaw) {
        if (item is Map) items.add(TravelItem.fromJson(item));
      }
    }
    return TravelPlan(
      id: data['id'].toString(),
      destination: (data['destination'] ?? '').toString(),
      startDate: DateTime.tryParse((data['start_date'] ?? '').toString()) ??
          DateTime.now(),
      endDate: DateTime.tryParse((data['end_date'] ?? '').toString()) ??
          DateTime.now(),
      weather: (data['weather'] ?? '').toString(),
      notes: (data['notes'] ?? '').toString(),
      items: items,
    );
  }
}

class TravelItem {
  TravelItem({
    required this.id,
    required this.label,
    required this.isChecked,
  });

  final String id;
  final String label;
  final bool isChecked;

  static TravelItem fromJson(Map data) {
    return TravelItem(
      id: data['id'].toString(),
      label: (data['label'] ?? '').toString(),
      isChecked: data['is_checked'] == true || data['is_checked'] == 1,
    );
  }
}

String _formatDate(DateTime date) {
  final y = date.year.toString().padLeft(4, "0");
  final m = date.month.toString().padLeft(2, "0");
  final d = date.day.toString().padLeft(2, "0");
  return "$y-$m-$d";
}

class _TripRow extends StatelessWidget {
  const _TripRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistItem extends StatelessWidget {
  const _ChecklistItem({
    required this.label,
    required this.checked,
    required this.onChanged,
    required this.onEdit,
    required this.onDelete,
  });

  final String label;
  final bool checked;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadows,
      ),
      child: Row(
        children: [
          Checkbox(value: checked, onChanged: onChanged),
          Expanded(child: Text(label)),
          IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, size: 18),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
          ),
        ],
      ),
    );
  }
}
