import 'dart:async';
import 'package:flutter/material.dart';
import 'language_selection_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LanguageSelectionPage(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F123A),
      body: Center(
        child: CircleAvatar(
          backgroundImage:  const AssetImage('asset/images/quiz2.jpg'),
          radius: 100,
         ),
      ),
    );
  }
}
