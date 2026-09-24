import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/class/route_transitions.dart';
import 'category_page.dart';
import 'onboarding_view.dart';

// ================= Splash Page =================
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  // ================= Lifecycle =================
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      _checkFirstTime();
    });
  }

  // ================= First Time Check =================
  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isFirstTime = prefs.getBool('isFirstTime') ?? true;

    if (isFirstTime) {
      await prefs.setBool('isFirstTime', false);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        AppRoute.fadeSlide(const OnboardingView()),
      );
    } else {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        AppRoute.fadeSlide(const CategoryPage()),
      );
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0F0C20),
              Color(0xFF1E1035),
              Color(0xFF2A0845),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Logo Avatar with glowing border
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                      blurRadius: 25,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: const CircleAvatar(
                  backgroundImage: ResizeImage(
                    AssetImage('asset/images/quiz2.jpg'),
                    width: 300,
                    height: 300,
                  ),
                  radius: 75,
                ),
              ),

              const SizedBox(height: 28),

              // Title
              const Text(
                "منصة الاختبارات الذكية",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              const Text(
                "اختبارات متطورة مدعومة بالذكاء الاصطناعي",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const Spacer(),

              // Loading Indicator
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFFA78BFA),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
