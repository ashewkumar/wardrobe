import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/analytics_service.dart';
import '../services/api_service.dart';
import '../services/app_time_service.dart';
import '../services/calendar_service.dart';
import '../services/stability_service.dart';
import '../services/weather_service.dart';
import '../ui/app_theme.dart';
import 'ai_suggestion_page.dart';
import 'analytics_page.dart';
import 'outfit_builder_page.dart';
import 'travel_page.dart';

class HomeDashboardPage extends StatefulWidget {
  const HomeDashboardPage({super.key});

  @override
  State<HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<HomeDashboardPage> {
  String? token;
  String? userId;

  String _greetingName = 'Mira';
  _WeatherData _weather = const _WeatherData(
    city: 'Delhi',
    temperatureC: 31,
    condition: 'Sunny',
    tip: 'Light layers recommended',
  );
  _OutfitData _todayOutfit = const _OutfitData(
    title: "Today's planned outfit",
    description: 'Plan your look for the day',
  );
  List<_StatItem> _quickStats = const [
    _StatItem(label: 'Total items', value: '0', icon: Icons.inventory_2),
    _StatItem(
      label: 'Upcoming events',
      value: '0',
      icon: Icons.event_available,
    ),
  ];

  late final List<_ActionItem> _boosters = [
    _ActionItem(
      title: 'Outfit Builder',
      subtitle: 'Drag and layer',
      icon: Icons.layers,
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const OutfitBuilderPage())),
    ),
    _ActionItem(
      title: 'Analytics',
      subtitle: 'Wear insights',
      icon: Icons.query_stats,
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const AnalyticsPage())),
    ),
    _ActionItem(
      title: 'Travel Planner',
      subtitle: 'Packing list',
      icon: Icons.card_travel,
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const TravelPage())),
    ),
    _ActionItem(
      title: 'Style Playbook',
      subtitle: 'Tips and inspo',
      icon: Icons.auto_awesome_mosaic,
      onTap: () {},
    ),
  ];

  @override
  void initState() {
    super.initState();
    AppAnalyticsService.instance.trackScreen('home_dashboard_page');
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    userId = prefs.getString('user_id');

    if (token == null || userId == null) {
      return;
    }

    await AppStabilityService.instance.monitor(
      'home_dashboard_load',
      () => Future.wait([
        _loadProfile(),
        _loadStats(),
        _loadWeather(),
        _loadNextPlan(),
      ]),
    );
  }

  Future<void> _loadProfile() async {
    if (token == null) return;
    final res = await ApiService.getProfile(token!);
    if (res != null && res['status'] == true) {
      final data = res['data'];
      if (data is Map && data['name'] != null) {
        setState(() {
          _greetingName = data['name'].toString();
        });
      }
    }
  }

  Future<void> _loadStats() async {
    if (token == null || userId == null) return;

    int totalItems = 0;
    final imagesRes = await ApiService.getImages(token!, userId!);
    if (imagesRes != null && imagesRes['status'] == true) {
      final list = imagesRes['data'];
      if (list is List) {
        totalItems = list.length;
      }
    }

    final dates = await CalendarService().getImportantDates(
      token: token!,
      userId: userId!,
    );
    final now = AppTime.now();
    final upcoming = dates.where((d) {
      final date = DateTime(d.date.year, d.date.month, d.date.day);
      final today = DateTime(now.year, now.month, now.day);
      return date.isAtSameMomentAs(today) || date.isAfter(today);
    }).length;

    setState(() {
      _quickStats = [
        _StatItem(
          label: 'Total items',
          value: totalItems.toString(),
          icon: Icons.inventory_2,
        ),
        _StatItem(
          label: 'Upcoming events',
          value: upcoming.toString(),
          icon: Icons.event_available,
        ),
      ];
    });
  }

  Future<void> _loadWeather() async {
    const lat = 28.61;
    const lon = 77.20;
    final temp = await WeatherService().getTemperature(lat, lon);
    final tempRounded = temp.round();
    final condition = _conditionForTemp(tempRounded);
    final tip = _tipForTemp(tempRounded);

    setState(() {
      _weather = _WeatherData(
        city: 'Delhi',
        temperatureC: tempRounded,
        condition: condition,
        tip: tip,
      );
    });
  }

  Future<void> _loadNextPlan() async {
    if (token == null || userId == null) return;
    final dates = await CalendarService().getImportantDates(
      token: token!,
      userId: userId!,
    );
    if (dates.isEmpty) {
      setState(() {
        _todayOutfit = const _OutfitData(
          title: "Today's planned outfit",
          description: 'No upcoming plans yet',
        );
      });
      return;
    }

    dates.sort((a, b) => a.date.compareTo(b.date));
    final next = dates.first;
    setState(() {
      _todayOutfit = _OutfitData(
        title: "Today's planned outfit",
        description: 'Next: ${next.title} on ${next.dateLabel}',
      );
    });
  }

  String _conditionForTemp(int temp) {
    if (temp >= 34) return 'Hot';
    if (temp >= 28) return 'Warm';
    if (temp >= 22) return 'Mild';
    return 'Cool';
  }

  String _tipForTemp(int temp) {
    if (temp >= 34) return 'Breathable fabrics recommended';
    if (temp >= 28) return 'Light layers recommended';
    if (temp >= 22) return 'Comfort layers recommended';
    return 'Add a light jacket';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good morning, $_greetingName',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Style with confidence today',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.person, color: AppTheme.plum),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _WeatherCard(data: _weather, onRefresh: _loadWeather),
              const SizedBox(height: 16),
              _TodayOutfitCard(data: _todayOutfit),
              const SizedBox(height: 16),
              _PrimaryCta(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AiSuggestionPage()),
                ),
              ),
              const SizedBox(height: 20),
              _QuickStats(items: _quickStats),
              const SizedBox(height: 24),
              Text('Boosters', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _ActionGrid(items: _boosters),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeatherData {
  const _WeatherData({
    required this.city,
    required this.temperatureC,
    required this.condition,
    required this.tip,
  });

  final String city;
  final int temperatureC;
  final String condition;
  final String tip;
}

class _OutfitData {
  const _OutfitData({required this.title, required this.description});

  final String title;
  final String description;
}

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({required this.data, required this.onRefresh});

  final _WeatherData data;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.softShadows,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.mint.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.wb_sunny, color: AppTheme.plum, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data.city} - ${data.temperatureC}C - ${data.condition}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(data.tip, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          TextButton(onPressed: onRefresh, child: const Text('Refresh')),
        ],
      ),
    );
  }
}

