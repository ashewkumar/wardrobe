import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_config.dart';
import '../services/api_service.dart';
import '../ui/app_theme.dart';

class AiSuggestionPage extends StatefulWidget {
  const AiSuggestionPage({super.key});

  @override
  State<AiSuggestionPage> createState() => _AiSuggestionPageState();
}

class _AiSuggestionPageState extends State<AiSuggestionPage> {
  String _occasion = "Office";
  String _weather = "Warm";
  String _style = "Minimal";
  bool _loading = false;
  String _statusMessage = "";
  Map<String, Map<String, dynamic>> _suggestedByType = {};
  List<String> _suggestedImages = [];
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _suggestNow(auto: true);
  }

  String _seasonForWeather(String weather) {
    switch (weather.toLowerCase()) {
      case "cool":
        return "Winter";
      case "rainy":
        return "Spring";
      case "warm":
      default:
        return "Summer";
    }
  }

  String _canonicalType(String raw) {
    final value = raw.toLowerCase();
    if (value.contains("top") ||
        value.contains("shirt") ||
        value.contains("blouse")) {
      return "Top";
    }
    if (value.contains("bottom") ||
        value.contains("pants") ||
        value.contains("trouser") ||
        value.contains("skirt")) {
      return "Bottom";
    }
    if (value.contains("foot") ||
        value.contains("shoe") ||
        value.contains("sneaker") ||
        value.contains("loafer")) {
      return "Footwear";
    }
    if (value.contains("access") ||
        value.contains("bag") ||
        value.contains("belt")) {
      return "Accessory";
    }
    return "Other";
  }

  bool _occasionMatches(String itemOccasion, String selectedOccasion) {
    final item = itemOccasion.toLowerCase();
    final selected = selectedOccasion.toLowerCase();

    if (selected == "office") {
      return item.contains("office") ||
          item.contains("work") ||
          item.contains("formal");
    }
    if (selected.contains("date") || selected.contains("event")) {
      return item.contains("date") ||
          item.contains("event") ||
          item.contains("dinner") ||
          item.contains("night out");
    }
    return item.contains(selected);
  }

  void _setStateSafe(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  Future<void> _suggestNow({bool auto = false}) async {
    final requestId = ++_requestId;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");
    final userId = prefs.getString("user_id");

    if (token == null || userId == null) {
      if (!auto && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please login to get suggestions.")),
        );
      }
      return;
    }

    _setStateSafe(() {
      _loading = true;
      _statusMessage = "";
      _suggestedByType = {};
      _suggestedImages = [];
    });

    try {
      final res = await ApiService.getImages(token, userId);
      if (res == null || res["status"] != true) {
        if (requestId == _requestId) {
          _setStateSafe(() {
            _statusMessage = "Could not load wardrobe items.";
          });
        }
        return;
      }

      final list = res["data"];
      final items = <Map<String, dynamic>>[];
      if (list is List) {
        for (final item in list) {
          if (item is Map) {
            items.add(Map<String, dynamic>.from(item));
          }
        }
      }
      if (items.isEmpty) {
        if (requestId == _requestId) {
          _setStateSafe(() {
            _statusMessage = "No wardrobe items found.";
          });
        }
        return;
      }

      final season = _seasonForWeather(_weather);
      final occasion = _occasion;

      final filtered = items.where((item) {
        final category = item["category"];
        if (category is! Map) return false;
        final itemOccasion = (category["occasion"] ?? "").toString();
        if (itemOccasion.isEmpty) return false;
        if (!_occasionMatches(itemOccasion, occasion)) return false;

        final itemSeason = (category["season"] ?? "").toString();
        if (itemSeason.isNotEmpty &&
            !itemSeason.toLowerCase().contains(season.toLowerCase())) {
          return false;
        }
        return true;
      }).toList();

      final source = filtered.isNotEmpty ? filtered : items;
      final Map<String, Map<String, dynamic>> picked = {};
      for (final item in source) {
        final category = item["category"];
        if (category is! Map) continue;
        final typeRaw =
            (category["type"] ?? category["name"] ?? "").toString();
        if (typeRaw.isEmpty) continue;
        final type = _canonicalType(typeRaw);
        if (type == "Other") continue;
        if (!picked.containsKey(type)) {
          picked[type] = item;
        }
      }

      if (picked.isEmpty) {
        if (requestId == _requestId) {
          _setStateSafe(() {
            _statusMessage =
                "No matching outfit pieces found for $occasion. Try another occasion.";
          });
        }
        return;
      }

      final images = <String>[];
      for (final item in picked.values) {
        final url = ApiConfig.imageUrl(item["image_url"]);
        if (url != null) {
          images.add(url);
        }
      }

      if (requestId == _requestId) {
        _setStateSafe(() {
          _suggestedByType = picked;
          _suggestedImages = images;
          _statusMessage = "Suggested for $occasion - $season - $_style";
        });
      }
    } catch (e) {
      if (requestId == _requestId) {
        _setStateSafe(() {
          _statusMessage = "Something went wrong. Please try again.";
        });
      }
    } finally {
      if (requestId == _requestId) {
        _setStateSafe(() {
          _loading = false;
        });
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Outfit Suggestions")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text("Occasion", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              _ChipOption(
                label: "Office",
                selected: _occasion == "Office",
                onTap: () {
                  setState(() => _occasion = "Office");
                  _suggestNow();
                },
              ),
              _ChipOption(
                label: "Casual",
                selected: _occasion == "Casual",
                onTap: () {
                  setState(() => _occasion = "Casual");
                  _suggestNow();
                },
              ),
              _ChipOption(
                label: "Party",
                selected: _occasion == "Party",
                onTap: () {
                  setState(() => _occasion = "Party");
                  _suggestNow();
                },
              ),
              _ChipOption(
                label: "Wedding",
                selected: _occasion == "Wedding",
                onTap: () {
                  setState(() => _occasion = "Wedding");
                  _suggestNow();
                },
              ),
              _ChipOption(
                label: "Travel",
                selected: _occasion == "Travel",
                onTap: () {
                  setState(() => _occasion = "Travel");
                  _suggestNow();
                },
              ),
              _ChipOption(
                label: "Date / Event",
                selected: _occasion == "Date / Event",
                onTap: () {
                  setState(() => _occasion = "Date / Event");
                  _suggestNow();
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text("Filters", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _weather,
                  items: const [
                    DropdownMenuItem(value: "Warm", child: Text("Warm")),
                    DropdownMenuItem(value: "Cool", child: Text("Cool")),
                    DropdownMenuItem(value: "Rainy", child: Text("Rainy")),
                  ],
                  onChanged: (value) =>
                      setState(() => _weather = value ?? "Warm"),
                  decoration: const InputDecoration(labelText: "Weather"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _style,
                  items: const [
                    DropdownMenuItem(value: "Minimal", child: Text("Minimal")),
                    DropdownMenuItem(value: "Bold", child: Text("Bold")),
                    DropdownMenuItem(value: "Classic", child: Text("Classic")),
                  ],
                  onChanged: (value) =>
                      setState(() => _style = value ?? "Minimal"),
                  decoration: const InputDecoration(labelText: "Style tag"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : () => _suggestNow(),
              child: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Suggest Now"),
            ),
          ),
          const SizedBox(height: 16),
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
                Text("Suggested Outfit",
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                if (_suggestedByType.isNotEmpty) ...[
                  for (final type in ["Top", "Bottom", "Footwear", "Accessory"])
                    if (_suggestedByType.containsKey(type))
                      _OutfitRow(
                        label: type,
                        value:
                            (_suggestedByType[type]?["image_name"] ?? "").toString(),
                      ),
                ] else if (_statusMessage.isNotEmpty) ...[
                  Text(
                    _statusMessage,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ] else ...[
                  Text(
                    "Tap Suggest Now to generate a look.",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                if (_suggestedImages.isNotEmpty) const SizedBox(height: 12),
                if (_suggestedImages.isNotEmpty)
                  SizedBox(
                    height: 88,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _suggestedImages.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final url = _suggestedImages[i];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            url,
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) =>
                                const Icon(Icons.broken_image),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  "Reason: $_occasion - $_weather - $_style palette",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        child: const Text("Like"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _loading ? null : () => _suggestNow(),
                        child: const Text("Regenerate"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        child: const Text("Save"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChipOption extends StatelessWidget {
  const _ChipOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _OutfitRow extends StatelessWidget {
  const _OutfitRow({required this.label, required this.value});

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
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}









