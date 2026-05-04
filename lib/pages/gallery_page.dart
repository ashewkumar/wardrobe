import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_config.dart';
import '../services/api_service.dart';
import '../ui/app_theme.dart';
import '../ui/modern_ui.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  List images = [];
  bool loading = true;

  String? token;
  String? userId;
  final ImagePicker _picker = ImagePicker();

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadAuthAndFetch();
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

  // Fetch images
  Future<void> _fetchImages() async {
    if (token == null || userId == null) return;

    setState(() {
      loading = true;
    });

    try {
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

        _showError("Failed to load images");
      }
    } catch (e) {
      print("ERROR: $e");

      setState(() {
        loading = false;
      });

      _showError("Connection failed");
    }
  }

  Future<void> _deleteImage(String id) async {
    if (token == null) return;

    final res = await ApiService.deleteImage(token!, id);
    if (res != null && res["status"] == true) {
      await _fetchImages();
    } else {
      _showError("Failed to delete image");
    }
  }

  Future<void> _showEditDialog(Map img) async {
    if (token == null || userId == null) return;

    final nameController = TextEditingController(text: img['image_name']?.toString() ?? '');
    final descController = TextEditingController(text: img['description']?.toString() ?? '');

    final category = img['category'] is Map ? img['category'] as Map : <String, dynamic>{};
    final categoryNameController = TextEditingController(text: (category['name'] ?? '').toString());
    final typeController = TextEditingController(text: (category['type'] ?? '').toString());
    final genderController = TextEditingController(text: (category['gender'] ?? '').toString());
    final colorController = TextEditingController(text: (category['colour'] ?? '').toString());
    final sizeController = TextEditingController(text: (category['size'] ?? '').toString());
    final seasonController = TextEditingController(text: (category['season'] ?? '').toString());
    final occasionController = TextEditingController(text: (category['occasion'] ?? '').toString());

    File? newImage;
    bool saving = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text("Edit Image"),
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
                            _showError("Failed to update image");
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernUI.appBar(
        context: context,
        title: "Image Gallery",
      ),
      body: ModernUI.pageWrapper(
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : images.isEmpty
                ? const Center(child: Text("No Images Found"))
                : Padding(
                    padding: const EdgeInsets.all(12),
                    child: GridView.builder(
                      itemCount: images.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.8,
                      ),
                      itemBuilder: (context, index) {
                        final img = images[index];

                        return ImageCard(
                          name: (img['image_name'] ?? 'Image').toString(),
                          desc: img['description']?.toString(),
                          url: ApiConfig.imageUrl(img['image_url']),
                          onEdit: () => _showEditDialog(img),
                          onDelete: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text("Delete"),
                                  content: const Text("Delete this image?"),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text("Cancel"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text("Delete"),
                                    ),
                                  ],
                                );
                              },
                            );
                            if (ok == true) {
                              await _deleteImage(img['id'].toString());
                            }
                          },
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}

class ImageCard extends StatelessWidget {
  final String name;
  final String? desc;
  final String? url;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ImageCard({
    super.key,
    required this.name,
    this.desc,
    required this.url,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.softBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.softBorder),
        boxShadow: AppTheme.softShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: url == null
                    ? const SizedBox(
                        height: 140,
                        child: Center(
                          child: Icon(Icons.image_not_supported, size: 40),
                        ),
                      )
                    : Image.network(
                        url!,
                        height: 140,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) return child;

                          return const SizedBox(
                            height: 140,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                        errorBuilder: (c, e, s) {
                          return const SizedBox(
                            height: 140,
                            child: Center(
                              child: Icon(Icons.broken_image, size: 40),
                            ),
                          );
                        },
                      ),
              ),
              Positioned(
                right: 6,
                top: 6,
                child: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == "edit" && onEdit != null) onEdit!();
                    if (value == "delete" && onDelete != null) onDelete!();
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
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                ),
              ),
            ],
          ),

          // Text
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.navy,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  desc ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
