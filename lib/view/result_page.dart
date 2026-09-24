import 'package:confetti/confetti.dart'
    show ConfettiController, ConfettiWidget, BlastDirectionality;
import 'package:exam/view/category_page.dart';
import 'package:exam/view/report_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../core/class/route_transitions.dart';
import '../service/cloud_last_analysis_service.dart';
import '../service/cloud_report_service.dart';
import '../service/cognitive_analyzer.dart';
import '../model/cognitive_report.dart';
import '../service/behavior_logger.dart';
import '../service/quiz_progress_service.dart';
import '../service/report_history_service.dart';
import '../service/report_service.dart';
import '../service/statistics_service.dart';

// ================= Result Page =================
class ResultPage extends StatefulWidget {
  final int score;
  final int total;

  const ResultPage({super.key, required this.score, required this.total});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  // ================= Controllers =================
  late ConfettiController _confettiController;
  CognitiveReport? cognitiveReport;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _initResult();
    // Confetti
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 4),
    );
    _confettiController.play();
  }

  Future<void> _initResult() async {
    if (_saved) return;
    _saved = true;

    try {
      // Save Final Statistics
      final statisticsService = StatisticsService();
      await statisticsService.saveResult(
        correct: widget.score,
        wrong: (widget.total - widget.score).clamp(0, widget.total),
      );

      await QuizProgressService.clearProgress();

      // Cognitive Analysis
      final logs = BehaviorLogger.getSessionLogs();
      final report = CognitiveAnalyzer.analyze(
        logs.isNotEmpty ? logs : [],
      );
      cognitiveReport = report;

      await CloudLastAnalysisService.saveLastAnalysis(report);

      // Save Reports
      ReportService.saveReport(report);
      ReportHistoryService.addReport(report);
      await CloudReportService.saveReport(report);
    } catch (_) {}
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  // ================= Helpers =================
  double get percentage =>
      widget.total > 0 ? (widget.score / widget.total) * 100 : 0;

  String getScoreTitle() {
    if (percentage == 100) return "نتيجة ممتازة! 🎉";
    if (percentage >= 70) return "أداء ممتاز! 👏";
    if (percentage >= 50) return "أداء جيد 🙂";
    return "حاول مرة أخرى 💡";
  }

  String getScoreSubtitle() {
    if (percentage >= 80) return "أحسنت! لديك معرفة جيدة جداً بالمعلومات.";
    if (percentage >= 50) return "نتيجة طيبة، مع بعض المراجعة ستصبح أفضل!";
    return "لا تقلق، تكرار الاختبار يساعدك على التعلم والتحسن بسرعة.";
  }

  Color getScoreColor() {
    if (percentage >= 80) return const Color(0xFF10B981); // Green
    if (percentage >= 60) return const Color(0xFFF59E0B); // Amber
    if (percentage >= 40) return const Color(0xFFF97316); // Orange
    return const Color(0xFFEF4444); // Red
  }

  void _navigateToCategories() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        AppRoute.fadeSlide(const CategoryPage()),
      );
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final bool isGuest = _auth.currentUser == null;
    final Color mainColor = getScoreColor();
    final int wrongCount = (widget.total - widget.score).clamp(0, widget.total);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _navigateToCategories();
      },
      child: Scaffold(
        body: Stack(
          alignment: Alignment.topCenter,
          children: [
            // ================= Background =================
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0F0C20),
                    Color(0xFF1E1035),
                    Color(0xFF2A0845),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                    child: Container(
                      padding: const EdgeInsets.all(26),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E163B).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Trophy Badge
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: mainColor.withValues(alpha: 0.15),
                              border: Border.all(
                                color: mainColor.withValues(alpha: 0.4),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: mainColor.withValues(alpha: 0.3),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              percentage >= 50
                                  ? Icons.emoji_events_rounded
                                  : Icons.stars_rounded,
                              size: 64,
                              color: percentage >= 50
                                  ? Colors.amberAccent
                                  : mainColor,
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Title & Subtitle
                          Text(
                            getScoreTitle(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: mainColor,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Text(
                            getScoreSubtitle(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Percentage Circle Gauge
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 130,
                                height: 130,
                                child: CircularProgressIndicator(
                                  value: percentage / 100,
                                  strokeWidth: 10,
                                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                                  valueColor: AlwaysStoppedAnimation<Color>(mainColor),
                                  strokeCap: StrokeCap.round,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "${percentage.toInt()}%",
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    "${widget.score} / ${widget.total}",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white60,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Stat Chips (Correct / Wrong)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildStatChip(
                                icon: Icons.check_circle_rounded,
                                label: "${widget.score} صحيحة",
                                color: const Color(0xFF10B981),
                              ),
                              const SizedBox(width: 12),
                              _buildStatChip(
                                icon: Icons.cancel_rounded,
                                label: "$wrongCount خاطئة",
                                color: const Color(0xFFEF4444),
                              ),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // Action Button 1: Cognitive Report
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
                                ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF6C63FF)
                                        .withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                icon: const Icon(
                                  Icons.psychology_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                label: const Text(
                                  "عرض التقرير المعرفي",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                onPressed: () => isGuest
                                    ? Fluttertoast.showToast(
                                        msg: "يجب تسجيل الدخول لتظهر التقارير",
                                      )
                                    : Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => LastAnalysisPage(),
                                        ),
                                      ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Action Button 2: Back to Categories
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                              ),
                              child: ElevatedButton.icon(
                                icon: const Icon(
                                  Icons.home_rounded,
                                  color: Colors.white,
                                  size: 22,
                                ),
                                label: const Text(
                                  "العودة إلى الفئات",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                onPressed: _navigateToCategories,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Confetti Effect
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Color(0xFF10B981),
                  Color(0xFF3B82F6),
                  Color(0xFFEC4899),
                  Color(0xFFF59E0B),
                  Color(0xFF8B5CF6),
                ],
                gravity: 0.25,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
