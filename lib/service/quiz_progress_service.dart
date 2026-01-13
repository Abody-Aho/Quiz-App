import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuizProgressService {

  /// ================= Save Progress =================
  static Future<void> saveProgress({
    required int score,
    required int questionNumber,
  }) async {

    // ===== Local Save =====
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('quiz_score', score);
    await prefs.setInt('quiz_question', questionNumber);

    // ===== Firebase Save =====
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'currentQuiz': {
          'score': score,
          'questionNumber': questionNumber,
          'updatedAt': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));
    }
  }

  /// ================= Clear Progress =================
  static Future<void> clearProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('quiz_score');
    await prefs.remove('quiz_question');
  }
}
