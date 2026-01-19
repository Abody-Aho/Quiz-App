class AnswerLog {
  final int questionIndex;
  final bool isCorrect;
  final String category;

  AnswerLog({
    required this.questionIndex,
    required this.isCorrect,
    required this.category,
  });

  Map<String, dynamic> toJson() => {
    'questionIndex': questionIndex,
    'isCorrect': isCorrect,
    'category': category,
  };

  factory AnswerLog.fromJson(Map<String, dynamic> json) {
    return AnswerLog(
      questionIndex: json['questionIndex'],
      isCorrect: json['isCorrect'],
      category: json['category'],
    );
  }
}
