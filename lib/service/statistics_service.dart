import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatisticsService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===================== حفظ النتيجة النهائية =====================
  Future<void> saveResult({
    required int correct,
    required int wrong,
  }) async {
    final user = _auth.currentUser;

    // Guest
    if (user == null) {
      final prefs = await SharedPreferences.getInstance();
      prefs.setInt('correct', (prefs.getInt('correct') ?? 0) + correct);
      prefs.setInt('wrong', (prefs.getInt('wrong') ?? 0) + wrong);
    }
    // Logged User
    else {
      final ref = _firestore.collection('users').doc(user.uid);
      await ref.set({
        'correctAnswers': FieldValue.increment(correct),
        'wrongAnswers': FieldValue.increment(wrong),
      }, SetOptions(merge: true));
    }
  }

  // ===================== 🔥 التعديل هنا بالضبط 🔥 =====================
  // حفظ كل إجابة فورًا (حتى لو خرج من الاختبار)
  Future<void> saveSingleAnswer({
    required bool isCorrect,
  }) async {
    final user = _auth.currentUser;

    // ===== Guest (محلي) =====
    final prefs = await SharedPreferences.getInstance();
    if (isCorrect) {
      prefs.setInt(
        'correct',
        (prefs.getInt('correct') ?? 0) + 1,
      );
    } else {
      prefs.setInt(
        'wrong',
        (prefs.getInt('wrong') ?? 0) + 1,
      );
    }

    // ===== Logged User (Firebase) =====
    if (user != null) {
      final ref = _firestore.collection('users').doc(user.uid);
      await ref.update({
        isCorrect
            ? 'correctAnswers'
            : 'wrongAnswers': FieldValue.increment(1),
      });
    }
  }
}
