import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exam/view/report_page.dart';
import 'package:exam/view/review_questions_page.dart';
import 'package:exam/view/statistics_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../core/class/route_transitions.dart';
import '../service/auth_service.dart';
import '../service/global_cognitive_analyzer.dart';
import '../service/report_history_service.dart';
import 'global_report_page.dart';

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

  // ================= Save Google User =================
  Future<void> saveGoogleUser(User user) async {
    final doc = _firestore.collection('users').doc(user.uid);
    final snapshot = await doc.get();

    final prefs = await SharedPreferences.getInstance();
    final localCorrect = prefs.getInt('correct') ?? 0;
    final localWrong = prefs.getInt('wrong') ?? 0;

    await doc.set({
      'displayName': user.displayName,
      'photoURL': user.photoURL,
      'correctAnswers': snapshot.exists
          ? snapshot['correctAnswers'] ?? 0
          : localCorrect,
      'wrongAnswers': snapshot.exists
          ? snapshot['wrongAnswers'] ?? 0
          : localWrong,
    }, SetOptions(merge: true));
  }

  // ================= Load User Data =================
  Future<void> _loadUserData() async {
    final user = _auth.currentUser;

    // ===== Guest =====
    if (user == null) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        displayName = "زائر التطبيق";
        email = "مستخدم ضيف";
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
          child: Skeletonizer(
            enabled: isLoading,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // ================= Avatar =================
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                          blurRadius: 18,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: const Color(0xFF1E163B),
                      backgroundImage: imageUrl.isNotEmpty
                          ? NetworkImage(imageUrl)
                          : null,
                      child: imageUrl.isEmpty
                          ? const Icon(
                              Icons.person_rounded,
                              size: 48,
                              color: Color(0xFFA78BFA),
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ================= Name =================
                  Text(
                    displayName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 21,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // ================= Email =================
                  Text(
                    email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white60,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  // ================= Guest Notice =================
                  if (isGuest)
                    Container(
                      margin: const EdgeInsets.only(top: 14),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Text(
                        "هذه الإحصائيات محفوظة محليًا على الجهاز\nسجّل الدخول لحفظها على حسابك",
                        style: TextStyle(color: Colors.amberAccent, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  const SizedBox(height: 22),

                  // ================= Stat Cards =================
                  InkWell(
                    onTap: isGuest
                        ? () => Fluttertoast.showToast(
                              msg: "يجب تسجيل الدخول لمراجعة الإجابات",
                            )
                        : () => Navigator.push(
                              context,
                              AppRoute.fadeSlide(
                                ReviewQuestionsPage(showCorrect: true),
                              ),
                            ),
                    borderRadius: BorderRadius.circular(20),
                    child: _buildGlassStatCard(
                      title: "إجابات صحيحة",
                      value: correct,
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF10B981),
                    ),
                  ),

                  const SizedBox(height: 12),

                  InkWell(
                    onTap: isGuest
                        ? () => Fluttertoast.showToast(
                              msg: "يجب تسجيل الدخول لمراجعة الإجابات",
                            )
                        : () => Navigator.push(
                              context,
                              AppRoute.fadeSlide(
                                ReviewQuestionsPage(showCorrect: false),
                              ),
                            ),
                    borderRadius: BorderRadius.circular(20),
                    child: _buildGlassStatCard(
                      title: "إجابات خاطئة",
                      value: wrong,
                      icon: Icons.cancel_rounded,
                      color: const Color(0xFFEF4444),
                    ),
                  ), 

                  const SizedBox(height: 24),

                  // ================= Navigation Action Buttons =================
                  _gradientActionButton(
                    icon: Icons.bar_chart_rounded,
                    title: "لوحة المتصدرين",
                    gradient: const [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
                    onPressed: () => Navigator.push(
                      context,
                      AppRoute.fadeSlide(const StatisticsPage()),
                    ),
                  ),

                  const SizedBox(height: 14),

                  _gradientActionButton(
                    icon: Icons.psychology_rounded,
                    title: "آخر تقرير معرفي",
                    gradient: const [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                    onPressed: () => isGuest
                        ? Fluttertoast.showToast(
                            msg: "يجب تسجيل الدخول لتظهر التقارير",
                          )
                        : Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LastAnalysisPage(),
                            ),
                          ),
                  ),

                  const SizedBox(height: 14),

                  _gradientActionButton(
                    icon: Icons.auto_graph_rounded,
                    title: "التقرير المعرفي الشامل",
                    gradient: const [Color(0xFF2563EB), Color(0xFF8B5CF6)],
                    onPressed: () {
                      if (isGuest) {
                        Fluttertoast.showToast(
                          msg: "يجب تسجيل الدخول لتظهر التقارير",
                        );
                      } else {
                        final reports = ReportHistoryService.getAllReports();
                        final _ = GlobalCognitiveAnalyzer.analyzeAll(reports);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GlobalReportPage(),
                          ),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  // ================= Auth Action =================
                  if (isGuest)
                    _buildGoogleButton(
                      text: "تسجيل الدخول باستخدام Google",
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

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= Widgets =================

  Widget _buildGlassStatCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E163B).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradientActionButton({
    required String title,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradient),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          icon: Icon(icon, color: Colors.white, size: 22),
          label: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
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
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("asset/images/google2.png", height: 22),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton({required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(
              "تسجيل الخروج",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= Logout Dialog =================
  Future<void> showDeleteConfirmDialog({required BuildContext context}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B1537),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.logout_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text(
                'تسجيل خروج',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: const Text(
            'هل أنت متأكد من تسجيل الخروج؟',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final nav = Navigator.of(context);
                await authService.signOut();
                if (!mounted) return;
                setState(() => isLoading = true);
                await _loadUserData();
                if (!mounted) return;
                nav.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('نعم', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
