import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_config.dart';
import '../services/api_service.dart';
import '../ui/app_theme.dart';
import 'upload_image_page.dart';

class OutfitBuilderPage extends StatefulWidget {
  const OutfitBuilderPage({super.key});

  @override
  State<OutfitBuilderPage> createState() => _OutfitBuilderPageState();
}

class _OutfitBuilderPageState extends State<OutfitBuilderPage> {
  bool _loading = true;
  bool _saving = false;
  String? _token;
  String? _userId;
  List<Map<String, dynamic>> _wardrobeItems = [];
  List<_SavedOutfit> _savedOutfits = [];

  String? _editingOutfitId;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _occasionController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final Map<String, Map<String, dynamic>> _selectedBySlot = {};
  static const List<String> _slots = ['Top', 'Bottom', 'Footwear', 'Accessory'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _occasionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _userId = prefs.getString('user_id');

    if (_token == null || _userId == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    if (mounted) {
      setState(() => _loading = true);
    }

    await Future.wait([_fetchWardrobeItems(), _fetchSavedOutfits()]);

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _fetchWardrobeItems() async {
    if (_token == null || _userId == null) return;

    final res = await ApiService.getImages(_token!, _userId!);
    if (res != null && res['status'] == true) {
      final data = res['data'];
      if (!mounted) return;
      setState(() {
        _wardrobeItems = _normalizeMapList(data);
      });
      return;
    }

    if (mounted) {
      _showMessage('Failed to load wardrobe items');
    }
  }

  Future<void> _fetchSavedOutfits() async {
    if (_token == null || _userId == null) return;

    final res = await ApiService.getSavedOutfits(_token!, _userId!);
    final payload = res is Map<String, dynamic> ? res : <String, dynamic>{};
    final status = payload['status'];
    final rawList = res is List
        ? res
        : payload['data'] ?? payload['outfits'] ?? payload['items'];
    final list = _normalizeMapList(rawList);

    if (status == false && mounted) {
      _showMessage('Could not load saved outfits');
    }

    if (!mounted) return;
    setState(() {
      _savedOutfits = list.map(_SavedOutfit.fromJson).toList();
    });
  }

  List<Map<String, dynamic>> _normalizeMapList(dynamic raw) {
    if (raw is! List) return [];
    return raw.whereType<Map>().map((entry) {
      return entry.map((key, value) => MapEntry(key.toString(), value));
    }).toList();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  String? _responseMessage(dynamic res) {
    if (res is Map) {
      final message = res['message']?.toString().trim();
      if (message != null && message.isNotEmpty) {
        return message;
      }

      final errors = res['errors'];
      if (errors is Map) {
        for (final value in errors.values) {
          if (value is List && value.isNotEmpty) {
            final first = value.first.toString().trim();
            if (first.isNotEmpty) return first;
          }

          final text = value?.toString().trim();
          if (text != null && text.isNotEmpty) return text;
        }
      }
    }

    return null;
  }

  String _slotForItem(Map<String, dynamic> item) {
    final category = _mapValue(item['category']);
    final combined = [
      category?['type'],
      category?['name'],
      item['type'],
      item['category_name'],
    ].whereType<Object>().map((e) => e.toString().toLowerCase()).join(' ');

    if (combined.contains('shoe') ||
        combined.contains('footwear') ||
        combined.contains('sandal') ||
        combined.contains('heel') ||
        combined.contains('boot') ||
        combined.contains('loafer') ||
        combined.contains('sneaker')) {
      return 'Footwear';
    }

    if (combined.contains('bottom') ||
        combined.contains('pant') ||
        combined.contains('jean') ||
        combined.contains('trouser') ||
        combined.contains('short') ||
        combined.contains('skirt')) {
      return 'Bottom';
    }

    if (combined.contains('access') ||
        combined.contains('jewel') ||
        combined.contains('bag') ||
        combined.contains('belt') ||
        combined.contains('watch')) {
      return 'Accessory';
    }

    return 'Top';
  }

  Map<String, dynamic>? _mapValue(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) {
      return raw.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  List<Map<String, dynamic>> _itemsForSlot(String slot) {
    return _wardrobeItems.where((item) => _slotForItem(item) == slot).toList();
  }

  void _toggleSelection(String slot, Map<String, dynamic> item) {
    final current = _selectedBySlot[slot];
    final isSame = current?['id'].toString() == item['id'].toString();

    setState(() {
      if (isSame) {
        _selectedBySlot.remove(slot);
      } else {
        _selectedBySlot[slot] = item;
      }
    });
  }

  void _clearBuilder() {
    setState(() {
      _editingOutfitId = null;
      _selectedBySlot.clear();
      _nameController.clear();
      _occasionController.clear();
      _notesController.clear();
    });
  }

  void _autoSuggest() {
    final suggestion = <String, Map<String, dynamic>>{};
    for (final slot in _slots) {
      final items = _itemsForSlot(slot);
      if (items.isNotEmpty) {
        suggestion[slot] = items.first;
      }
    }

    if (suggestion.isEmpty) {
      _showMessage('Add wardrobe items first');
      return;
    }

    setState(() {
      _selectedBySlot
        ..clear()
        ..addAll(suggestion);
      _nameController.text = _nameController.text.trim().isEmpty
          ? 'New Outfit'
          : _nameController.text;
    });
  }

  Future<void> _saveOutfit() async {
    if (_token == null || _userId == null) return;

    final selectedIds = _selectedBySlot.values
        .map((item) => item['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();

    if (_nameController.text.trim().isEmpty) {
      _showMessage('Enter outfit name');
      return;
    }

    if (selectedIds.isEmpty) {
      _showMessage('Select at least one wardrobe item');
      return;
    }

    setState(() => _saving = true);

    final name = _nameController.text.trim();
    final occasion = _occasionController.text.trim();
    final notes = _notesController.text.trim();

    final res = _editingOutfitId == null
        ? await ApiService.createOutfit(
            _token!,
            userId: _userId!,
            name: name,
            occasion: occasion,
            notes: notes,
            imageIds: selectedIds,
          )
        : await ApiService.updateOutfit(
            _token!,
            _editingOutfitId!,
            userId: _userId!,
            name: name,
            occasion: occasion,
            notes: notes,
            imageIds: selectedIds,
          );

    if (!mounted) return;
    setState(() => _saving = false);

    if (res != null && res['status'] == true) {
      _showMessage(
        _responseMessage(res) ??
            (_editingOutfitId == null
                ? 'Outfit saved successfully'
                : 'Outfit updated successfully'),
      );
      _clearBuilder();
      await _fetchSavedOutfits();
      return;
    }

    _showMessage(
      _responseMessage(res) ??
          (_editingOutfitId == null
              ? 'Failed to save outfit'
              : 'Failed to update outfit'),
    );
  }

  void _editOutfit(_SavedOutfit outfit) {
    final selected = <String, Map<String, dynamic>>{};

    for (final itemId in outfit.imageIds) {
      final matches = _wardrobeItems.where(
        (item) => item['id']?.toString() == itemId,
      );
      if (matches.isEmpty) continue;
      final item = matches.first;
      selected[_slotForItem(item)] = item;
    }

    setState(() {
      _editingOutfitId = outfit.id;
      _selectedBySlot
        ..clear()
        ..addAll(selected);
      _nameController.text = outfit.name;
      _occasionController.text = outfit.occasion ?? '';
      _notesController.text = outfit.notes ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasSelection = _selectedBySlot.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Outfit Builder'),
        actions: [
          IconButton(onPressed: _loadData, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: ListView(
                children: [
                  _buildCanvasCard(context),
                  const SizedBox(height: 16),
                  _buildFormCard(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _autoSuggest,
                          child: const Text('Auto-suggest'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saving ? null : _saveOutfit,
                          child: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _editingOutfitId == null
                                      ? 'Save Outfit'
                                      : 'Update Outfit',
                                ),
                        ),
                      ),
                    ],
                  ),
                  if (hasSelection || _editingOutfitId != null) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _clearBuilder,
                      child: const Text('Clear builder'),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    'Choose Pieces',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  ..._slots.map(
                    (slot) => _SlotSection(
                      title: slot,
                      items: _itemsForSlot(slot),
                      selectedId: _selectedBySlot[slot]?['id']?.toString(),
                      onSelect: (item) => _toggleSelection(slot, item),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Saved Outfits',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '${_savedOutfits.length}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_savedOutfits.isEmpty)
                    _EmptyStateCard(
                      title: 'No saved outfits yet',
                      subtitle:
                          'Build an outfit from your wardrobe items and save it to the database.',
                    )
                  else
                    ..._savedOutfits.map(
                      (outfit) => _SavedOutfitTile(
                        outfit: outfit,
                        onEdit: () => _editOutfit(outfit),
                      ),
                    ),
                  if (_wardrobeItems.isEmpty) ...[
                    const SizedBox(height: 20),
                    _EmptyStateCard(
                      title: 'No wardrobe items found',
                      subtitle:
                          'Upload items first so the outfit builder can use them.',
                      actionLabel: 'Add item',
                      onAction: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const UploadImagePage(),
                          ),
                        );
                        if (!context.mounted) return;
                        await _loadData();
                      },
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildCanvasCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cloud,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _editingOutfitId == null ? 'Current Draft' : 'Editing Saved Outfit',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (_selectedBySlot.isEmpty)
            const Text('Select pieces below to build your outfit.')
          else
            ..._slots.map((slot) {
              final item = _selectedBySlot[slot];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white,
                      child: Icon(_iconForSlot(slot), color: AppTheme.plum),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slot,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            item == null
                                ? 'Not selected'
                                : (item['image_name'] ?? 'Item').toString(),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadows,
      ),
      child: Column(
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Outfit Name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _occasionController,
            decoration: const InputDecoration(labelText: 'Occasion'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
        ],
      ),
    );
  }

  IconData _iconForSlot(String slot) {
    switch (slot) {
      case 'Bottom':
        return Icons.checkroom;
      case 'Footwear':
        return Icons.hiking;
      case 'Accessory':
        return Icons.watch;
      default:
        return Icons.style;
    }
  }
}

class _SlotSection extends StatelessWidget {
  const _SlotSection({
    required this.title,
    required this.items,
    required this.selectedId,
    required this.onSelect,
  });

  final String title;
  final List<Map<String, dynamic>> items;
  final String? selectedId;
  final ValueChanged<Map<String, dynamic>> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppTheme.softShadows,
              ),
              child: Text('No $title items available'),
            )
          else
            SizedBox(
              height: 136,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final category = item['category'] is Map
                      ? item['category'] as Map
                      : const {};
                  final imageUrl = ApiConfig.imageUrl(item['image_url']);
                  final isSelected = selectedId == item['id']?.toString();

                  return InkWell(
                    onTap: () => onSelect(item),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: 148,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? AppTheme.plum : AppTheme.border,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: AppTheme.softShadows,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: double.infinity,
                                color: AppTheme.cloud,
                                child: imageUrl == null
                                    ? const Icon(
                                        Icons.image,
                                        color: AppTheme.plum,
                                      )
                                    : Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return const Icon(
                                                Icons.broken_image,
                                                color: AppTheme.plum,
                                              );
                                            },
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            (item['image_name'] ?? 'Item').toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (category['colour'] ?? category['name'] ?? '-')
                                .toString(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
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
    );
  }
}

class _SavedOutfitTile extends StatelessWidget {
  const _SavedOutfitTile({required this.outfit, required this.onEdit});

  final _SavedOutfit outfit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadows,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: AppTheme.cloud,
            child: const Icon(Icons.layers, color: AppTheme.plum),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  outfit.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if ((outfit.occasion ?? '').trim().isNotEmpty)
                      outfit.occasion!.trim(),
                    '${outfit.imageIds.length} item(s)',
                  ].join(' - '),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          TextButton(onPressed: onEdit, child: const Text('Edit')),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 10),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _SavedOutfit {
  const _SavedOutfit({
    required this.id,
    required this.name,
    required this.imageIds,
    this.occasion,
    this.notes,
  });

  final String id;
  final String name;
  final List<String> imageIds;
  final String? occasion;
  final String? notes;

  factory _SavedOutfit.fromJson(Map<String, dynamic> json) {
    final ids = <String>{};

    void collectId(dynamic value) {
      if (value == null) return;
      final text = value.toString().trim();
      if (text.isNotEmpty) ids.add(text);
    }

    void collectList(dynamic raw) {
      if (raw is! List) return;
      for (final entry in raw) {
        if (entry is Map) {
          final map = entry.map(
            (key, value) => MapEntry(key.toString(), value),
          );
          collectId(
            map['image_id'] ??
                map['item_id'] ??
                map['id'] ??
                map['user_image_id'],
          );

          final nestedImage = map['image'];
          if (nestedImage is Map) {
            collectId(nestedImage['id']);
          }
        } else {
          collectId(entry);
        }
      }
    }

    collectList(json['image_ids']);
    collectList(json['images']);
    collectList(json['items']);
    collectList(json['pieces']);
    collectList(json['outfit_items']);

    return _SavedOutfit(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? json['title'] ?? 'Saved Outfit').toString(),
      occasion: json['occasion']?.toString(),
      notes: json['notes']?.toString(),
      imageIds: ids.toList(),
    );
  }
}
