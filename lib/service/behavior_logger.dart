import '../model/answer_log.dart';

class BehaviorLogger {
  static final List<AnswerLog> _sessionLogs = [];

  static void startSession() {
    _sessionLogs.clear();
  }

  static void logAnswer({
    required int questionIndex,
    required bool isCorrect,
    required String category,
  }) {
    _sessionLogs.add(
      AnswerLog(
        questionIndex: questionIndex,
        isCorrect: isCorrect,
        category: category,
      ),
    );
  }

  static List<AnswerLog> getSessionLogs() {
    return List.from(_sessionLogs);
  }
}
