import '../model/cognitive_report.dart';

class GlobalCognitiveAnalyzer {
  static CognitiveReport analyzeAll(
    List<CognitiveReport> reports, {
    String langCode = 'ar',
  }) {
    int totalCorrect = 0;
    int totalWrong = 0;

    Map<String, double> categorySum = {};
    Map<String, int> categoryCount = {};

    List<bool> globalFlow = [];

    for (var r in reports) {
      totalCorrect += r.totalCorrect;
      totalWrong += r.totalWrong;

      // Merge answers flow
      globalFlow.addAll(r.answersFlow);

      // Merge category weakness
      r.categoryWeakness.forEach((cat, value) {
        categorySum[cat] = (categorySum[cat] ?? 0) + value;
        categoryCount[cat] = (categoryCount[cat] ?? 0) + 1;
      });
    }

    double accuracy = (totalCorrect + totalWrong) == 0
        ? 0
        : (totalCorrect / (totalCorrect + totalWrong)) * 100;

    // Average weakness per category
    Map<String, double> weakness = {};
    categorySum.forEach((cat, sum) {
      weakness[cat] = sum / categoryCount[cat]!;
    });

    // Multi-language Performance Trend Analysis
    String trend;
    if (langCode == 'en') {
      if (accuracy >= 80) {
        trend = "Excellent and stable performance across all quizzes";
      } else if (accuracy >= 60) {
        trend = "Good performance with slight variation across some sessions";
      } else {
        trend = "Shows general performance weakness across most quizzes";
      }
    } else if (langCode == 'es') {
      if (accuracy >= 80) {
        trend = "Rendimiento excelente y estable en todas las pruebas";
      } else if (accuracy >= 60) {
        trend = "Buen rendimiento con ligera variación en algunas sesiones";
      } else {
        trend = "Muestra debilidad general de rendimiento en la mayoría de las pruebas";
      }
    } else {
      if (accuracy >= 80) {
        trend = "أداء ممتاز ومستقر عبر جميع الاختبارات";
      } else if (accuracy >= 60) {
        trend = "أداء جيد مع وجود تذبذب في بعض الجلسات";
      } else {
        trend = "يظهر ضعف عام في الأداء عبر معظم الاختبارات";
      }
    }

    // Multi-language Summary
    String summary;
    if (langCode == 'en') {
      summary =
          "Analyzed ${reports.length} quizzes. "
          "Overall accuracy rate: ${accuracy.toStringAsFixed(1)}%. "
          "$trend.";
    } else if (langCode == 'es') {
      summary =
          "Analizados ${reports.length} exámenes. "
          "Tasa de precisión general: ${accuracy.toStringAsFixed(1)}%. "
          "$trend.";
    } else {
      summary =
          "تم تحليل ${reports.length} اختبار. "
          "نسبة الدقة العامة ${accuracy.toStringAsFixed(1)}%. "
          "$trend.";
    }

    return CognitiveReport(
      totalCorrect: totalCorrect,
      totalWrong: totalWrong,
      accuracy: accuracy,
      categoryWeakness: weakness,
      performanceTrend: trend,
      summary: summary,
      answersFlow: globalFlow,
    );
  }
}
