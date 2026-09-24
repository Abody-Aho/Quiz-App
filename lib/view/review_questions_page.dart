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
        backgroundColor: Color(0xFF0F0C20),
        body: Center(
          child: Text(
            "يجب تسجيل الدخول عبر Google لمراجعة الإجابات",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      );
    }

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
            children: [
              // Custom Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            showCorrect
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            color: showCorrect
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            showCorrect
                                ? "الإجابات الصحيحة"
                                : "الإجابات الخاطئة",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 42),
                  ],
                ),
              ),

              // Firestore List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid)
                      .collection('answered_questions')
                      .where('isCorrect', isEqualTo: showCorrect)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    // Error
                    if (snapshot.hasError) {
                      return Center(
                        child: Container(
                          padding: const EdgeInsets.all(22),
                          margin: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 50,
                                color: Color(0xFFEF4444),
                              ),
                              SizedBox(height: 12),
                              Text(
                                "حدث خطأ في تحميل البيانات",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Loading
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF8B5CF6),
                        ),
                      );
                    }

                    final docs = snapshot.data!.docs;

                    // Empty State
                    if (docs.isEmpty) {
                      return Center(
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          margin: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                showCorrect
                                    ? Icons.check_circle_outline_rounded
                                    : Icons.cancel_outlined,
                                size: 64,
                                color: showCorrect
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                showCorrect
                                    ? "لا توجد إجابات صحيحة محفوظة"
                                    : "لا توجد إجابات خاطئة محفوظة",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "ابدأ اختبارًا جديدًا وستظهر الإجابات هنا",
                                style: TextStyle(color: Colors.white60),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Question Cards List
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        return ReviewQuestionCard(data: docs[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
