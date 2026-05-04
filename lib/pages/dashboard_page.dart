import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../login_page.dart';
import '../ui/modern_ui.dart';
import '../ui/app_theme.dart';

import '../services/api_config.dart';
import '../services/api_service.dart';
import '../services/app_time_service.dart';
import '../services/weather_service.dart';
import '../services/ai_service.dart';
import '../services/calendar_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // ================= USER DATA =================

  String? token;
  String? userId;

  // ================= AI DATA =================

  String outfitName = "";
  String imageUrl = "";
  List<String> imageUrls = [];
  bool loading = false;
  String seasonLabel = "";
  String weatherLabel = "";
  String occasionLabel = "";
  String specialDayTitle = "";

  // ================= INIT =================

  @override
  void initState() {
    super.initState();
    loadAuth(); // only this
  }

  Future<void> loadAuth() async {
    final prefs = await SharedPreferences.getInstance();

    //final token = prefs.getString("token");
    token = prefs.getString("token");
    //final userId = prefs.getInt("user_id");
    userId = prefs.getString("user_id");

    print("LOADED → token=$token , userId=$userId");

    if (token == null || userId == null) {
      print("TOKEN OR USER ID MISSING");
      return;
    }

    // Auto-load suggestion so it highlights on the dashboard
    await _getSuggestion();
  }

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

  // ================= AI SUGGEST =================

  Future<void> _getSuggestion() async {
    if (token == null || userId == null) {
      print("TOKEN OR USER ID MISSING");
      return;
    }

    setState(() {
      loading = true;
      outfitName = "";
      imageUrl = "";
      imageUrls = [];
      seasonLabel = "";
      weatherLabel = "";
      occasionLabel = "";
      specialDayTitle = "";
    });

    try {
      // ================= LOCATION (Demo) =================
      double lat = 28.61;
      double lon = 77.20;

      // ================= GET WEATHER =================
      final temp = await WeatherService().getTemperature(lat, lon);

      // ================= GET SEASON =================
      final season = AIService.getSeason(temp);

      // ================= GET OCCASION =================
      final now = AppTime.now();
      final specialDate = await CalendarService().getImportantDateFor(
        now,
        token: token!,
        userId: userId!,
      );
      final occasion = AIService.resolveOccasion(
        date: now,
        calendarOccasion: specialDate?.occasion,
      );

      print("TEMP=$temp → SEASON=$season");

      // ================= API CALL =================
      final res = await ApiService.getOutfitSuggestion(
        token!,
        season,
        occasion,
        userId!,
      );

      print("AI RESPONSE = $res");

      if (res != null && res['status'] == true) {
        final data = res['data'];

        final List<String> urls = [];
        final images = data['images'];
        if (images is List) {
          for (final item in images) {
            if (item is String) {
              final url = ApiConfig.imageUrl(item);
              if (url != null) {
                urls.add(url);
              }
            } else if (item is Map && item['image_url'] != null) {
              final url = ApiConfig.imageUrl(item['image_url']);
              if (url != null) {
                urls.add(url);
              }
            }
          }
        }

        setState(() {
          outfitName = data['image_name'] ?? "";

          imageUrl = ApiConfig.imageUrl(data['image_url']) ?? "";
          imageUrls = urls;
          seasonLabel = season;
          weatherLabel = "${temp.toStringAsFixed(1)}°C";
          occasionLabel = occasion;
          specialDayTitle = specialDate?.title ?? "";
        });
      } else {
        setState(() {
          outfitName = "No Outfit Found";
          imageUrl = "";
          imageUrls = [];
          seasonLabel = season;
          weatherLabel = "${temp.toStringAsFixed(1)}°C";
          occasionLabel = occasion;
          specialDayTitle = specialDate?.title ?? "";
        });
      }
    } catch (e) {
      print("SUGGEST ERROR: $e");

      setState(() {
        outfitName = "Error Occurred";
        imageUrl = "";
        imageUrls = [];
        seasonLabel = "";
        weatherLabel = "";
        occasionLabel = "";
        specialDayTitle = "";
      });
    }

    setState(() {
      loading = false;
    });
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ================= APP BAR =================
      appBar: ModernUI.appBar(
        context: context,
        title: "My Wardrobe",
        logout: _logout,
      ),

      // ================= DRAWER =================
      drawer: _buildDrawer(),

      // ================= BODY =================
      body: ModernUI.pageWrapper(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const Text(
                "Welcome",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 4),

              const Text(
                "Manage your wardrobe easily",
                style: TextStyle(color: Colors.black54),
              ),

              const SizedBox(height: 25),

              // ================= AI CARD =================
              _aiSuggestionCard(),

              const SizedBox(height: 20),

              // ================= DASHBOARD =================
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,

                  children: [
                    ModernUI.dashboardCard(
                      icon: Icons.cloud_upload_outlined,
                      title: "Upload",
                      color: AppTheme.navy,
                      onTap: () {
                        Navigator.pushNamed(context, '/upload-image');
                      },
                    ),

                    ModernUI.dashboardCard(
                      icon: Icons.photo_library_outlined,
                      title: "Gallery",
                      color: const Color(0xFF3A8BC2),
                      onTap: () {
                        Navigator.pushNamed(context, '/gallery');
                      },
                    ),

                    // ================= AI =================
                    ModernUI.dashboardCard(
                      icon: Icons.auto_awesome_outlined,
                      title: "AI Suggest",
                      color: const Color(0xFF5AA9E6),
                      onTap: _getSuggestion,
                    ),

                    ModernUI.dashboardCard(
                      icon: Icons.event_outlined,
                      title: "Important Dates",
                      color: const Color(0xFF4B8BBE),
                      onTap: () {
                        Navigator.pushNamed(context, '/important-dates');
                      },
                    ),

                    ModernUI.dashboardCard(
                      icon: Icons.person_outline,
                      title: "Profile",
                      color: const Color(0xFF1E3A8A),
                      onTap: () {
                        Navigator.pushNamed(context, '/profile');
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

  // ================= AI CARD =================

  Widget _aiSuggestionCard() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: AppTheme.softBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.softBorder),
        boxShadow: AppTheme.softShadows,
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          const Text(
            "Today's Outfit",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          if (specialDayTitle.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F1FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.event_available_outlined,
                    size: 16,
                    color: AppTheme.navy,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Today Highlight: $specialDayTitle",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.navy,
                    ),
                  ),
                ],
              ),
            ),

          if (specialDayTitle.isNotEmpty) const SizedBox(height: 10),

          if (weatherLabel.isNotEmpty || seasonLabel.isNotEmpty)
            Text(
              "Weather: $weatherLabel • $seasonLabel",
              style: const TextStyle(color: Colors.black54),
            ),

          if (occasionLabel.isNotEmpty) const SizedBox(height: 4),

          if (occasionLabel.isNotEmpty)
            Text(
              specialDayTitle.isNotEmpty
                  ? "Occasion: $specialDayTitle ($occasionLabel)"
                  : "Occasion: $occasionLabel",
              style: const TextStyle(color: Colors.black54),
            ),

          if (weatherLabel.isNotEmpty || occasionLabel.isNotEmpty)
            const SizedBox(height: 10),

          if (loading)
            const Center(child: CircularProgressIndicator())
          else if (outfitName.isNotEmpty)
            Column(
              children: [
                Row(
                  children: [
                    if (imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),

                        child: Image.network(
                          imageUrl, // ??? Already full URL

                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,

                          errorBuilder: (c, e, s) {
                            return const Icon(Icons.broken_image);
                          },
                        ),
                      ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        outfitName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (imageUrls.isNotEmpty) const SizedBox(height: 12),
                if (imageUrls.isNotEmpty)
                  SizedBox(
                    height: 96,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: imageUrls.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final url = imageUrls[i];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            url,
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) =>
                                const Icon(Icons.broken_image),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            )
          else if (imageUrls.isNotEmpty)
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: imageUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final url = imageUrls[i];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      url,
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
                    ),
                  );
                },
              ),
            )
          else
            const Text(
              "Tap 'AI Suggest' to get outfit",
              style: TextStyle(color: Colors.black54),
            ),
        ],
      ),
    );
  }

  // ================= DRAWER =================

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppTheme.softBg,

      child: ListView(
        padding: EdgeInsets.zero,

        children: [
          // ================= HEADER =================
          Container(
            height: 200,

            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [AppTheme.navy, AppTheme.sky]),
            ),

            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: AppTheme.softBg,
                  child: Icon(Icons.person, size: 45, color: AppTheme.navy),
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

          _drawerItem(
            icon: Icons.settings_outlined,
            title: "Settings",
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/settings');
            },
          ),

          _drawerItem(
            icon: Icons.event_outlined,
            title: "Important Dates",
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/important-dates');
            },
          ),

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

      title: Text(title, style: TextStyle(color: color)),

      onTap: onTap,
    );
  }
}
