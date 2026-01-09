import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService authService = AuthService();

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

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;

    if (user == null) {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        email = "guest@quiz-app.local";
        imageUrl = "";
        correct = prefs.getInt('correct') ?? 0;
        wrong = prefs.getInt('wrong') ?? 0;
        isLoading = false;
      });
      return;
    }

    email = user.email ?? email;
    imageUrl = user.photoURL ?? "";

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();

      setState(() {
        correct = doc.exists ? (doc.data()?['correctAnswers'] ?? 0) : 0;
        wrong = doc.exists ? (doc.data()?['wrongAnswers'] ?? 0) : 0;
        isLoading = false;
      });
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

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
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    CircleAvatar(
                      radius: 55,
                      backgroundColor: Colors.white,
                      backgroundImage: imageUrl.isNotEmpty
                          ? NetworkImage(imageUrl)
                          : null,
                      child: imageUrl.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 55,
                              color: Colors.purple,
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      email,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isGuest)
                      Container(
                        margin: const EdgeInsets.only(top: 14, bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Expanded(
                              child: Text(
                                "هذه الإحصائيات محفوظة محليًا على الجهاز\nسجّل الدخول لحفظها على حسابك",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            SizedBox(width: 16),
                            Icon(
                              Icons.info_outline,
                              color: Colors.white,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    _buildStatCard(
                      title: "Correct Answers",
                      value: correct,
                      icon: Icons.check_circle,
                      color: Colors.greenAccent,
                      size: 15.5,
                    ),
                    _buildStatCard(
                      title: "Wrong Answers",
                      value: wrong,
                      icon: Icons.cancel,
                      color: Colors.redAccent,
                      size: 15.5,
                    ),
                    const SizedBox(height: 25),
                    if (isGuest)
                      _buildGoogleButton(
                        text: "Google تسجيل الدخول باستخدام",
                        onTap: () async {
                          final user = await authService.signInWithGoogle();
                          if (user != null) {
                            setState(() => isLoading = true);
                            await _loadUserData();
                          }
                        },
                      ),
                    if (!isGuest)
                      _buildLogoutButton(
                        onTap: () async {
                          showDeleteConfirmDialog(context: context);
                        },
                      ),
                  ],
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
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1A40),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
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
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> showDeleteConfirmDialog({required BuildContext context}) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2E2A50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              const SizedBox(width: 8),
              Text(
                'تسجيل خروج',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'هل أنت متأكد من تسجيل الخروج؟',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('إلغاء', style: const TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                await authService.signOut();
                setState(() => isLoading = true);
                await _loadUserData();
                Navigator.pop(context);
              },
              child: Text('نعم', style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
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
            Text(
              "تسجيل الخروج",
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int value,
    required double size,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 10,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 10,
        ),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: size),
        ),
        trailing: Text(
          value.toString(),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}
