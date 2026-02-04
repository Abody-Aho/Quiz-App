import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/cognitive_report.dart';

class CloudReportService {
  static Future<void> saveReport(CognitiveReport report) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cognitive_reports')
        .add({
      'totalCorrect': report.totalCorrect,
      'totalWrong': report.totalWrong,
      'accuracy': report.accuracy,
      'categoryWeakness': report.categoryWeakness,
      'performanceTrend': report.performanceTrend,
      'summary': report.summary,
      'answersFlow': report.answersFlow,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // جلب كل التقارير من السحابة
  static Future<List<CognitiveReport>> getAllReports() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('cognitive_reports')
        .orderBy('createdAt')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return CognitiveReport(
        totalCorrect: data['totalCorrect'],
        totalWrong: data['totalWrong'],
        accuracy: (data['accuracy'] as num).toDouble(),
        categoryWeakness:
        Map<String, double>.from(data['categoryWeakness']),
        performanceTrend: data['performanceTrend'],
        summary: data['summary'],
        answersFlow: List<bool>.from(data['answersFlow']),
      );
    }).toList();
  }
}
