import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_config.dart';
import '../services/api_service.dart';
import '../ui/app_theme.dart';
import 'upload_image_page.dart';

class WardrobePage extends StatefulWidget {
  const WardrobePage({super.key});

  @override
  State<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage> {
  bool loading = true;
  List images = [];
  String? token;
  String? userId;
  int selectedFilter = 0;
  final ImagePicker _picker = ImagePicker();

  final List<String> filters = const [
    "All",
    "Tops",
    "Bottoms",
    "Footwear",
    "Accessories",
    "Occasion",
  ];

  @override
  void initState() {
    super.initState();
    _loadAuthAndFetch();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Future<void> _loadAuthAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token");
    userId = prefs.getString("user_id");

    if (token == null || userId == null) {
      setState(() {
        loading = false;
      });
      return;
    }

    await _fetchImages();
  }

  Future<void> _fetchImages() async {
    if (token == null || userId == null) return;

    setState(() {
      loading = true;
    });

    final res = await ApiService.getImages(token!, userId!);
    if (res != null && res["status"] == true) {
      final list = res["data"];
      setState(() {
        images = list is List ? list : [];
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
      _showError("Failed to load items");
    }
  }

  List _applyFilter() {
    if (selectedFilter == 0) return images;

    final filter = filters[selectedFilter].toLowerCase();
    return images.where((img) {
      final category = img["category"] is Map ? img["category"] as Map : {};
      final name = (category["name"] ?? "").toString().toLowerCase();
      final type = (category["type"] ?? "").toString().toLowerCase();
      final occasion = (category["occasion"] ?? "").toString().toLowerCase();

      if (filter == "occasion") {
        return occasion.isNotEmpty;
      }

      return name.contains(filter) || type.contains(filter);
    }).toList();
  }

  Future<void> _deleteImage(String id) async {
    if (token == null) return;

    final res = await ApiService.deleteImage(token!, id);
    if (res != null && res["status"] == true) {
      await _fetchImages();
    } else {
      _showError("Failed to delete item");
    }
  }

  Future<void> _showEditDialog(Map img) async {
    if (token == null || userId == null) return;

    final nameController = TextEditingController(
      text: img['image_name']?.toString() ?? '',
    );
    final descController = TextEditingController(
      text: img['description']?.toString() ?? '',
    );

    final category = img['category'] is Map ? img['category'] as Map : {};
    final categoryNameController = TextEditingController(
      text: (category['name'] ?? '').toString(),
    );
    final typeController = TextEditingController(
      text: (category['type'] ?? '').toString(),
    );
    final genderController = TextEditingController(
      text: (category['gender'] ?? '').toString(),
    );
    final colorController = TextEditingController(
      text: (category['colour'] ?? '').toString(),
    );
    final sizeController = TextEditingController(
      text: (category['size'] ?? '').toString(),
    );
    final seasonController = TextEditingController(
      text: (category['season'] ?? '').toString(),
    );
    final occasionController = TextEditingController(
      text: (category['occasion'] ?? '').toString(),
    );

    File? newImage;
    bool saving = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text("Edit Item"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: "Image Name"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(labelText: "Description"),
                    ),
                    const Divider(height: 24),
                    TextField(
                      controller: categoryNameController,
                      decoration: const InputDecoration(labelText: "Category Name"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: typeController,
                      decoration: const InputDecoration(labelText: "Type"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: genderController,
                      decoration: const InputDecoration(labelText: "Gender"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: colorController,
                      decoration: const InputDecoration(labelText: "Color"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: sizeController,
                      decoration: const InputDecoration(labelText: "Size"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: seasonController,
                      decoration: const InputDecoration(labelText: "Season"),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: occasionController,
                      decoration: const InputDecoration(labelText: "Occasion"),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            newImage == null
                                ? "No new image"
                                : newImage!.path.split('/').last,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final picked = await _picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 85,
                            );
                            if (picked != null) {
                              setLocalState(() {
                                newImage = File(picked.path);
                              });
                            }
                          },
                          child: const Text("Change Image"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          setLocalState(() => saving = true);

                          final fields = <String, String>{
                            'user_id': userId!,
                            'image_name': nameController.text.trim(),
                            'description': descController.text.trim(),
                            'category_name': categoryNameController.text.trim(),
                            'type': typeController.text.trim(),
                            'gender': genderController.text.trim(),
                            'colour': colorController.text.trim(),
                            'size': sizeController.text.trim(),
                            'season': seasonController.text.trim(),
                            'occasion': occasionController.text.trim(),
                          }..removeWhere((key, value) => value.isEmpty);

                          final res = await ApiService.updateImage(
                            token!,
                            img['id'].toString(),
                            fields: fields,
                            imageFile: newImage,
                          );

                          setLocalState(() => saving = false);

                          if (res != null && res['status'] == true) {
                            if (!mounted) return;
                            Navigator.pop(context);
                            await _fetchImages();
                          } else {
                            _showError("Failed to update item");
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDetails(Map img) {
    final category = img["category"] is Map ? img["category"] as Map : {};
    final imageUrl = ApiConfig.imageUrl(img["image_url"]);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            shrinkWrap: true,
            children: [
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: AppTheme.cloud,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: imageUrl == null
                    ? const Icon(Icons.image, size: 70, color: Colors.black38)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) =>
                              const Icon(Icons.broken_image, size: 50),
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              Text(
                (img["image_name"] ?? "Item").toString(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                (img["description"] ?? "").toString(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _detailRow("Category", (category["name"] ?? "-").toString()),
              _detailRow("Type", (category["type"] ?? "-").toString()),
              _detailRow("Gender", (category["gender"] ?? "-").toString()),
              _detailRow("Color", (category["colour"] ?? "-").toString()),
              _detailRow("Size", (category["size"] ?? "-").toString()),
              _detailRow("Season", (category["season"] ?? "-").toString()),
              _detailRow("Occasion", (category["occasion"] ?? "-").toString()),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _applyFilter();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Wardrobe"),
        actions: [
          IconButton(
            onPressed: _fetchImages,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _FilterChips(
              filters: filters,
              selected: selectedFilter,
              onSelect: (i) => setState(() => selectedFilter = i),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? const Center(child: Text("No items found"))
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.78,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final category =
                                item["category"] is Map ? item["category"] as Map : {};
                            final imageUrl = ApiConfig.imageUrl(
                              item["image_url"],
                            );

                            return InkWell(
                              onTap: () => _showDetails(item as Map),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: AppTheme.softShadows,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: AppTheme.cloud,
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                top: Radius.circular(20),
                                              ),
                                            ),
                                            child: imageUrl == null
                                                ? const Icon(
                                                    Icons.image,
                                                    color: AppTheme.plum,
                                                    size: 50,
                                                  )
                                                : ClipRRect(
                                                    borderRadius:
                                                        const BorderRadius.vertical(
                                                      top: Radius.circular(20),
                                                    ),
                                                    child: Image.network(
                                                      imageUrl,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (c, e, s) =>
                                                          const Icon(
                                                            Icons.broken_image,
                                                            size: 40,
                                                          ),
                                                    ),
                                                  ),
                                          ),
                                          Positioned(
                                            right: 6,
                                            top: 6,
                                            child: PopupMenuButton<String>(
                                              onSelected: (value) async {
                                                if (value == "edit") {
                                                  await _showEditDialog(item as Map);
                                                }
                                                if (value == "delete") {
                                                  final ok = await showDialog<bool>(
                                                    context: context,
                                                    builder: (context) {
                                                      return AlertDialog(
                                                        title: const Text("Delete"),
                                                        content: const Text(
                                                          "Delete this item?",
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
                                                    await _deleteImage(
                                                      item["id"].toString(),
                                                    );
                                                  }
                                                }
                                              },
                                              itemBuilder: (context) => [
                                                const PopupMenuItem(
                                                  value: "edit",
                                                  child: Text("Edit"),
                                                ),
                                                const PopupMenuItem(
                                                  value: "delete",
                                                  child: Text("Delete"),
                                                ),
                                              ],
                                              icon: const Icon(
                                                Icons.more_vert,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            (item["image_name"] ?? "Item")
                                                .toString(),
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "${(category["name"] ?? "-").toString()} - "
                                            "${(category["colour"] ?? "-").toString()}",
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "wardrobe_add_item_fab",
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const UploadImagePage()),
        ),
        backgroundColor: AppTheme.plum,
        icon: const Icon(Icons.add),
        label: const Text("Add item"),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.filters,
    required this.selected,
    required this.onSelect,
  });

  final List<String> filters;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return ChoiceChip(
            selected: selected == index,
            label: Text(filters[index]),
            onSelected: (_) => onSelect(index),
          );
        },
      ),
    );
  }
}
