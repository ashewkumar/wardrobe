import 'package:flutter/material.dart';
import '../ui/app_theme.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Wardrobe Analytics")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _InsightCard(
            title: "Wear count",
            value: "412 wears",
            subtitle: "Last 30 days",
            icon: Icons.loop,
          ),
          _InsightCard(
            title: "Most worn",
            value: "Ivory linen shirt",
            subtitle: "22 wears",
            icon: Icons.star,
          ),
          _InsightCard(
            title: "Lowest cost per wear",
            value: "Tan loafers",
            subtitle: "₹165 / wear",
            icon: Icons.savings,
          ),
          const SizedBox(height: 12),
          Text("Wardrobe Composition",
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _CompositionRow(label: "Tops", value: "48%"),
          _CompositionRow(label: "Bottoms", value: "22%"),
          _CompositionRow(label: "Footwear", value: "18%"),
          _CompositionRow(label: "Accessories", value: "12%"),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadows,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.cloud,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.plum),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.titleLarge),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompositionRow extends StatelessWidget {
  const _CompositionRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadows,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
