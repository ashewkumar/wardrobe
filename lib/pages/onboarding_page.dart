import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../ui/app_theme.dart';
import 'auth_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _index = 0;

  final List<_OnboardingSlide> _slides = const [
    _OnboardingSlide(
      title: "Digital Wardrobe",
      body:
          "Upload your closet once and get a clean, searchable inventory that keeps every piece in play.",
      icon: Icons.grid_view_rounded,
    ),
    _OnboardingSlide(
      title: "AI Outfit Suggestions",
      body:
          "Instantly build looks based on your style tags, color harmony, and what's already in your wardrobe.",
      icon: Icons.auto_awesome,
    ),
    _OnboardingSlide(
      title: "Calendar & Events",
      body:
          "Plan outfits ahead, attach them to events, and receive smart reminders before your day starts.",
      icon: Icons.calendar_month,
    ),
    _OnboardingSlide(
      title: "Travel & Packing",
      body:
          "Create a trip, fetch the weather, and pack with capsule collections that actually get worn.",
      icon: Icons.card_travel,
    ),
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AuthPage()),
    );
  }

  void _next() {
    if (_index < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Wardrobe Studio",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: _completeOnboarding,
                      child: const Text("Skip"),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 140,
                            width: 140,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: AppTheme.softShadows,
                            ),
                            child: Icon(slide.icon, size: 64, color: AppTheme.plum),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            slide.title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            slide.body,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: index == _index ? 28 : 8,
                          decoration: BoxDecoration(
                            color: index == _index ? AppTheme.plum : AppTheme.border,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _next,
                        child: Text(_index == _slides.length - 1
                            ? "Start Styling"
                            : "Next"),
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
}

class _OnboardingSlide {
  final String title;
  final String body;
  final IconData icon;

  const _OnboardingSlide({
    required this.title,
    required this.body,
    required this.icon,
  });
}
