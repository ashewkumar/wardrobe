import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../ui/app_theme.dart';
import '../ui/modern_ui.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool loading = true;
  Map<String, dynamic>? profile;
  String? error;
  String? token;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');

    if (token == null) {
      setState(() {
        loading = false;
        error = 'Not logged in';
      });
      return;
    }

    final res = await ApiService.getProfile(token!);
    if (res != null && res['status'] == true) {
      setState(() {
        profile = res['data'] as Map<String, dynamic>;
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
        error = 'Failed to load profile';
      });
    }
  }

  Future<void> _showEditDialog() async {
    if (profile == null || token == null) return;

    final nameController = TextEditingController(text: profile?['name']?.toString() ?? '');
    final phoneController = TextEditingController(text: profile?['phone']?.toString() ?? '');
    final locationController = TextEditingController(text: profile?['location']?.toString() ?? '');

    bool saving = false;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Edit Profile'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Phone'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: locationController,
                      decoration: const InputDecoration(labelText: 'Location'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          setLocalState(() => saving = true);

                          final res = await ApiService.updateProfile(
                            token!,
                            name: nameController.text.trim(),
                            phone: phoneController.text.trim(),
                            location: locationController.text.trim(),
                          );

                          setLocalState(() => saving = false);

                          if (res != null && res['status'] == true) {
                            if (!mounted) return;
                            Navigator.pop(context);
                            await _loadProfile();
                          }
                        },
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    final name = profile?['name']?.toString() ?? 'User';
    final email = profile?['email']?.toString() ?? '';
    final phone = profile?['phone']?.toString() ?? '';
    final location = profile?['location']?.toString() ?? '';
    final createdAt = profile?['created_at']?.toString();
    final joined = createdAt != null && createdAt.length >= 4
        ? createdAt.substring(0, 4)
        : '';

    return Scaffold(
      appBar: ModernUI.appBar(
        context: context,
        title: 'My Profile',
        actions: [
          IconButton(
            onPressed: loading ? null : _showEditDialog,
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: ModernUI.pageWrapper(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : error != null
                  ? Center(child: Text(error!))
                  : Column(
                      children: [
                        const SizedBox(height: 20),

                        // PROFILE IMAGE
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            CircleAvatar(
                              radius: 60,
                              backgroundColor: AppTheme.softBg,
                              child: const Icon(
                                Icons.person,
                                size: 70,
                              ),
                            ),
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: colors.primary,
                              child: const Icon(
                                Icons.edit,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // NAME
                        Text(
                          name,
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 6),

                        // EMAIL
                        Text(
                          email,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),

                        const SizedBox(height: 30),

                        // INFO CARDS
                        _infoTile(
                          context,
                          icon: Icons.phone_outlined,
                          title: 'Mobile',
                          value: phone.isEmpty ? '-' : phone,
                        ),

                        _infoTile(
                          context,
                          icon: Icons.location_on_outlined,
                          title: 'Location',
                          value: location.isEmpty ? '-' : location,
                        ),

                        _infoTile(
                          context,
                          icon: Icons.calendar_today_outlined,
                          title: 'Joined',
                          value: joined.isEmpty ? '-' : joined,
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  // ================= INFO TILE =================

  Widget _infoTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.softBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.softBorder),
          boxShadow: AppTheme.softShadows,
        ),
        child: ListTile(
          leading: Icon(
            icon,
            color: colors.primary,
          ),
          title: Text(title),
          subtitle: Text(value),
        ),
      ),
    );
  }
}
