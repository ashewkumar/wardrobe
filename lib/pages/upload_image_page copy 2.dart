import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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
  bool _autoFillingDetails = false;
  bool _imagePreparedWithLens = false;

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

  List<String> _categoryOptions = [];
  List<String> _typeOptions = [];
  List<String> _genderOptions = [];
  List<String> _colorOptions = [];
  List<String> _sizeOptions = [];
  List<String> _seasonOptions = [];
  List<String> _occasionOptions = [];

  String? _selectedCategory;
  String? _selectedType;
  String? _selectedGender;
  String? _selectedColor;
  String? _selectedSize;
  String? _selectedSeason;
  String? _selectedOccasion;

  static const Map<String, List<String>> _typeKeywordMap = {
    'T-Shirt': ['tshirt', 'tee', 't-shirt'],
    'Shirt': ['shirt', 'buttondown', 'button-up', 'buttonup'],
    'Top': ['top', 'blouse', 'camisole', 'tank'],
    'Sweater': ['sweater', 'jumper', 'cardigan'],
    'Hoodie': ['hoodie', 'sweatshirt'],
    'Jacket': ['jacket', 'blazer', 'coat'],
    'Dress': ['dress', 'gown'],
    'Jeans': ['jeans', 'denim'],
    'Pants': ['pants', 'trousers', 'slacks', 'joggers', 'leggings'],
    'Shorts': ['shorts'],
    'Skirt': ['skirt'],
    'Saree': ['saree', 'sari'],
    'Kurta': ['kurta', 'kurti'],
    'Shoes': ['shoes', 'sneakers', 'trainers', 'boots', 'heels', 'sandals'],
    'Bag': ['bag', 'handbag', 'purse', 'tote', 'backpack'],
  };

  static const Map<String, List<String>> _genderKeywordMap = {
    'Women': ['women', 'woman', 'female', 'girl', 'ladies', 'womens'],
    'Men': ['men', 'man', 'male', 'boy', 'mens'],
    'Unisex': ['unisex'],
  };

  static const Map<String, List<String>> _seasonKeywordMap = {
    'Summer': ['summer'],
    'Winter': ['winter'],
    'Spring': ['spring'],
    'Autumn': ['autumn', 'fall'],
    'Rainy': ['rain', 'rainy', 'monsoon'],
  };

  static const Map<String, List<String>> _occasionKeywordMap = {
    'Casual': ['casual', 'daily', 'everyday'],
    'Work': ['office', 'formal', 'work'],
    'Party': ['party', 'festive', 'celebration'],
    'Wedding': ['wedding', 'bridal'],
    'Sports': ['sport', 'sports', 'gym', 'active', 'athletic'],
    'Travel': ['travel', 'trip', 'vacation', 'holiday'],
  };

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

      final categoryMap = <String, String>{};
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
          addOption(categoryMap, item["category_name"]);
          if (category is! Map) continue;
          addOption(categoryMap, category["name"]);
          addOption(categoryMap, category["category_name"]);
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
        values.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        return values;
      }

      if (mounted) {
        setState(() {
          _categoryOptions = sorted(categoryMap);
          _typeOptions = sorted(typeMap);
          _genderOptions = sorted(genderMap);
          _colorOptions = sorted(colorMap);
          _sizeOptions = sorted(sizeMap);
          _seasonOptions = sorted(seasonMap);
          _occasionOptions = sorted(occasionMap);
          _syncSelectionsWithControllers();
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
                  await _pickFromSource(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.center_focus_strong),
                title: const Text("Google Lens"),
                subtitle: const Text("Capture and extract a cropped item"),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickFromSource(ImageSource.camera, useLensCrop: true);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Gallery"),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickFromSource(ImageSource.gallery);
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

  Future<void> _pickFromSource(
    ImageSource source, {
    bool useLensCrop = false,
  }) async {
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1024,
      maxHeight: 1024,
    );

    if (picked == null || !mounted) return;

    File selectedFile = File(picked.path);

    if (useLensCrop) {
      final croppedFile = await Navigator.of(context).push<File>(
        MaterialPageRoute(
          builder: (_) => _LensCropPage(imageFile: selectedFile),
        ),
      );

      if (croppedFile == null || !mounted) return;
      selectedFile = croppedFile;
    }

    setState(() {
      _image = selectedFile;
      _imagePreparedWithLens = useLensCrop;
    });

    await _autoFillDetailsFromImage(selectedFile);
  }

  Future<void> _autoFillDetailsFromImage(File imageFile) async {
    if (_autoFillingDetails) return;

    final previousValues = [
      _nameController.text,
      _descController.text,
      _categoryName.text,
      _typeController.text,
      _genderController.text,
      _colorController.text,
      _sizeController.text,
      _seasonController.text,
      _occasionController.text,
    ].where((value) => value.trim().isNotEmpty).length;

    if (mounted) {
      setState(() => _autoFillingDetails = true);
    }

    try {
      final suggestion = await _buildImageDetailSuggestion(imageFile);
      if (!mounted) return;

      setState(() {
        _fillIfEmpty(_nameController, suggestion.name);
        _fillIfEmpty(_descController, suggestion.description);
        _applySuggestedDropdownValue(
          controller: _categoryName,
          value: suggestion.categoryName,
          options: _categoryOptions,
          onSelected: (value) => _selectedCategory = value,
        );

        _applySuggestedDropdownValue(
          controller: _typeController,
          value: suggestion.type,
          options: _typeOptions,
          onSelected: (value) => _selectedType = value,
        );
        _applySuggestedDropdownValue(
          controller: _genderController,
          value: suggestion.gender,
          options: _genderOptions,
          onSelected: (value) => _selectedGender = value,
        );
        _applySuggestedDropdownValue(
          controller: _colorController,
          value: suggestion.color,
          options: _colorOptions,
          onSelected: (value) => _selectedColor = value,
        );
        _applySuggestedDropdownValue(
          controller: _sizeController,
          value: suggestion.size,
          options: _sizeOptions,
          onSelected: (value) => _selectedSize = value,
        );
        _applySuggestedDropdownValue(
          controller: _seasonController,
          value: suggestion.season,
          options: _seasonOptions,
          onSelected: (value) => _selectedSeason = value,
        );
        _applySuggestedDropdownValue(
          controller: _occasionController,
          value: suggestion.occasion,
          options: _occasionOptions,
          onSelected: (value) => _selectedOccasion = value,
        );
      });

      final filledCount = [
        _nameController.text,
        _descController.text,
        _categoryName.text,
        _typeController.text,
        _genderController.text,
        _colorController.text,
        _sizeController.text,
        _seasonController.text,
        _occasionController.text,
      ].where((value) => value.trim().isNotEmpty).length;

      if (filledCount > previousValues) {
        showMessage("Image details auto-filled where possible.");
      }
    } catch (_) {
      if (mounted) {
        showMessage("Could not auto-fill image details.");
      }
    } finally {
      if (mounted) {
        setState(() => _autoFillingDetails = false);
      }
    }
  }

  Future<_ImageDetailSuggestion> _buildImageDetailSuggestion(
    File imageFile,
  ) async {
    return _buildLocalImageDetailSuggestion(imageFile);
  }

  Future<_ImageDetailSuggestion> _buildLocalImageDetailSuggestion(
    File imageFile,
  ) async {
    final filename = imageFile.path.replaceAll('\\', '/').split('/').last;
    final baseName = filename.replaceFirst(RegExp(r'\.[^.]+$'), '');
    final tokens = _tokenize(baseName);

    final type = _inferFromKeywords(tokens, _typeKeywordMap);
    final gender =
        _inferFromKeywords(tokens, _genderKeywordMap) ?? _genderFromType(type);
    final season = _inferFromKeywords(tokens, _seasonKeywordMap);
    final occasion = _inferFromKeywords(tokens, _occasionKeywordMap);
    final size = _inferSize(tokens);
    final color = await _estimateColorName(imageFile);
    final categoryName = _categoryNameFromType(type);
    final prettyName = _humanizeName(
      baseName,
      fallbackType: type,
      color: color,
    );
    final description = _buildDescription(
      type: type,
      color: color,
      gender: gender,
      season: season,
      occasion: occasion,
    );

    return _ImageDetailSuggestion(
      name: prettyName,
      description: description,
      categoryName: categoryName,
      type: type,
      gender: gender,
      color: color,
      size: size,
      season: season,
      occasion: occasion,
    );
  }

  void _fillIfEmpty(TextEditingController controller, String? value) {
    if (controller.text.trim().isNotEmpty) return;
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return;
    controller.text = trimmed;
  }

  void _applySuggestedDropdownValue({
    required TextEditingController controller,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onSelected,
  }) {
    if (controller.text.trim().isNotEmpty) return;
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return;

    final matched = _findBestOption(trimmed, options);
    controller.text = matched ?? trimmed;
    onSelected(matched);
  }

  void _syncSelectionsWithControllers() {
    _selectedCategory = _findBestOption(_categoryName.text, _categoryOptions);
    _selectedType = _findBestOption(_typeController.text, _typeOptions);
    _selectedGender = _findBestOption(_genderController.text, _genderOptions);
    _selectedColor = _findBestOption(_colorController.text, _colorOptions);
    _selectedSize = _findBestOption(_sizeController.text, _sizeOptions);
    _selectedSeason = _findBestOption(_seasonController.text, _seasonOptions);
    _selectedOccasion = _findBestOption(
      _occasionController.text,
      _occasionOptions,
    );
  }

  List<String> _tokenize(String raw) {
    return raw
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((part) => part.isNotEmpty)
        .toList();
  }

  String? _inferFromKeywords(
    List<String> tokens,
    Map<String, List<String>> mapping,
  ) {
    for (final entry in mapping.entries) {
      if (entry.value.any(tokens.contains)) {
        return entry.key;
      }
    }
    return null;
  }

  String? _inferSize(List<String> tokens) {
    const directSizes = {
      'xxs': 'XXS',
      'xs': 'XS',
      's': 'S',
      'm': 'M',
      'l': 'L',
      'xl': 'XL',
      'xxl': 'XXL',
      'xxxl': 'XXXL',
    };

    for (final token in tokens) {
      final direct = directSizes[token];
      if (direct != null) return direct;
      if (RegExp(r'^\d{2,3}$').hasMatch(token)) return token;
    }
    return null;
  }

  String? _genderFromType(String? type) {
    switch (type) {
      case 'Dress':
      case 'Skirt':
      case 'Saree':
        return 'Women';
      default:
        return null;
    }
  }

  String? _categoryNameFromType(String? type) {
    switch (type) {
      case 'T-Shirt':
      case 'Shirt':
      case 'Top':
      case 'Sweater':
      case 'Hoodie':
      case 'Jacket':
        return 'Topwear';
      case 'Dress':
      case 'Saree':
      case 'Kurta':
        return 'Ethnic';
      case 'Jeans':
      case 'Pants':
      case 'Shorts':
      case 'Skirt':
        return 'Bottomwear';
      case 'Shoes':
        return 'Footwear';
      case 'Bag':
        return 'Accessories';
      default:
        return 'Clothing';
    }
  }

  String _humanizeName(String baseName, {String? fallbackType, String? color}) {
    final cleaned = baseName
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (cleaned.isNotEmpty) {
      return cleaned
          .split(' ')
          .map((word) {
            if (word.isEmpty) return word;
            if (word.length <= 3 && word == word.toUpperCase()) return word;
            return '${word[0].toUpperCase()}${word.substring(1)}';
          })
          .join(' ');
    }

    final parts = [color, fallbackType].whereType<String>().toList();
    if (parts.isNotEmpty) {
      return parts.join(' ');
    }

    return 'Wardrobe Item';
  }

  String? _buildDescription({
    String? type,
    String? color,
    String? gender,
    String? season,
    String? occasion,
  }) {
    final parts = <String>[];
    if (color != null && color.isNotEmpty) parts.add(color.toLowerCase());
    if (gender != null && gender.isNotEmpty && gender != 'Unisex') {
      parts.add(gender.toLowerCase());
    }
    if (type != null && type.isNotEmpty) parts.add(type.toLowerCase());

    if (parts.isEmpty) return null;

    final buffer = StringBuffer('Auto-detected ${parts.join(' ')}');
    final extras = [
      season,
      occasion,
    ].whereType<String>().where((value) => value.isNotEmpty).toList();
    if (extras.isNotEmpty) {
      buffer.write(' suitable for ${extras.join(' and ').toLowerCase()}');
    }
    buffer.write('.');
    return buffer.toString();
  }

  Future<String?> _estimateColorName(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return null;

      final resized = img.copyResize(decoded, width: 48);
      num totalWeight = 0;
      num redSum = 0;
      num greenSum = 0;
      num blueSum = 0;

      for (final pixel in resized) {
        final alpha = pixel.a.toInt();
        if (alpha < 32) continue;
        final brightness = (pixel.r + pixel.g + pixel.b) / 3;
        if (brightness > 248) continue;

        totalWeight += 1;
        redSum += pixel.r;
        greenSum += pixel.g;
        blueSum += pixel.b;
      }

      if (totalWeight == 0) return null;

      final red = (redSum / totalWeight).round();
      final green = (greenSum / totalWeight).round();
      final blue = (blueSum / totalWeight).round();

      return _closestColorName(red, green, blue);
    } catch (_) {
      return null;
    }
  }

  String _closestColorName(int red, int green, int blue) {
    const palette = <String, List<int>>{
      'Black': [25, 25, 25],
      'White': [245, 245, 245],
      'Grey': [140, 140, 140],
      'Navy': [32, 52, 101],
      'Blue': [52, 120, 246],
      'Green': [64, 148, 84],
      'Olive': [114, 124, 70],
      'Yellow': [232, 196, 63],
      'Orange': [223, 128, 47],
      'Red': [196, 63, 63],
      'Pink': [225, 125, 168],
      'Purple': [126, 77, 190],
      'Brown': [122, 82, 52],
      'Beige': [214, 196, 158],
    };

    String bestName = 'Grey';
    double bestDistance = double.infinity;

    for (final entry in palette.entries) {
      final rgb = entry.value;
      final dr = red - rgb[0];
      final dg = green - rgb[1];
      final db = blue - rgb[2];
      final distance = math.sqrt(dr * dr + dg * dg + db * db);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestName = entry.key;
      }
    }

    return bestName;
  }

  String? _findBestOption(String value, List<String> options) {
    if (options.isEmpty) return null;

    final normalizedValue = _normalize(value);
    for (final option in options) {
      if (_normalize(option) == normalizedValue) return option;
    }

    for (final option in options) {
      final normalizedOption = _normalize(option);
      if (normalizedOption.contains(normalizedValue) ||
          normalizedValue.contains(normalizedOption)) {
        return option;
      }
    }

    return null;
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  Future<void> _detectDetailsForSelectedImage() async {
    final currentImage = _image;
    if (currentImage == null) {
      showMessage("Select image first");
      return;
    }

    await _autoFillDetailsFromImage(currentImage);
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
    final filePath = _image!.path;
    final normalizedPath = filePath.replaceAll('\\', '/');
    final fileName = normalizedPath.split('/').last;
    final lowerName = fileName.toLowerCase();
    final contentType = lowerName.endsWith('.png')
        ? MediaType('image', 'png')
        : lowerName.endsWith('.webp')
        ? MediaType('image', 'webp')
        : MediaType('image', 'jpeg');

    final multipartFile = await http.MultipartFile.fromPath(
      'image',
      filePath,
      filename: fileName,
      contentType: contentType,
    );

    request.files.add(multipartFile);

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    setState(() => _loading = false);

    print("STATUS: ${response.statusCode}");
    print("BODY: ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      showMessage("Upload successful");

      setState(() {
        _image = null;
        _imagePreparedWithLens = false;

        _nameController.clear();
        _descController.clear();

        _categoryName.clear();
        _typeController.clear();
        _genderController.clear();
        _colorController.clear();
        _sizeController.clear();
        _seasonController.clear();
        _occasionController.clear();

        _selectedCategory = null;
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
      showMessage("Upload failed (${response.statusCode})");
    }
  }

  // ---------------- MESSAGE ----------------

  void showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
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
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
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
            initialValue: null,
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
        initialValue: value,
        items: options
            .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
            .toList(),
        onChanged: (selected) {
          onChanged(selected);
          controller.text = selected ?? "";
        },
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      ),
    );
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernUI.appBar(context: context, title: "Upload Image"),
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
                        child: Image.file(_image!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.image, size: 60, color: Colors.black38),
                          SizedBox(height: 10),
                          Text(
                            "No Image Selected",
                            style: TextStyle(color: Colors.black45),
                          ),
                        ],
                      ),
              ),

              if (_imagePreparedWithLens) ...[
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.plum.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppTheme.plum.withValues(alpha: 0.16),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.center_focus_strong,
                          size: 16,
                          color: AppTheme.plum,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Cropped with Google Lens flow",
                          style: TextStyle(
                            color: AppTheme.plum,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),

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

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: (_image == null || _autoFillingDetails || _loading)
                      ? null
                      : _detectDetailsForSelectedImage,
                  icon: _autoFillingDetails
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: const Text(
                    "Detect category, type, color, gender and description",
                  ),
                ),
              ),

              const SizedBox(height: 20),

              if (_autoFillingDetails)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Analyzing image and auto-filling details...",
                        ),
                      ),
                    ],
                  ),
                ),

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
                    buildField(
                      "Description",
                      _descController,
                      Icons.description,
                    ),
                    const Divider(),
                    buildDropdownField(
                      label: "Category Name",
                      icon: Icons.category,
                      options: _categoryOptions,
                      value: _selectedCategory,
                      controller: _categoryName,
                      onChanged: (value) =>
                          setState(() => _selectedCategory = value),
                    ),
                    buildDropdownField(
                      label: "Type",
                      icon: Icons.style,
                      options: _typeOptions,
                      value: _selectedType,
                      controller: _typeController,
                      onChanged: (value) => setState(() {
                        _selectedType = value;
                        if (_categoryName.text.trim().isEmpty &&
                            value != null) {
                          final inferredCategory = _categoryNameFromType(value);
                          final matchedCategory = inferredCategory == null
                              ? null
                              : _findBestOption(
                                  inferredCategory,
                                  _categoryOptions,
                                );
                          _categoryName.text =
                              matchedCategory ?? inferredCategory ?? "";
                          _selectedCategory = matchedCategory;
                        }
                      }),
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

class _ImageDetailSuggestion {
  const _ImageDetailSuggestion({
    this.name,
    this.description,
    this.categoryName,
    this.type,
    this.gender,
    this.color,
    this.size,
    this.season,
    this.occasion,
  });

  final String? name;
  final String? description;
  final String? categoryName;
  final String? type;
  final String? gender;
  final String? color;
  final String? size;
  final String? season;
  final String? occasion;
}

class _LensCropPage extends StatefulWidget {
  const _LensCropPage({required this.imageFile});

  final File imageFile;

  @override
  State<_LensCropPage> createState() => _LensCropPageState();
}

class _LensCropPageState extends State<_LensCropPage> {
  final TransformationController _transformationController =
      TransformationController();

  img.Image? _decodedImage;
  bool _processing = true;
  bool _saving = false;
  String? _error;
  double? _viewportSize;
  Size? _displayImageSize;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final bytes = await widget.imageFile.readAsBytes();
      final decoded = img.decodeImage(bytes);

      if (decoded == null) {
        throw Exception("decode failed");
      }

      if (!mounted) return;

      setState(() {
        _decodedImage = decoded;
        _processing = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _processing = false;
        _error = "Could not prepare the captured image.";
      });
    }
  }

  void _initializeViewport(double viewportSize) {
    if (_decodedImage == null) return;
    if (_viewportSize == viewportSize && _displayImageSize != null) return;

    final imageWidth = _decodedImage!.width.toDouble();
    final imageHeight = _decodedImage!.height.toDouble();
    final baseScale = math.max(
      viewportSize / imageWidth,
      viewportSize / imageHeight,
    );

    final displaySize = Size(imageWidth * baseScale, imageHeight * baseScale);

    _viewportSize = viewportSize;
    _displayImageSize = displaySize;
    _transformationController.value = Matrix4.identity()
      ..translateByDouble(
        (viewportSize - displaySize.width) / 2,
        (viewportSize - displaySize.height) / 2,
        0,
        1,
      );
  }

  Future<void> _saveCrop() async {
    if (_decodedImage == null ||
        _viewportSize == null ||
        _displayImageSize == null) {
      return;
    }

    setState(() => _saving = true);

    try {
      final matrix = _transformationController.value.storage;
      final scale = _transformationController.value.getMaxScaleOnAxis();
      final tx = matrix[12];
      final ty = matrix[13];
      final viewportSize = _viewportSize!;
      final displaySize = _displayImageSize!;

      final pixelPerDisplayX = _decodedImage!.width / displaySize.width;
      final pixelPerDisplayY = _decodedImage!.height / displaySize.height;
      final effectiveScaleX = pixelPerDisplayX / scale;
      final effectiveScaleY = pixelPerDisplayY / scale;

      final cropLeft = ((0 - tx) * effectiveScaleX).clamp(
        0,
        math.max(0, _decodedImage!.width - 1).toDouble(),
      );
      final cropTop = ((0 - ty) * effectiveScaleY).clamp(
        0,
        math.max(0, _decodedImage!.height - 1).toDouble(),
      );
      final cropWidth = (viewportSize * effectiveScaleX).clamp(
        1,
        (_decodedImage!.width - cropLeft).toDouble(),
      );
      final cropHeight = (viewportSize * effectiveScaleY).clamp(
        1,
        (_decodedImage!.height - cropTop).toDouble(),
      );

      final cropped = img.copyCrop(
        _decodedImage!,
        x: cropLeft.round(),
        y: cropTop.round(),
        width: cropWidth.round(),
        height: cropHeight.round(),
      );

      final outputFile = File(
        '${Directory.systemTemp.path}/lens_crop_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await outputFile.writeAsBytes(img.encodeJpg(cropped, quality: 92));

      if (!mounted) return;
      Navigator.of(context).pop(outputFile);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not extract the cropped image.")),
      );
      setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _decodedImage;

    return Scaffold(
      appBar: ModernUI.appBar(context: context, title: "Google Lens Crop"),
      body: ModernUI.pageWrapper(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _processing
              ? const Center(child: CircularProgressIndicator())
              : _error != null || image == null
              ? Center(
                  child: Text(
                    _error ?? "Could not open image.",
                    textAlign: TextAlign.center,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Move and zoom the clothing item inside the frame. The extracted crop is what will be uploaded to the wardrobe database.",
                      style: TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final viewportSize = math.min(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          );
                          _initializeViewport(viewportSize);
                          final displaySize = _displayImageSize!;

                          return Center(
                            child: Container(
                              width: viewportSize,
                              height: viewportSize,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    InteractiveViewer(
                                      transformationController:
                                          _transformationController,
                                      minScale: 1,
                                      maxScale: 5,
                                      boundaryMargin: const EdgeInsets.all(120),
                                      child: SizedBox(
                                        width: displaySize.width,
                                        height: displaySize.height,
                                        child: Image.file(
                                          widget.imageFile,
                                          fit: BoxFit.fill,
                                        ),
                                      ),
                                    ),
                                    IgnorePointer(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 3,
                                          ),
                                        ),
                                      ),
                                    ),
                                    IgnorePointer(
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: Container(
                                          margin: const EdgeInsets.all(14),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.6,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: const Text(
                                            "Pinch to zoom and drag to frame the item",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _saving ? null : _saveCrop,
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.content_cut),
                        label: Text(
                          _saving ? "Extracting..." : "Use Cropped Image",
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
