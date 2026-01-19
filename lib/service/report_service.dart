import '../model/cognitive_report.dart';

class ReportService {
  static CognitiveReport? _lastReport;

  static void saveReport(CognitiveReport report) {
    _lastReport = report;
  }

  static CognitiveReport? getLastReport() {
    return _lastReport;
  }

  static bool hasReport() {
    return _lastReport != null;
  }
}
