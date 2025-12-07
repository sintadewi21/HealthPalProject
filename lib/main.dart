import 'package:flutter/material.dart';
import 'onboarding.dart'; // sesuaikan path kalau kamu taruh di folder lain

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'HealthPal Onboarding',
      theme: ThemeData(
        primaryColor: const Color(0xFF111827),
        useMaterial3: false,
      ),
      home: const OnboardingScreen(),
    );
  }
}
