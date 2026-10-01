import '../model/answer_log.dart';
import '../model/cognitive_report.dart';

class CognitiveAnalyzer {
  static CognitiveReport analyze(List<AnswerLog> logs, {String langCode = 'ar'}) {
    int total = logs.length;
    int correct = logs.where((e) => e.isCorrect).length;
    int wrong = total - correct;

    double accuracy = total == 0 ? 0 : (correct / total) * 100;

    // ===== Category Weakness & Strength =====
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

    // ===== Trend Analysis (Start / End) =====
    int mid = total ~/ 2;

    int firstHalfCorrect =
        logs.sublist(0, mid).where((e) => e.isCorrect).length;

    int secondHalfCorrect =
        logs.sublist(mid).where((e) => e.isCorrect).length;

    String trend;
    if (langCode == 'en') {
      if (secondHalfCorrect < firstHalfCorrect) {
        trend = "Performance declined as the test progressed, indicating possible fatigue or distraction.";
      } else if (secondHalfCorrect > firstHalfCorrect) {
        trend = "Performance improved as the test progressed, showing better adaptation and focus.";
      } else {
        trend = "Consistent performance throughout the test, indicating a stable level of focus.";
      }
    } else if (langCode == 'es') {
      if (secondHalfCorrect < firstHalfCorrect) {
        trend = "Disminución del rendimiento a medida que avanzaba la prueba, lo que indica posible fatiga o distracción.";
      } else if (secondHalfCorrect > firstHalfCorrect) {
        trend = "Mejora del rendimiento a medida que avanzaba la prueba, mostrando mejor adaptación y enfoque.";
      } else {
        trend = "Rendimiento constante a lo largo de la prueba, lo que indica un nivel de enfoque estable.";
      }
    } else {
      if (secondHalfCorrect < firstHalfCorrect) {
        trend = "انخفاض في الأداء مع التقدم في الاختبار، قد يدل على تعب أو تشتت.";
      } else if (secondHalfCorrect > firstHalfCorrect) {
        trend = "تحسن في الأداء مع التقدم في الاختبار، يدل على تأقلم وتركيز أفضل.";
      } else {
        trend = "أداء ثابت طوال الاختبار، يدل على مستوى تركيز مستقر.";
      }
    }

    // ===== Stability Index =====
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
    if (langCode == 'en') {
      if (longestCorrectStreak >= 5) {
        stability = "High performance stability (long streak of correct answers)";
      } else if (longestCorrectStreak >= 3) {
        stability = "Moderate performance stability";
      } else {
        stability = "Fluctuating performance with low consistency";
      }
    } else if (langCode == 'es') {
      if (longestCorrectStreak >= 5) {
        stability = "Alta estabilidad de rendimiento (larga racha de respuestas correctas)";
      } else if (longestCorrectStreak >= 3) {
        stability = "Estabilidad de rendimiento moderada";
      } else {
        stability = "Rendimiento fluctuante con baja consistencia";
      }
    } else {
      if (longestCorrectStreak >= 5) {
        stability = "ثبات عالي في الأداء (سلسلة نجاح طويلة)";
      } else if (longestCorrectStreak >= 3) {
        stability = "ثبات متوسط في الأداء";
      } else {
        stability = "أداء متذبذب مع قلة الاستمرارية";
      }
    }

    // ===== Focus Index =====
    int switches = 0;
    for (int i = 1; i < logs.length; i++) {
      if (logs[i].isCorrect != logs[i - 1].isCorrect) {
        switches++;
      }
    }

    double focusScore = total <= 1 ? 100 : 100 - (switches / total) * 100;

    String focusAnalysis;
    if (langCode == 'en') {
      if (focusScore >= 80) {
        focusAnalysis = "High focus and excellent mental stability during the quiz.";
      } else if (focusScore >= 60) {
        focusAnalysis = "Good focus with slight fluctuation during the test.";
      } else {
        focusAnalysis = "Clear distraction and frequent changes in performance level.";
      }
    } else if (langCode == 'es') {
      if (focusScore >= 80) {
        focusAnalysis = "Alto enfoque y excelente estabilidad mental durante la prueba.";
      } else if (focusScore >= 60) {
        focusAnalysis = "Buen enfoque con alguna fluctuación durante la prueba.";
      } else {
        focusAnalysis = "Distracción clara y cambios frecuentes en el nivel de rendimiento.";
      }
    } else {
      if (focusScore >= 80) {
        focusAnalysis = "تركيز عالي وثبات ذهني ممتاز أثناء الحل.";
      } else if (focusScore >= 60) {
        focusAnalysis = "تركيز جيد مع بعض التذبذب أثناء الاختبار.";
      } else {
        focusAnalysis = "يوجد تشتت واضح وتغيّر متكرر في مستوى الأداء.";
      }
    }

    // ===== Answers Flow =====
    List<bool> flow = logs.map((e) => e.isCorrect).toList();

    // ===== Recommendations =====
    List<String> recommendations = [];

    if (langCode == 'en') {
      if (accuracy < 60) {
        recommendations.add("We recommend reviewing the fundamentals of weak categories before your next attempt.");
      }
      if (focusScore < 60) {
        recommendations.add("Try to minimize distractions and increase focus while taking quizzes.");
      }
      if (secondHalfCorrect < firstHalfCorrect) {
        recommendations.add("Taking short breaks is recommended to avoid mental fatigue during longer tests.");
      }
      if (recommendations.isEmpty) {
        recommendations.add("Excellent performance! Keep up the great work and continue practicing.");
      }
    } else if (langCode == 'es') {
      if (accuracy < 60) {
        recommendations.add("Recomendamos revisar los fundamentos de las categorías débiles antes del próximo intento.");
      }
      if (focusScore < 60) {
        recommendations.add("Intenta minimizar las distracciones y aumentar el enfoque al realizar los exámenes.");
      }
      if (secondHalfCorrect < firstHalfCorrect) {
        recommendations.add("Se recomiendan breves descansos para evitar la fatiga mental durante los exámenes largos.");
      }
      if (recommendations.isEmpty) {
        recommendations.add("¡Rendimiento excelente! Sigue con el gran trabajo y continúa practicando.");
      }
    } else {
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
    }

    // ===== Final Summary =====
    String summary;
    if (langCode == 'en') {
      summary =
          "Answered $total questions with an overall accuracy rate of ${accuracy.toStringAsFixed(1)}%. "
          "$trend\n\n"
          "Stability Analysis: $stability.\n"
          "Focus Analysis: $focusAnalysis.\n\n"
          "Recommendations:\n- ${recommendations.join("\n- ")}";
    } else if (langCode == 'es') {
      summary =
          "Respondió $total preguntas con una tasa de precisión general de ${accuracy.toStringAsFixed(1)}%. "
          "$trend\n\n"
          "Análisis de Estabilidad: $stability.\n"
          "Análisis de Enfoque: $focusAnalysis.\n\n"
          "Recomendaciones:\n- ${recommendations.join("\n- ")}";
    } else {
      summary =
          "تم حل $total سؤال بنسبة دقة عامة ${accuracy.toStringAsFixed(1)}%. "
          "$trend\n\n"
          "تحليل الثبات: $stability.\n"
          "تحليل التركيز: $focusAnalysis.\n\n"
          "التوصيات:\n- ${recommendations.join("\n- ")}";
    }

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
