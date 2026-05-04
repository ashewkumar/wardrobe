import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/auth_page.dart';
import 'pages/home_shell.dart';
import 'pages/onboarding_page.dart';
import 'pages/splash_page.dart';
import 'services/analytics_service.dart';
import 'services/app_time_service.dart';
import 'services/notification_service.dart';
import 'services/stability_service.dart';
import 'ui/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppTime.init();
  await AppAnalyticsService.instance.init();
  await AppStabilityService.instance.init();
  await AppNotificationService.instance.init();
  await AppAnalyticsService.instance.track('app_open');

  runZonedGuarded(
    () => runApp(const MyApp()),
    (error, stack) => AppStabilityService.instance.recordError(
      'run_zoned_guarded',
      '$error\n$stack',
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<_EntryState> _resolveEntry() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_PrefsKeys.authToken);
    final onboardingDone =
        prefs.getBool(_PrefsKeys.onboardingComplete) ?? false;
    return _EntryState(onboardingDone: onboardingDone, hasToken: token != null);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: FutureBuilder<_EntryState>(
        future: _resolveEntry(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SplashPage();
          }

          if (snapshot.hasError) {
            return const Scaffold(
              body: Center(child: Text("Something went wrong")),
            );
          }

          final data = snapshot.data;
          if (data == null) {
            return const SplashPage();
          }

          if (!data.onboardingDone) {
            return const OnboardingPage();
          }

          if (!data.hasToken) {
            return const AuthPage();
          }

          return const HomeShell();
        },
      ),
    );
  }
}

class _PrefsKeys {
  static const String authToken = 'token';
  static const String onboardingComplete = 'onboarding_complete';
}

class _EntryState {
  final bool onboardingDone;
  final bool hasToken;

  const _EntryState({required this.onboardingDone, required this.hasToken});
}
