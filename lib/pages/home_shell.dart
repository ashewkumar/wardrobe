import 'package:flutter/material.dart';

import '../ui/app_theme.dart';
import 'calendar_page.dart';
import 'home_dashboard_page.dart';
import 'inner_circle_page.dart';
import 'profile_settings_page.dart';
import 'travel_page.dart';
import 'wardrobe_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  final List<Widget> _pages = const [
    HomeDashboardPage(),
    WardrobePage(),
    CalendarPage(),
    InnerCirclePage(),
    TravelPage(),
    ProfileSettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: AppTheme.softShadows,
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          type: BottomNavigationBarType.fixed,
          onTap: (value) => setState(() => _index = value),
          selectedItemColor: AppTheme.plum,
          unselectedItemColor: Colors.black54,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.checkroom_outlined),
              label: "Wardrobe",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label: "Calendar",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite_outline),
              label: "Inner Circle",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.card_travel),
              label: "Travel",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }
}
