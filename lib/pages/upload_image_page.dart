import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_config.dart';
import '../services/api_service.dart';
import '../ui/app_theme.dart';
import '../ui/modern_ui.dart';

class UploadImagePage extends StatefulWidget {
  const UploadImagePage({super.key});

  @override
  State<UploadImagePage> createState() => _UploadImagePageState();
}

class _UploadImagePageState extends State<UploadImagePage> {
  File? _image;
  bool _loading = false;
  bool _loadingOptions = false;

  final ImagePicker picker = ImagePicker();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  final TextEditingController _categoryName = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _sizeController = TextEditingController();
  final TextEditingController _seasonController = TextEditingController();
  final TextEditingController _occasionController = TextEditingController();

  List<String> _typeOptions = [];
  List<String> _genderOptions = [];
  List<String> _colorOptions = [];
  List<String> _sizeOptions = [];
  List<String> _seasonOptions = [];
  List<String> _occasionOptions = [];

  String? _selectedType;
  String? _selectedGender;
  String? _selectedColor;
  String? _selectedSize;
  String? _selectedSeason;
  String? _selectedOccasion;

  // ---------------- PICK IMAGE ----------------

  @override
  void initState() {
    super.initState();
    _loadCategoryOptions();
  }

  Future<void> _loadCategoryOptions() async {
    if (_loadingOptions) return;
    setState(() => _loadingOptions = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getString('user_id');

    if (token == null || userId == null) {
      if (mounted) setState(() => _loadingOptions = false);
      return;
    }

    try {
      final res = await ApiService.getImages(token, userId);
      final list = res is Map ? res["data"] : null;

      final typeMap = <String, String>{};
      final genderMap = <String, String>{};
      final colorMap = <String, String>{};
      final sizeMap = <String, String>{};
      final seasonMap = <String, String>{};
      final occasionMap = <String, String>{};

      void addOption(Map<String, String> target, dynamic raw) {
        final value = raw?.toString().trim();
        if (value == null || value.isEmpty) return;
        final key = value.toLowerCase();
        target.putIfAbsent(key, () => value);
      }

      if (list is List) {
        for (final item in list) {
          if (item is! Map) continue;
          final category = item["category"];
          if (category is! Map) continue;
          addOption(typeMap, category["type"]);
          addOption(genderMap, category["gender"]);
          addOption(colorMap, category["colour"]);
          addOption(colorMap, category["color"]);
          addOption(sizeMap, category["size"]);
          addOption(seasonMap, category["season"]);
          addOption(occasionMap, category["occasion"]);
        }
      }

      List<String> sorted(Map<String, String> map) {
        final values = map.values.toList();
        values.sort(
          (a, b) => a.toLowerCase().compareTo(b.toLowerCase()),
        );
        return values;
      }

      if (mounted) {
        setState(() {
          _typeOptions = sorted(typeMap);
          _genderOptions = sorted(genderMap);
          _colorOptions = sorted(colorMap);
          _sizeOptions = sorted(sizeMap);
          _seasonOptions = sorted(seasonMap);
          _occasionOptions = sorted(occasionMap);
        });
      }
    } finally {
      if (mounted) setState(() => _loadingOptions = false);
    }
  }

  Future pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Camera"),
                onTap: () async {
                  Navigator.pop(context);

                  final picked = await picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 80,
                  );

                  if (picked != null && mounted) {
                    setState(() {
                      _image = File(picked.path);
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Gallery"),
                onTap: () async {
                  Navigator.pop(context);

                  final picked = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                  );

                  if (picked != null && mounted) {
                    setState(() {
                      _image = File(picked.path);
                    });
                  }
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.close),
                title: const Text("Cancel"),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------------- UPLOAD IMAGE ----------------

  Future uploadImage() async {
    if (_image == null) {
      showMessage("Select image first");
      return;
    }

    if (_nameController.text.isEmpty) {
      showMessage("Enter image name");
      return;
    }

    if (_categoryName.text.isEmpty) {
      showMessage("Enter category name");
      return;
    }

    setState(() => _loading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getString('user_id');

    if (token == null || token.isEmpty) {
      setState(() => _loading = false);
      showMessage("Session expired. Please login again.");
      return;
    }

    final uri = ApiConfig.uri("upload-image");

    var request = http.MultipartRequest('POST', uri);

    request.headers.addAll({
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    });

    // Fields
    request.fields.addAll({
      // user_images
      if (userId != null) 'user_id': userId,
      'image_name': _nameController.text.trim(),
      'description': _descController.text.trim(),

      // wardrobe_categories
      'category_name': _categoryName.text.trim(),
      'type': _typeController.text.trim(),
      'gender': _genderController.text.trim(),
      'colour': _colorController.text.trim(),
      'size': _sizeController.text.trim(),
      'season': _seasonController.text.trim(),
      'occasion': _occasionController.text.trim(),
    });

    // File
    final bytes = await _image!.readAsBytes();
    final fileName = _image!.path.split('/').last;

    final multipartFile = http.MultipartFile.fromBytes(
      'image',
      bytes,
      filename: fileName,
    );

    request.files.add(multipartFile);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    setState(() => _loading = false);

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      showMessage("Upload Successful ");

      setState(() {
        _image = null;

        _nameController.clear();
        _descController.clear();

        _categoryName.clear();
        _typeController.clear();
        _genderController.clear();
        _colorController.clear();
        _sizeController.clear();
        _seasonController.clear();
        _occasionController.clear();

        _selectedType = null;
        _selectedGender = null;
        _selectedColor = null;
        _selectedSize = null;
        _selectedSeason = null;
        _selectedOccasion = null;
      });

      _loadCategoryOptions();
    } else if (response.statusCode == 401) {
      showMessage("Unauthorized. Please login again.");
    } else {
      showMessage("Upload Failed  (${response.statusCode})");
    }
  }

  // ---------------- MESSAGE ----------------

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ---------------- DISPOSE ----------------

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();

    _categoryName.dispose();
    _typeController.dispose();
    _genderController.dispose();
    _colorController.dispose();
    _sizeController.dispose();
    _seasonController.dispose();
    _occasionController.dispose();

    super.dispose();
  }

  // ---------------- FIELD BUILDER ----------------

  Widget buildField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }

  Widget buildDropdownField({
    required String label,
    required IconData icon,
    required List<String> options,
    required String? value,
    required ValueChanged<String?> onChanged,
    required TextEditingController controller,
  }) {
    if (options.isEmpty) {
      if (_loadingOptions) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: DropdownButtonFormField<String>(
            value: null,
            items: const [
              DropdownMenuItem(value: "loading", child: Text("Loading...")),
            ],
            onChanged: null,
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon),
            ),
          ),
        );
      }
      return buildField(label, controller, icon);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        items: options
            .map(
              (opt) => DropdownMenuItem(
                value: opt,
                child: Text(opt),
              ),
            )
            .toList(),
        onChanged: (selected) {
          onChanged(selected);
          controller.text = selected ?? "";
        },
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
      ),
    );
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernUI.appBar(
        context: context,
        title: "Upload Image",
      ),
      body: ModernUI.pageWrapper(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // IMAGE CARD
              Container(
                width: double.infinity,
                height: 220,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.softBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.softBorder),
                  boxShadow: AppTheme.softShadows,
                ),
                child: _image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _image!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.image,
                            size: 60,
                            color: Colors.black38,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "No Image Selected",
                            style: TextStyle(color: Colors.black45),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 20),

              // SELECT BUTTON
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add_a_photo),
                  label: const Text("Select Image"),
                  onPressed: pickImage,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // FORM CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.softBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.softBorder),
                  boxShadow: AppTheme.softShadows,
                ),
                child: Column(
                  children: [
                    buildField("Image Name", _nameController, Icons.title),
                    buildField("Description", _descController, Icons.description),
                    const Divider(),
                    buildField("Category Name", _categoryName, Icons.category),
                    buildDropdownField(
                      label: "Type",
                      icon: Icons.style,
                      options: _typeOptions,
                      value: _selectedType,
                      controller: _typeController,
                      onChanged: (value) =>
                          setState(() => _selectedType = value),
                    ),
                    buildDropdownField(
                      label: "Gender",
                      icon: Icons.person,
                      options: _genderOptions,
                      value: _selectedGender,
                      controller: _genderController,
                      onChanged: (value) =>
                          setState(() => _selectedGender = value),
                    ),
                    buildDropdownField(
                      label: "Color",
                      icon: Icons.color_lens,
                      options: _colorOptions,
                      value: _selectedColor,
                      controller: _colorController,
                      onChanged: (value) =>
                          setState(() => _selectedColor = value),
                    ),
                    buildDropdownField(
                      label: "Size",
                      icon: Icons.straighten,
                      options: _sizeOptions,
                      value: _selectedSize,
                      controller: _sizeController,
                      onChanged: (value) =>
                          setState(() => _selectedSize = value),
                    ),
                    buildDropdownField(
                      label: "Season",
                      icon: Icons.cloud,
                      options: _seasonOptions,
                      value: _selectedSeason,
                      controller: _seasonController,
                      onChanged: (value) =>
                          setState(() => _selectedSeason = value),
                    ),
                    buildDropdownField(
                      label: "Occasion",
                      icon: Icons.event,
                      options: _occasionOptions,
                      value: _selectedOccasion,
                      controller: _occasionController,
                      onChanged: (value) =>
                          setState(() => _selectedOccasion = value),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // UPLOAD BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text(
                          "Upload Image",
                          style: TextStyle(fontSize: 16),
                        ),
                        onPressed: uploadImage,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
