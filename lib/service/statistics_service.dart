import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatisticsService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveResult({
    required int correct,
    required int wrong,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      final prefs = await SharedPreferences.getInstance();
      prefs.setInt('correct', (prefs.getInt('correct') ?? 0) + correct);
      prefs.setInt('wrong', (prefs.getInt('wrong') ?? 0) + wrong);
    } else {
      final ref = _firestore.collection('users').doc(user.uid);
      await ref.set({
        'correctAnswers': FieldValue.increment(correct),
        'wrongAnswers': FieldValue.increment(wrong),
      }, SetOptions(merge: true));
    }
  }

}
