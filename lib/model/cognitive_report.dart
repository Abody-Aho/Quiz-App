class CognitiveReport {
  final int totalCorrect;
  final int totalWrong;
  final double accuracy;
  final Map<String, double> categoryWeakness;
  final String performanceTrend;
  final String summary;

  final List<bool> answersFlow;

  CognitiveReport({
    required this.totalCorrect,
    required this.totalWrong,
    required this.accuracy,
    required this.categoryWeakness,
    required this.performanceTrend,
    required this.summary,
    required this.answersFlow,
  });

  Map<String, dynamic> toMap() {
    return {
      'totalCorrect': totalCorrect,
      'totalWrong': totalWrong,
      'accuracy': accuracy,
      'categoryWeakness': categoryWeakness,
      'performanceTrend': performanceTrend,
      'summary': summary,
      'answersFlow': answersFlow,
    };
  }

  factory CognitiveReport.fromMap(Map<String, dynamic> map) {
    return CognitiveReport(
      totalCorrect: map['totalCorrect'] ?? 0,
      totalWrong: map['totalWrong'] ?? 0,
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0,
      categoryWeakness:
      Map<String, double>.from(map['categoryWeakness'] ?? {}),
      performanceTrend: map['performanceTrend'] ?? '',
      summary: map['summary'] ?? '',
      answersFlow: List<bool>.from(map['answersFlow'] ?? []),
    );
  }
}

