import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exam/view/language_selection_page.dart';
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
      Navigator.pushReplacement(
        context,
        AppRoute.fadeSlide(const LanguageSelectionPage()),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("لم يتم تسجيل الدخول")));
    }

    setState(() => isLoading = false);
  }
  Future<void> saveGoogleUser(User user) async {
    final doc = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid);

    final snapshot = await doc.get();

    if (!snapshot.exists) {
      await doc.set({
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'correctAnswers': 0,
        'wrongAnswers': 0,
      });
    } else {
      await doc.update({
        'displayName': user.displayName,
        'photoURL': user.photoURL,
      });
    }
  }


  // ================= Guest Flow =================
  void _continueAsGuest() {
    Navigator.pushReplacement(
      context,
      AppRoute.fadeSlide(const LanguageSelectionPage()),
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
            colors: [Color(0xff1D2671), Color(0xffC33764)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Card(
            elevation: 16,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                    radius: 38,
                    backgroundColor: Color(0xFFF3E5F5),
                    child: Icon(
                      Icons.lock_outline,
                      size: 42,
                      color: Color(0xFF6A1B9A),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    "مرحبًا بك",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "سجّل الدخول لحفظ تقدمك ومزامنة نتائجك\nأو تابع كضيف",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 28),

                  // ================= Google Button =================
                  InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: isLoading ? null : _signInWithGoogle,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
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
                                  color: Colors.purple,
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
                                    "Google تسجيل الدخول باستخدام ",
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ================= Guest Button =================
                  TextButton(
                    onPressed: _continueAsGuest,
                    child: const Text(
                      "المتابعة كضيف",
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF6A1B9A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
