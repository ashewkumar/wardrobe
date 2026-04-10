import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


import '../services/api_service.dart';
import '../pages/dashboard_page.dart';
import 'ui/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;

  final _emailFormKey = GlobalKey<FormState>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscureText = true;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);
  }

  // ================= EMAIL LOGIN =================

 Future<void> emailLogin() async {
  if (!_emailFormKey.currentState!.validate()) return;

  setState(() => isLoading = true);

  try {
    final response = await ApiService.login(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    setState(() => isLoading = false);

    if (!mounted) return;

    if (response != null) {
      // ✅ CREATE prefs FIRST
      final prefs = await SharedPreferences.getInstance();

      // ✅ SAVE TOKEN
      await prefs.setString("token", response['token']);

      // ✅ SAVE USER ID
      //await prefs.setInt("user_id", response['user']['id']);
      await prefs.setString(
  "user_id",
  response['user']['id'].toString(),
);

      print("SAVED → token=${response['token']}");
      print("SAVED → user_id=${response['user']['id']}");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardPage()),
      );
    } else {
      showError("Invalid email or password");
    }
  } catch (e) {
    setState(() => isLoading = false);
    print("LOGIN ERROR: $e");
    showError("Login failed");
  }
}


  // ================= UI HELPERS =================

  void showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.softBg,

      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.white, Color(0xFFEFF7FF)],
            ),
          ),
          child: Column(
            children: [

              const SizedBox(height: 40),

              Container(
                width: 88,
                height: 88,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.softBg,
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.softShadows,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/icons/app_icon.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "Welcome To My Wardrobe",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.navy,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                "Dress smarter, every day",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 18),

              TabBar(
                controller: _tabController,
                labelColor: AppTheme.navy,
                unselectedLabelColor: Colors.black54,
                indicatorColor: AppTheme.sky,
                indicatorWeight: 3,
                tabs: const [
                  Tab(text: "Email Login"),
                  Tab(text: "Mobile OTP"),
                ],
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [

                    emailLoginUI(),

                    const Center(
                      child: Text(
                        "OTP Login Coming Soon",
                        style: TextStyle(color: Colors.black),
                      ),
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

  // ================= EMAIL UI =================

  Widget emailLoginUI() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),

      child: Form(
        key: _emailFormKey,

        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: AppTheme.softBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.softBorder),
            boxShadow: AppTheme.softShadows,
          ),
          child: Column(
            children: [

              const SizedBox(height: 10),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Sign in",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.navy,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: emailController,

                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email, color: AppTheme.navy),
                  filled: true,
                  fillColor: AppTheme.softSurface,
                ),

                validator: (v) {
                  if (v == null || v.isEmpty) return "Enter email";
                  if (!v.contains("@")) return "Invalid email";
                  return null;
                },
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: passwordController,
                obscureText: obscureText,

                decoration: InputDecoration(
                  labelText: "Password",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock, color: AppTheme.navy),
                  filled: true,
                  fillColor: AppTheme.softSurface,

                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppTheme.navy,
                    ),
                    onPressed: () {
                      setState(() => obscureText = !obscureText);
                    },
                  ),
                ),

                validator: (v) {
                  if (v == null || v.isEmpty) return "Enter password";
                  if (v.length < 6) return "Min 6 chars";
                  return null;
                },
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,

                child: ElevatedButton(
                  onPressed: isLoading ? null : emailLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.navy,
                    foregroundColor: Colors.white,
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Login",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Look sharp. Save time.",
                style: TextStyle(fontSize: 12, color: Colors.black45),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
