import 'package:flutter/material.dart';
import '../models/wardrobe_item.dart';
import '../ui/app_theme.dart';

class ItemDetailsPage extends StatelessWidget {
  const ItemDetailsPage({super.key, required this.item});

  final WardrobeItem item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Item Details")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: AppTheme.cloud,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.border),
            ),
            child: Icon(item.icon, color: AppTheme.plum, size: 80),
          ),
          const SizedBox(height: 20),
          Text(item.name, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text("${item.category} · ${item.color} · ${item.brand}",
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          _InfoRow(label: "Wear count", value: "18"),
          _InfoRow(label: "Last worn", value: "Mar 29, 2026"),
          _InfoRow(label: "Cost per wear", value: "₹${(item.price / 18).round()}"),
          const SizedBox(height: 20),
          Text("Collections", style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: const [
              Chip(label: Text("Workwear")),
              Chip(label: Text("Monochrome")),
              Chip(label: Text("Travel capsule")),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  child: const Text("Edit Item"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text("Add to Outfit"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

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
