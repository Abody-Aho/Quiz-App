import '../model/cognitive_report.dart';

class ReportHistoryService {
  static final List<CognitiveReport> _history = [];

  // إضافة تقرير جديد بعد كل اختبار
  static void addReport(CognitiveReport report) {
    _history.add(report);
  }

  // جلب كل التقارير
  static List<CognitiveReport> getAllReports() {
    return List.from(_history);
  }

  // هل يوجد تقارير محفوظة؟
  static bool hasReports() {
    return _history.isNotEmpty;
  }

  // مسح السجل (اختياري)
  static void clear() {
    _history.clear();
  }
}
