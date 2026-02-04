import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/cognitive_report.dart';

class CloudLastAnalysisService {
  static Future<void> saveLastAnalysis(CognitiveReport report) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('last_analysis')
        .doc('current')
        .set({
      ...report.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    print(" تم حفظ تحليل آخر اختبار");
  }

  static Future<CognitiveReport?> getLastAnalysis() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('last_analysis')
        .doc('current')
        .get();

    if (!doc.exists) return null;

    return CognitiveReport.fromMap(doc.data()!);
  }
}
