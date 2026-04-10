import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../ui/app_theme.dart';
import 'home_shell.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool _isLogin = true;
  bool _acceptTerms = false;
  bool _usePhone = false;
  bool _loading = false;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _phone = TextEditingController();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please accept Terms & Privacy Policy")),
      );
      return;
    }

    if (_usePhone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phone login not implemented yet")),
      );
      return;
    }

    if (!_isLogin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signup not implemented yet")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final res = await ApiService.login(
        _email.text.trim(),
        _password.text.trim(),
      );

      setState(() => _loading = false);

      if (!mounted) return;

      if (res != null && res['status'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', res['token']);
        await prefs.setString('user_id', res['user']['id'].toString());

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeShell()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid credentials")),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: $e")),
      );
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _isLogin ? "Welcome Back" : "Create Account",
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin
                        ? "Pick up your styling routine where you left off."
                        : "Build a smarter wardrobe that works with you.",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppTheme.softShadows,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => setState(() => _isLogin = true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isLogin
                                        ? AppTheme.plum
                                        : AppTheme.border,
                                    foregroundColor: _isLogin
                                        ? Colors.white
                                        : AppTheme.ink,
                                  ),
                                  child: const Text("Login"),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => setState(() => _isLogin = false),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: !_isLogin
                                        ? AppTheme.plum
                                        : AppTheme.border,
                                    foregroundColor: !_isLogin
                                        ? Colors.white
                                        : AppTheme.ink,
                                  ),
                                  child: const Text("Sign Up"),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SwitchListTile(
                            title: const Text("Use phone + OTP"),
                            value: _usePhone,
                            onChanged: (value) => setState(() => _usePhone = value),
                          ),
                          if (_usePhone)
                            TextFormField(
                              controller: _phone,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: "Phone number",
                                prefixIcon: Icon(Icons.phone),
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty ? "Required" : null,
                            )
                          else
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: "Email address",
                                prefixIcon: Icon(Icons.mail),
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty ? "Required" : null,
                            ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _password,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: "Password",
                              prefixIcon: Icon(Icons.lock_outline),
                            ),
                            validator: (value) =>
                                value == null || value.length < 6
                                    ? "Minimum 6 characters"
                                    : null,
                          ),
                          if (_isLogin)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                child: const Text("Forgot password?"),
                              ),
                            ),
                          CheckboxListTile(
                            value: _acceptTerms,
                            onChanged: (value) =>
                                setState(() => _acceptTerms = value ?? false),
                            title: const Text("I accept Terms & Privacy Policy"),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              child: _loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(_isLogin ? "Login" : "Create Account"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _isLogin
                            ? "New here? "
                            : "Already have an account? ",
                      ),
                      TextButton(
                        onPressed: () => setState(() => _isLogin = !_isLogin),
                        child: Text(_isLogin ? "Sign up" : "Login"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
