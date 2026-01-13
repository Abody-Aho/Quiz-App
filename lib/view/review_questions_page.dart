import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../widget/review_question_card.dart';

class ReviewQuestionsPage extends StatelessWidget {
  final bool showCorrect;
  const ReviewQuestionsPage({super.key, required this.showCorrect});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text("يجب تسجيل الدخول عبر Google"),
        ),
      );
    }

    return Scaffold(
      // ================= AppBar =================
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Text(
          showCorrect ? "الإجابات الصحيحة" : "الإجابات الخاطئة",
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: Colors.white
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF6A1B9A),
                Color(0xFF8E24AA),
                Color(0xFFC33764),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // ================= Background =================
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF3E5F5),
              Color(0xFFEDE7F6),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('answered_questions')
              .where('isCorrect', isEqualTo: showCorrect)
              .orderBy('createdAt', descending: true)
              .snapshots(),

          builder: (context, snapshot) {
            // ================= Error =================
            if (snapshot.hasError) {
              return Center(
                child: Card(
                  color: Colors.red.shade50,
                  margin: const EdgeInsets.all(24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.error_outline,
                            size: 50, color: Colors.redAccent),
                        SizedBox(height: 12),
                        Text(
                          "حدث خطأ في تحميل البيانات",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            // ================= Loading =================
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF6A1B9A),
                ),
              );
            }

            final docs = snapshot.data!.docs;

            // ================= Empty State =================
            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      showCorrect
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                      size: 70,
                      color: Colors.purple.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      showCorrect
                          ? "لا توجد إجابات صحيحة محفوظة"
                          : "لا توجد إجابات خاطئة محفوظة",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "ابدأ اختبارًا جديدًا وستظهر هنا",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              );
            }

            // ================= List =================
            return ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                return ReviewQuestionCard(data: docs[index]);
              },
            );
          },
        ),
      ),
    );
  }
}
