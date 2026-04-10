import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../services/calendar_service.dart';
import '../ui/app_theme.dart';
import '../ui/modern_ui.dart';

class ImportantDatesPage extends StatefulWidget {
  const ImportantDatesPage({super.key});

  @override
  State<ImportantDatesPage> createState() => _ImportantDatesPageState();
}

class _ImportantDatesPageState extends State<ImportantDatesPage> {
  String? token;
  String? userId;

  bool loading = false;
  List<ImportantDate> dates = [];
  final TextEditingController _searchController = TextEditingController();
  String _query = "";

  @override
  void initState() {
    super.initState();
    _loadAuthAndFetch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAuthAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token");
    userId = prefs.getString("user_id");

    if (token == null || userId == null) {
      return;
    }

    await _fetchDates();
  }

  Future<void> _fetchDates() async {
    if (token == null || userId == null) return;

    setState(() {
      loading = true;
    });

    final list = await CalendarService().getImportantDates(
      token: token!,
      userId: userId!,
    );

    setState(() {
      dates = list;
      loading = false;
    });
  }

  Future<void> _deleteDate(ImportantDate item) async {
    if (token == null) return;

    final res = await ApiService.deleteImportantDate(token!, item.id);
    if (res != null && res["status"] == true) {
      await _fetchDates();
    }
  }

  Future<void> _showAddDialog() async {
    final titleController = TextEditingController();
    final occasionController = TextEditingController();
    final notesController = TextEditingController();
    DateTime? selectedDate;

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Important Date"),
          content: StatefulBuilder(
            builder: (context, setLocalState) {
              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: "Title",
                        ),
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
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? now,
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 5),
                          );
                          if (picked != null) {
                            setLocalState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: "Date",
                            border: OutlineInputBorder(),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              selectedDate == null
                                  ? "Pick a date"
                                  : "${selectedDate!.year.toString().padLeft(4, "0")}-"
                                    "${selectedDate!.month.toString().padLeft(2, "0")}-"
                                    "${selectedDate!.day.toString().padLeft(2, "0")}",
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: occasionController,
                        decoration: const InputDecoration(
                          labelText: "Occasion",
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: "Notes",
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (token == null || userId == null) return;

                if (!formKey.currentState!.validate()) return;

                if (selectedDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please pick a date")),
                  );
                  return;
                }

                final dateLabel =
                    "${selectedDate!.year.toString().padLeft(4, "0")}-"
                    "${selectedDate!.month.toString().padLeft(2, "0")}-"
                    "${selectedDate!.day.toString().padLeft(2, "0")}";

                final res = await ApiService.createImportantDate(
                  token!,
                  userId: userId!,
                  title: titleController.text.trim(),
                  date: dateLabel,
                  occasion: occasionController.text.trim(),
                  notes: notesController.text.trim(),
                );

                if (res != null && res["status"] == true) {
                  if (!mounted) return;
                  Navigator.pop(context);
                  await _fetchDates();
                } else {
                  if (!mounted) return;
                  final msg = res != null && res["message"] != null
                      ? res["message"].toString()
                      : "Failed to save date";
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(msg),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditDialog(ImportantDate item) async {
    final titleController = TextEditingController(text: item.title);
    final occasionController = TextEditingController(text: item.occasion);
    final notesController = TextEditingController(text: item.notes);
    DateTime selectedDate = item.date;

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Important Date"),
          content: StatefulBuilder(
            builder: (context, setLocalState) {
              return Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: "Title",
                        ),
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
                          final now = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 5),
                          );
                          if (picked != null) {
                            setLocalState(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: "Date",
                            border: OutlineInputBorder(),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "${selectedDate.year.toString().padLeft(4, "0")}-"
                              "${selectedDate.month.toString().padLeft(2, "0")}-"
                              "${selectedDate.day.toString().padLeft(2, "0")}",
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: occasionController,
                        decoration: const InputDecoration(
                          labelText: "Occasion",
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: "Notes",
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (token == null) return;
                if (!formKey.currentState!.validate()) return;

                final dateLabel =
                    "${selectedDate.year.toString().padLeft(4, "0")}-"
                    "${selectedDate.month.toString().padLeft(2, "0")}-"
                    "${selectedDate.day.toString().padLeft(2, "0")}";

                final res = await ApiService.updateImportantDate(
                  token!,
                  item.id,
                  userId: userId,
                  title: titleController.text.trim(),
                  date: dateLabel,
                  occasion: occasionController.text.trim(),
                  notes: notesController.text.trim(),
                );

                if (res != null && res["status"] == true) {
                  if (!mounted) return;
                  Navigator.pop(context);
                  await _fetchDates();
                } else {
                  if (!mounted) return;
                  final msg = res != null && res["message"] != null
                      ? res["message"].toString()
                      : "Failed to update date";
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(msg),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? dates
        : dates.where((d) {
            final haystack = [
              d.title,
              d.occasion,
              d.notes,
              d.dateLabel,
            ].join(" ").toLowerCase();
            return haystack.contains(q);
          }).toList();

    return Scaffold(
      appBar: ModernUI.appBar(
        context: context,
        title: "Important Dates",
      ),
      body: ModernUI.pageWrapper(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: "Search by title, occasion, date...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (v) {
                  setState(() {
                    _query = v;
                  });
                },
              ),
              const SizedBox(height: 14),
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? Center(
                            child: Text(
                              dates.isEmpty
                                  ? "No important dates yet"
                                  : "No matching dates",
                              style: const TextStyle(color: Colors.black54),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final item = filtered[i];
                              final now = DateTime.now();
                              final isToday = item.date.year == now.year &&
                                  item.date.month == now.month &&
                                  item.date.day == now.day;

                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isToday
                                      ? const Color(0xFFEFF7FF)
                                      : AppTheme.softBg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isToday
                                        ? AppTheme.navy
                                        : AppTheme.softBorder,
                                  ),
                                  boxShadow: AppTheme.softShadows,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.navy.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.event,
                                        color: AppTheme.navy,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item.title,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                              if (isToday)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.navy,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                      10,
                                                    ),
                                                  ),
                                                  child: const Text(
                                                    "Today",
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.dateLabel,
                                            style: const TextStyle(
                                              color: Colors.black54,
                                            ),
                                          ),
                                          if (item.occasion.isNotEmpty)
                                            const SizedBox(height: 6),
                                          if (item.occasion.isNotEmpty)
                                            Text(
                                              "Occasion: ${item.occasion}",
                                              style: const TextStyle(
                                                color: Colors.black54,
                                              ),
                                            ),
                                          if (item.notes.isNotEmpty)
                                            const SizedBox(height: 6),
                                          if (item.notes.isNotEmpty)
                                            Text(
                                              item.notes,
                                              style: const TextStyle(
                                                color: Colors.black54,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit_outlined,
                                        color: AppTheme.navy,
                                      ),
                                      onPressed: () => _showEditDialog(item),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.red,
                                      ),
                                      onPressed: () async {
                                        final ok = await showDialog<bool>(
                                          context: context,
                                          builder: (context) {
                                            return AlertDialog(
                                              title: const Text("Delete"),
                                              content: const Text(
                                                "Delete this date?",
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                    context,
                                                    false,
                                                  ),
                                                  child: const Text("Cancel"),
                                                ),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                    context,
                                                    true,
                                                  ),
                                                  child: const Text("Delete"),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                        if (ok == true) {
                                          await _deleteDate(item);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: AppTheme.navy,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
