import '../model/cognitive_report.dart';

class GlobalCognitiveAnalyzer {
  static CognitiveReport analyzeAll(List<CognitiveReport> reports) {
    int totalCorrect = 0;
    int totalWrong = 0;

    Map<String, double> categorySum = {};
    Map<String, int> categoryCount = {};

    List<bool> globalFlow = [];

    for (var r in reports) {
      totalCorrect += r.totalCorrect;
      totalWrong += r.totalWrong;

      // دمج تدفق الإجابات
      globalFlow.addAll(r.answersFlow);

      // دمج ضعف الفئات
      r.categoryWeakness.forEach((cat, value) {
        categorySum[cat] = (categorySum[cat] ?? 0) + value;
        categoryCount[cat] = (categoryCount[cat] ?? 0) + 1;
      });
    }

    double accuracy = (totalCorrect + totalWrong) == 0
        ? 0
        : (totalCorrect / (totalCorrect + totalWrong)) * 100;

    // متوسط الضعف حسب الفئة
    Map<String, double> weakness = {};
    categorySum.forEach((cat, sum) {
      weakness[cat] = sum / categoryCount[cat]!;
    });

    // تحليل اتجاه عام
    String trend;
    if (accuracy >= 80) {
      trend = "أداء ممتاز ومستقر عبر جميع الاختبارات";
    } else if (accuracy >= 60) {
      trend = "أداء جيد مع وجود تذبذب في بعض الجلسات";
    } else {
      trend = "يظهر ضعف عام في الأداء عبر معظم الاختبارات";
    }

    String summary =
        "تم تحليل ${reports.length} اختبار. "
        "نسبة الدقة العامة ${accuracy.toStringAsFixed(1)}%. "
        "$trend.";

    return CognitiveReport(
      totalCorrect: totalCorrect,
      totalWrong: totalWrong,
      accuracy: accuracy,
      categoryWeakness: weakness,
      performanceTrend: trend,
      summary: summary,
      answersFlow: globalFlow,   // 🔥 منحنى تراكمي لكل الاختبارات
    );
  }
}
