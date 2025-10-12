// lib/main.dart

import 'package:flutter/material.dart';
import 'package:time_os_final/screens/main_screen.dart';
import 'package:time_os_final/screens/onboarding/onboarding_flow_screen.dart';
import 'package:time_os_final/helpers/preferences_helper.dart';
import 'package:time_os_final/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if user has completed onboarding
  final bool hasOnboarded = await PreferencesHelper.hasOnboarded();

  runApp(MyApp(hasOnboarded: hasOnboarded));
}

class MyApp extends StatelessWidget {
  final bool hasOnboarded;

  const MyApp({super.key, required this.hasOnboarded});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TIME_OS',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      // Route configuration
      initialRoute: hasOnboarded ? '/main' : '/onboarding',
      routes: {
        '/onboarding': (context) => const OnboardingFlowScreen(),
        '/main': (context) => const MainScreen(),
      },
    );
  }
}
