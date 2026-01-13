import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exam/view/review_questions_page.dart';
import 'package:exam/view/statistics_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart' show Skeletonizer;

import '../core/class/route_transitions.dart';
import '../service/auth_service.dart';

// ================= Profile Page =================
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // ================= Services =================
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService authService = AuthService();

  // ================= User Data =================
  String displayName = "Guest Name";
  String email = "guest@quiz-app.local";
  String imageUrl = "";
  int correct = 0;
  int wrong = 0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // 🔥 تحديث البيانات عند الرجوع للصفحة
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadUserData();
  }

  // ================= Save Google User =================
  Future<void> saveGoogleUser(User user) async {
    final doc = _firestore.collection('users').doc(user.uid);
    final snapshot = await doc.get();

    // 🔄 جلب إحصائيات الضيف (إن وُجدت)
    final prefs = await SharedPreferences.getInstance();
    final localCorrect = prefs.getInt('correct') ?? 0;
    final localWrong = prefs.getInt('wrong') ?? 0;

    await doc.set({
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'correctAnswers':
      snapshot.exists ? snapshot['correctAnswers'] ?? 0 : localCorrect,
      'wrongAnswers':
      snapshot.exists ? snapshot['wrongAnswers'] ?? 0 : localWrong,
    }, SetOptions(merge: true));
  }

  // ================= Load User Data =================
  Future<void> _loadUserData() async {
    final user = _auth.currentUser;

    // ===== Guest =====
    if (user == null) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        displayName = "Guest Name";
        email = "guest@quiz-app.local";
        imageUrl = "";
        correct = prefs.getInt('correct') ?? 0;
        wrong = prefs.getInt('wrong') ?? 0;
        isLoading = false;
      });
      return;
    }

    // ===== Logged User =====
    email = user.email ?? email;
    imageUrl = user.photoURL ?? "";
    displayName = user.displayName ?? displayName;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();

      setState(() {
        if (doc.exists) {
          displayName = doc.data()?['displayName'] ?? displayName;
          correct = doc.data()?['correctAnswers'] ?? 0;
          wrong = doc.data()?['wrongAnswers'] ?? 0;
        }
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final bool isGuest = _auth.currentUser == null;

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
        child: Skeletonizer(
          enabled: isLoading,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // ================= Avatar =================
                CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.white,
                  backgroundImage:
                  imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                  child: imageUrl.isEmpty
                      ? const Icon(Icons.person,
                      size: 55, color: Colors.purple)
                      : null,
                ),

                const SizedBox(height: 12),

                // ================= Name =================
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                // ================= Email =================
                Text(
                  email,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                // ================= Guest Notice =================
                if (isGuest)
                  Container(
                    margin: const EdgeInsets.only(top: 14, bottom: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3)),
                    ),
                    child: const Text(
                      "هذه الإحصائيات محفوظة محليًا على الجهاز\nسجّل الدخول لحفظها على حسابك",
                      style: TextStyle(color: Colors.white, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),

                const SizedBox(height: 20),

                // ================= Statistics =================
                InkWell(
                  onTap: isGuest
                      ? () => Fluttertoast.showToast(
                    msg: "يجب تسجيل الدخول لمراجعة الإجابات",
                  )
                      : () => Navigator.push(
                    context,
                    AppRoute.fadeSlide(
                        ReviewQuestionsPage(showCorrect: true)),
                  ),
                  child: _buildStatCard(
                    title: "Correct Answers",
                    value: correct,
                    icon: Icons.check_circle,
                    color: Colors.greenAccent,
                  ),
                ),
                InkWell(
                  onTap: isGuest
                      ? () => Fluttertoast.showToast(
                    msg: "يجب تسجيل الدخول لمراجعة الإجابات",
                  )
                      : () => Navigator.push(
                    context,
                    AppRoute.fadeSlide(
                        ReviewQuestionsPage(showCorrect: false)),
                  ),
                  child: _buildStatCard(
                    title: "Wrong Answers",
                    value: wrong,
                    icon: Icons.cancel,
                    color: Colors.redAccent,
                  ),
                ),

                const SizedBox(height: 25),

                _statisticsButton(
                  onPressed: () => Navigator.push(
                    context,
                    AppRoute.fadeSlide(const StatisticsPage()),
                  ),
                ),

                const SizedBox(height: 25),

                // ================= Actions =================
                if (isGuest)
                  _buildGoogleButton(
                    text: "Google تسجيل الدخول باستخدام",
                    onTap: () async {
                      final user = await authService.signInWithGoogle();
                      if (user != null) {
                        setState(() => isLoading = true);
                        await saveGoogleUser(user);
                        await _loadUserData();
                      }
                    },
                  ),

                if (!isGuest)
                  _buildLogoutButton(
                    onTap: () => showDeleteConfirmDialog(context: context),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================= Widgets =================

  Widget _statisticsButton({required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 6,
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6A1B9A), Color(0xffC33764)],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bar_chart_rounded, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'لوحة المتصدرين',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton(
      {required String text, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("asset/images/google2.png", height: 22),
            const SizedBox(width: 12),
            Text(text,
                style:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton({required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Colors.white),
            SizedBox(width: 10),
            Text("تسجيل الخروج",
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 10,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title,
            style:
            const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        trailing: Text(
          value.toString(),
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }

  // ================= Logout Dialog =================
  Future<void> showDeleteConfirmDialog(
      {required BuildContext context}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2E2A50),
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('تسجيل خروج',
              style:
              TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text('هل أنت متأكد من تسجيل الخروج؟',
              style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child:
                const Text('إلغاء', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: () async {
                await authService.signOut();
                if (!mounted) return;
                setState(() => isLoading = true);
                await _loadUserData();
                if (!mounted) return;
                Navigator.pop(context);
              },
              style:
              ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child:
              const Text('نعم', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
