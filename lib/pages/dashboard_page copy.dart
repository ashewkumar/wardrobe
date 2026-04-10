import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../login_page.dart';
import '../ui/modern_ui.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {

  // ================= LOGOUT =================

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      backgroundColor: const Color(0xFFF7F9FA), // Soft White

      // ================= APP BAR =================

      appBar: ModernUI.appBar(
        context: context,
        title: "My Wardrobe",
        logout: _logout,
      ),

      // ================= DRAWER =================

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [

            // Header
            Container(
              height: 200,
              width: double.infinity,

              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF009688), // Teal
                    Color(0xFF4DB6AC), // Light Teal
                  ],
                ),
              ),

              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [

                  CircleAvatar(
                    radius: 42,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 45,
                      color: Color(0xFF009688),
                    ),
                  ),

                  SizedBox(height: 12),

                  Text(
                    "Welcome User",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Menu Items

            _drawerItem(
              icon: Icons.dashboard_outlined,
              title: "Dashboard",
              onTap: () => Navigator.pop(context),
            ),

            _drawerItem(
              icon: Icons.cloud_upload_outlined,
              title: "Upload Image",
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/upload-image');
              },
            ),

            _drawerItem(
              icon: Icons.photo_library_outlined,
              title: "Gallery",
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/gallery');
              },
            ),
            // SETTINGS ✅ NEW
      _drawerItem(
        icon: Icons.settings_outlined,
        title: "Settings",
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/settings');
        },
      ),
          // PROFILE ✅ NEW
_drawerItem(
  icon: Icons.person_outline,
  title: "Profile",
  onTap: () {
    Navigator.pop(context);
    Navigator.pushNamed(context, '/profile');
  },
),


            const Divider(),

            _drawerItem(
              icon: Icons.logout,
              title: "Logout",
              color: Colors.red,
              onTap: _logout,
            ),
          ],
        ),
      ),

      // ================= BODY =================

      body: ModernUI.pageWrapper(

        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              const Text(
                "Welcome 👋",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              const Text(
                "Manage your wardrobe easily",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 25),

              Expanded(
                child: GridView.count(

                  crossAxisCount: 2,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,

                  children: [

                    ModernUI.dashboardCard(
                      icon: Icons.cloud_upload_outlined,
                      title: "Upload",
                      color: const Color(0xFF009688), // Teal
                      onTap: () {
                        Navigator.pushNamed(context, '/upload-image');
                      },
                    ),

                    ModernUI.dashboardCard(
                      icon: Icons.photo_library_outlined,
                      title: "Gallery",
                      color: const Color(0xFF4DB6AC), // Light Teal
                      onTap: () {
                        Navigator.pushNamed(context, '/gallery');
                      },
                    ),

                    ModernUI.dashboardCard(
                      icon: Icons.category_outlined,
                      title: "Category",
                      color: const Color(0xFF26A69A),
                      onTap: () {
                        // TODO
                      },
                    ),

                    ModernUI.dashboardCard(
                      icon: Icons.favorite_outline,
                      title: "Favorites",
                      color: const Color(0xFF80CBC4),
                      onTap: () {
                        // TODO
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= DRAWER ITEM =================

  Widget _drawerItem({
    required IconData icon,
    required String title,
    Color color = Colors.black87,
    required VoidCallback onTap,
  }) {
    return ListTile(

      leading: Icon(icon, color: color),

      title: Text(
        title,
        style: TextStyle(color: color),
      ),

      onTap: onTap,
    );
  }
}
