import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exam/view/category_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
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
  String loadingStatus = "جاري تسجيل الدخول...";

  // ================= Google Sign-In =================
  Future<void> _signInWithGoogle() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
      loadingStatus = "جاري الاتصال بحساب Google...";
    });

    try {
      final user = await authService.signInWithGoogle();

      if (!mounted) return;

      if (user != null) {
        setState(() {
          loadingStatus = "جاري حفظ بيانات الحساب...";
        });

        await saveGoogleUser(user);

        if (!mounted) return;

        Fluttertoast.showToast(msg: "أهلاً بك ${user.displayName ?? ''}!");

        Navigator.pushReplacement(
          context,
          AppRoute.fadeSlide(const CategoryPage()),
        );
      } else {
        // المستخدم قام بإلغاء النافذة
        Fluttertoast.showToast(msg: "تم إلغاء تسجيل الدخول");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("فشل تسجيل الدخول: ${e.toString().split('\n').first}"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> saveGoogleUser(User user) async {
    try {
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
    } catch (_) {}
  }

  // ================= Guest Flow =================
  void _continueAsGuest() {
    if (isLoading) return;
    Navigator.pushReplacement(
      context,
      AppRoute.fadeSlide(const CategoryPage()),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
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
                              child: Row(
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
                              onPressed: isLoading ? null : _continueAsGuest,
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

          // ================= Full Screen Loading Overlay =================
          if (isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E163B),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 42,
                        height: 42,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Color(0xFFA78BFA),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        loadingStatus,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
