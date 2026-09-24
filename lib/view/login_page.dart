import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exam/view/category_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/class/route_transitions.dart';
import '../service/auth_service.dart';

// ================= Login Page =================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // ================= Services & State =================
  final AuthService authService = AuthService();
  bool isLoading = false;

  // ================= Google Sign-In =================
  Future<void> _signInWithGoogle() async {
    if (isLoading) return;
    setState(() => isLoading = true);

    final user = await authService.signInWithGoogle();

    if (!mounted) return;

    if (user != null) {
      await saveGoogleUser(user);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        AppRoute.fadeSlide(const CategoryPage()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("لم يتم تسجيل الدخول")),
      );
    }

    setState(() => isLoading = false);
  }

  Future<void> saveGoogleUser(User user) async {
    final doc = FirebaseFirestore.instance.collection('users').doc(user.uid);

    final snapshot = await doc.get();
    final fallbackName = user.displayName ?? user.email?.split('@').first ?? 'Google User';

    if (!snapshot.exists) {
      await doc.set({
        'displayName': fallbackName,
        'email': user.email ?? '',
        'photoURL': user.photoURL ?? '',
        'correctAnswers': 0,
        'wrongAnswers': 0,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } else {
      await doc.update({
        'displayName': user.displayName ?? snapshot.data()?['displayName'] ?? fallbackName,
        'email': user.email ?? snapshot.data()?['email'] ?? '',
        'photoURL': user.photoURL ?? snapshot.data()?['photoURL'] ?? '',
        'lastSeen': FieldValue.serverTimestamp(),
      });
    }
  }

  // ================= Guest Flow =================
  void _continueAsGuest() {
    Navigator.pushReplacement(
      context,
      AppRoute.fadeSlide(const CategoryPage()),
    );
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 36,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E163B).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header Lock Icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                        border: Border.all(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                            blurRadius: 18,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_person_rounded,
                        size: 52,
                        color: Color(0xFFA78BFA),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Title
                    const Text(
                      "مرحبًا بك",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Subtitle
                    const Text(
                      "سجّل الدخول لحفظ تقدمك ومزامنة نتائجك\nأو تابع كضيف",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ================= Google Button =================
                    InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: isLoading ? null : _signInWithGoogle,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF6C63FF),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      "asset/images/google2.png",
                                      height: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      "تسجيل الدخول باستخدام Google",
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ================= Guest Button =================
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _continueAsGuest,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          icon: const Icon(
                            Icons.person_outline_rounded,
                            color: Colors.white70,
                            size: 20,
                          ),
                          label: const Text(
                            "المتابعة كضيف",
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white70,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
