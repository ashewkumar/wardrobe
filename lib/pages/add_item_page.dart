import 'package:flutter/material.dart';
import '../ui/app_theme.dart';

class AddItemPage extends StatefulWidget {
  const AddItemPage({super.key});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  bool _draft = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Clothing Item")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            height: 190,
            decoration: BoxDecoration(
              color: AppTheme.cloud,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.photo_camera, size: 40, color: AppTheme.plum),
                const SizedBox(height: 12),
                Text(
                  "Capture or upload item",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  children: [
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text("Camera"),
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text("Gallery"),
                    ),
                    OutlinedButton(
                      onPressed: () {},
                      child: const Text("Bulk import"),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text("Item Details", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(labelText: "Item name"),
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(labelText: "Brand"),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            items: const [
              DropdownMenuItem(value: "Top", child: Text("Top")),
              DropdownMenuItem(value: "Bottom", child: Text("Bottom")),
              DropdownMenuItem(value: "Footwear", child: Text("Footwear")),
              DropdownMenuItem(value: "Accessory", child: Text("Accessory")),
            ],
            onChanged: (_) {},
            decoration: const InputDecoration(labelText: "Category"),
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(labelText: "Color"),
          ),
          const SizedBox(height: 12),
          TextFormField(
            decoration: const InputDecoration(labelText: "Price (optional)"),
          ),
          const SizedBox(height: 12),
          TextFormField(
            maxLines: 3,
            decoration: const InputDecoration(labelText: "Notes"),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            value: _draft,
            onChanged: (value) => setState(() => _draft = value),
            title: const Text("Save as draft before confirmation"),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text("AI Auto-tag"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text("Save Item"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
