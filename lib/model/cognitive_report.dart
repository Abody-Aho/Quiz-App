class CognitiveReport {
  final int totalCorrect;
  final int totalWrong;
  final double accuracy;
  final Map<String, double> categoryWeakness;
  final String performanceTrend;
  final String summary;

  // 👇 جديد لرسم منحنى الأداء
  final List<bool> answersFlow;

  CognitiveReport({
    required this.totalCorrect,
    required this.totalWrong,
    required this.accuracy,
    required this.categoryWeakness,
    required this.performanceTrend,
    required this.summary,
    required this.answersFlow,   // 👈 جديد
  });
}
