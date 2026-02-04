import '../model/answer_log.dart';
import '../model/cognitive_report.dart';

class CognitiveAnalyzer {
  static CognitiveReport analyze(List<AnswerLog> logs) {
    int total = logs.length;
    int correct = logs.where((e) => e.isCorrect).length;
    int wrong = total - correct;

    double accuracy = total == 0 ? 0 : (correct / total) * 100;

    // ===== تحليل حسب الفئة =====
    Map<String, List<AnswerLog>> byCategory = {};
    for (var log in logs) {
      byCategory.putIfAbsent(log.category, () => []);
      byCategory[log.category]!.add(log);
    }

    Map<String, double> weakness = {};
    Map<String, double> strength = {};

    byCategory.forEach((cat, list) {
      int wrongCount = list.where((e) => !e.isCorrect).length;
      int correctCount = list.length - wrongCount;

      double wrongRate = list.isEmpty ? 0 : (wrongCount / list.length) * 100;
      double correctRate = list.isEmpty ? 0 : (correctCount / list.length) * 100;

      weakness[cat] = wrongRate;
      strength[cat] = correctRate;
    });

    // ===== تحليل اتجاه الأداء (بداية / نهاية) =====
    int mid = total ~/ 2;

    int firstHalfCorrect =
        logs.sublist(0, mid).where((e) => e.isCorrect).length;

    int secondHalfCorrect =
        logs.sublist(mid).where((e) => e.isCorrect).length;

    String trend;
    if (secondHalfCorrect < firstHalfCorrect) {
      trend = "انخفاض في الأداء مع التقدم في الاختبار، قد يدل على تعب أو تشتت.";
    } else if (secondHalfCorrect > firstHalfCorrect) {
      trend = "تحسن في الأداء مع التقدم في الاختبار، يدل على تأقلم وتركيز أفضل.";
    } else {
      trend = "أداء ثابت طوال الاختبار، يدل على مستوى تركيز مستقر.";
    }

    // ===== تحليل الثبات (Stability Index) =====
    int longestCorrectStreak = 0;
    int currentStreak = 0;

    for (var log in logs) {
      if (log.isCorrect) {
        currentStreak++;
        if (currentStreak > longestCorrectStreak) {
          longestCorrectStreak = currentStreak;
        }
      } else {
        currentStreak = 0;
      }
    }

    String stability;
    if (longestCorrectStreak >= 5) {
      stability = "ثبات عالي في الأداء (سلسلة نجاح طويلة)";
    } else if (longestCorrectStreak >= 3) {
      stability = "ثبات متوسط في الأداء";
    } else {
      stability = "أداء متذبذب مع قلة الاستمرارية";
    }

    // ===== تحليل التركيز (Focus Index) =====
    int switches = 0;
    for (int i = 1; i < logs.length; i++) {
      if (logs[i].isCorrect != logs[i - 1].isCorrect) {
        switches++;
      }
    }

    double focusScore = total <= 1 ? 100 : 100 - (switches / total) * 100;

    String focusAnalysis;
    if (focusScore >= 80) {
      focusAnalysis = "تركيز عالي وثبات ذهني ممتاز أثناء الحل.";
    } else if (focusScore >= 60) {
      focusAnalysis = "تركيز جيد مع بعض التذبذب أثناء الاختبار.";
    } else {
      focusAnalysis = "يوجد تشتت واضح وتغيّر متكرر في مستوى الأداء.";
    }

    // ===== إنشاء بيانات منحنى الأداء =====
    List<bool> flow = logs.map((e) => e.isCorrect).toList();

    // ===== توصيات تعليمية ذكية =====
    List<String> recommendations = [];

    if (accuracy < 60) {
      recommendations.add("ننصح بإعادة مراجعة أساسيات الفئات الضعيفة قبل المحاولة القادمة.");
    }

    if (focusScore < 60) {
      recommendations.add("حاول تقليل المشتتات وزيادة التركيز أثناء أداء الاختبارات.");
    }

    if (secondHalfCorrect < firstHalfCorrect) {
      recommendations.add("يفضل أخذ فترات راحة قصيرة لتجنب الإرهاق الذهني أثناء الاختبارات الطويلة.");
    }

    if (recommendations.isEmpty) {
      recommendations.add("أداء ممتاز! استمر بنفس الأسلوب وواصل التدريب.");
    }

    // ===== النص التحليلي النهائي =====
    String summary =
        "تم حل $total سؤال بنسبة دقة عامة ${accuracy.toStringAsFixed(1)}%. "
        "$trend\n\n"
        "تحليل الثبات: $stability.\n"
        "تحليل التركيز: $focusAnalysis.\n\n"
        "التوصيات:\n- ${recommendations.join("\n- ")}";

    return CognitiveReport(
      totalCorrect: correct,
      totalWrong: wrong,
      accuracy: accuracy,
      categoryWeakness: weakness,
      performanceTrend: trend,
      summary: summary,
      answersFlow: flow,
    );
  }
}