class _TodayOutfitCard extends StatelessWidget {
  const _TodayOutfitCard({required this.data});

  final _OutfitData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.softShadows,
      ),
      child: Row(
        children: [
          Container(
            height: 76,
            width: 76,
            decoration: BoxDecoration(
              color: AppTheme.cloud,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Icon(Icons.checkroom, color: AppTheme.plum),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  data.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          TextButton(onPressed: () {}, child: const Text('Edit')),
        ],
      ),
    );
  }
}

class _PrimaryCta extends StatelessWidget {
  const _PrimaryCta({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.plum,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Get outfit suggestion',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Tell us your occasion, weather, or vibe and get a complete look.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.plum,
              ),
              child: const Text('Suggest Now'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats({required this.items});

  final List<_StatItem> items;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(items.length, (index) {
        final item = items[index];
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 0 ? 12 : 0),
            child: _StatCard(
              label: item.label,
              value: item.value,
              icon: item.icon,
            ),
          ),
        );
      }),
    );
  }
}

class _StatItem {
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.plum),
          const SizedBox(height: 12),
          Text(value, style: Theme.of(context).textTheme.headlineMedium),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  const _ActionGrid({required this.items});

  final List<_ActionItem> items;

  @override
  Widget build(BuildContext context) {
    final rows = <List<_ActionItem>>[];
    for (var i = 0; i < items.length; i += 2) {
      rows.add(items.sublist(i, i + 2 > items.length ? items.length : i + 2));
    }

    return Column(
      children: List.generate(rows.length, (rowIndex) {
        final row = rows[rowIndex];
        return Padding(
          padding: EdgeInsets.only(
            bottom: rowIndex == rows.length - 1 ? 0 : 12,
          ),
          child: Row(
            children: List.generate(2, (colIndex) {
              if (colIndex >= row.length) {
                return const Expanded(child: SizedBox());
              }
              final item = row[colIndex];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: colIndex == 0 ? 12 : 0),
                  child: _ActionTile(
                    title: item.title,
                    subtitle: item.subtitle,
                    icon: item.icon,
                    onTap: item.onTap,
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

class _ActionItem {
  const _ActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.softShadows,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.plum),
            const SizedBox(height: 10),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
