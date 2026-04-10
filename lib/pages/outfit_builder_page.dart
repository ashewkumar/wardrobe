import 'package:flutter/material.dart';
import '../ui/app_theme.dart';

class OutfitBuilderPage extends StatelessWidget {
  const OutfitBuilderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Outfit Builder")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.cloud,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.layers, size: 56, color: AppTheme.plum),
                  const SizedBox(height: 10),
                  Text(
                    "Drag & drop canvas",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Layer tops, bottoms, footwear, and accessories",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  Text("Suggested Pieces",
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  _SuggestionTile(
                    title: "Ivory linen shirt",
                    subtitle: "Top · Cool cotton",
                    icon: Icons.checkroom,
                  ),
                  _SuggestionTile(
                    title: "Navy tailored pants",
                    subtitle: "Bottom · Structured fit",
                    icon: Icons.chair,
                  ),
                  _SuggestionTile(
                    title: "Tan loafers",
                    subtitle: "Footwear · Leather",
                    icon: Icons.hiking,
                  ),
                  _SuggestionTile(
                    title: "Gold hoops",
                    subtitle: "Accessory · Warm metal",
                    icon: Icons.wb_iridescent,
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text("Auto-suggest"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text("Save Outfit"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

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
            child: Icon(icon, color: AppTheme.plum),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}
