import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../ui/app_theme.dart';
import 'auth_page.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  Map<String, dynamic>? profile;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      setState(() => loading = false);
      return;
    }

    final res = await ApiService.getProfile(token);
    if (res != null && res['status'] == true) {
      setState(() {
        profile = res['data'] as Map<String, dynamic>;
        loading = false;
      });
    } else {
      setState(() => loading = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = profile?['name']?.toString() ?? 'User';
    final email = profile?['email']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text("Profile & Settings")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppTheme.softShadows,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppTheme.mint.withOpacity(0.7),
                  child: const Icon(Icons.person, color: AppTheme.plum, size: 28),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loading ? 'Loading...' : name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loading ? '' : email,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text("Style Preferences",
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _PreferenceTile(
            title: "Preferred colors",
            value: "Ivory · Navy · Terracotta",
          ),
          _PreferenceTile(
            title: "Climate preference",
            value: "Warm weather layering",
          ),
          const SizedBox(height: 20),
          Text("Settings", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _SettingTile(
            title: "Notifications",
            subtitle: "Outfit reminders, travel prep, social alerts",
            trailing: Switch(value: true, onChanged: (_) {}),
          ),
          _SettingTile(
            title: "Privacy controls",
            subtitle: "Manage shared wardrobes and invites",
            trailing: const Icon(Icons.chevron_right),
          ),
          _SettingTile(
            title: "Delete account",
            subtitle: "GDPR / DPDP compliant request",
            trailing: const Icon(Icons.delete_outline),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _logout(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.coral),
            child: const Text("Logout"),
          ),
        ],
      ),
    );
  }
}

class _PreferenceTile extends StatelessWidget {
  const _PreferenceTile({required this.title, required this.value});

  final String title;
  final String value;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget trailing;

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
          trailing,
        ],
      ),
    );
  }
}
