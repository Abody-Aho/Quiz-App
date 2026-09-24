import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../model/cognitive_report.dart';
import '../service/cloud_last_analysis_service.dart';

class LastAnalysisPage extends StatefulWidget {
  const LastAnalysisPage({super.key});

  @override
  State<LastAnalysisPage> createState() => _LastAnalysisPageState();
}

class _LastAnalysisPageState extends State<LastAnalysisPage> {
  Future<CognitiveReport?>? _futureReport;

  @override
  void initState() {
    super.initState();
    _futureReport = CloudLastAnalysisService.getLastAnalysis();
  }

  Color _getWeaknessColor(double value) {
    if (value >= 70) return const Color(0xFFEF4444);
    if (value >= 40) return const Color(0xFFF59E0B);
    return const Color(0xFF10B981);
  }

  // Calculate smooth cumulative accuracy percentage spots from answersFlow
  List<FlSpot> _buildCumulativeAccuracySpots(List<bool> flow) {
    if (flow.isEmpty) return [const FlSpot(1, 0)];

    List<FlSpot> spots = [];
    int runningCorrect = 0;

    // Sample at most 15-20 points for a smooth curve
    int step = (flow.length / 15).ceil().clamp(1, 100);

    for (int i = 0; i < flow.length; i++) {
      if (flow[i]) runningCorrect++;

      if ((i + 1) % step == 0 || i == flow.length - 1) {
        double runningAcc = (runningCorrect / (i + 1)) * 100;
        spots.add(FlSpot((spots.length + 1).toDouble(), runningAcc.roundToDouble()));
      }
    }

    return spots;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
          child: FutureBuilder<CognitiveReport?>(
            future: _futureReport,
            builder: (context, snapshot) {
              // Loading
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                );
              }

              // No Data
              if (!snapshot.hasData || snapshot.data == null) {
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.psychology_outlined,
                          size: 64,
                          color: Color(0xFFA78BFA),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "لا يوجد تحليل محفوظ بعد\nقم بحل اختبار أولاً لمشاهدة التقرير",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 18),
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded,
                              color: Colors.white, size: 28),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final report = snapshot.data!;
              final double wrongPercentage = (100 - report.accuracy).clamp(0, 100);

              return Column(
                children: [
                  // Custom Header
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.psychology_rounded,
                                color: Color(0xFFA78BFA),
                                size: 24,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "تحليل آخر اختبار",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 42),
                      ],
                    ),
                  ),

                  // Main Content Scroll
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      children: [
                        // ===== 1. Overview Card =====
                        _buildGlassCard(
                          title: "الملخص العام",
                          icon: Icons.analytics_rounded,
                          child: Row(
                            children: [
                              _buildStatBox(
                                label: "الإجابات الصحيحة",
                                value: "${report.totalCorrect}",
                                color: const Color(0xFF10B981),
                                icon: Icons.check_circle_rounded,
                              ),
                              const SizedBox(width: 10),
                              _buildStatBox(
                                label: "الإجابات الخاطئة",
                                value: "${report.totalWrong}",
                                color: const Color(0xFFEF4444),
                                icon: Icons.cancel_rounded,
                              ),
                              const SizedBox(width: 10),
                              _buildStatBox(
                                label: "نسبة الدقة",
                                value: "${report.accuracy.toStringAsFixed(1)}%",
                                color: const Color(0xFF8B5CF6),
                                icon: Icons.percent_rounded,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ===== 2. Accuracy Pie Chart =====
                        _buildGlassCard(
                          title: "مؤشر الدقة",
                          icon: Icons.pie_chart_rounded,
                          child: Column(
                            children: [
                              SizedBox(
                                height: 180,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    PieChart(
                                      PieChartData(
                                        sectionsSpace: 4,
                                        centerSpaceRadius: 55,
                                        startDegreeOffset: -90,
                                        sections: [
                                          PieChartSectionData(
                                            value: report.accuracy,
                                            color: const Color(0xFF10B981),
                                            radius: 22,
                                            showTitle: false,
                                          ),
                                          PieChartSectionData(
                                            value: wrongPercentage,
                                            color: const Color(0xFFEF4444),
                                            radius: 22,
                                            showTitle: false,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "${report.accuracy.toStringAsFixed(0)}%",
                                          style: const TextStyle(
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const Text(
                                          "نسبة النجاح",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.white60,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildLegendItem("صحيحة", const Color(0xFF10B981), "${report.accuracy.toStringAsFixed(0)}%"),
                                  const SizedBox(width: 20),
                                  _buildLegendItem("خاطئة", const Color(0xFFEF4444), "${wrongPercentage.toStringAsFixed(0)}%"),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ===== 3. Trend Card =====
                        _buildGlassCard(
                          title: "اتجاه الأداء",
                          icon: Icons.trending_up_rounded,
                          child: Text(
                            report.performanceTrend,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // ===== 4. Smooth Cumulative Accuracy Line Chart =====
                        if (report.answersFlow.isNotEmpty)
                          _buildGlassCard(
                            title: "منحنى الدقة التراكمي أثناء الاختبار",
                            icon: Icons.show_chart_rounded,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "يُظهر تطور نسبة الدقة التراكمية مع تقدم الأسئلة (0% إلى 100%)",
                                  style: TextStyle(color: Colors.white60, fontSize: 12),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 200,
                                  child: LineChart(
                                    LineChartData(
                                      minY: 0,
                                      maxY: 100,
                                      gridData: FlGridData(
                                        show: true,
                                        drawVerticalLine: false,
                                        horizontalInterval: 25,
                                        getDrawingHorizontalLine: (value) => FlLine(
                                          color: Colors.white.withValues(alpha: 0.08),
                                          strokeWidth: 1,
                                        ),
                                      ),
                                      titlesData: FlTitlesData(
                                        show: true,
                                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        leftTitles: AxisTitles(
                                          sideTitles: SideTitles(
                                            showTitles: true,
                                            interval: 25,
                                            reservedSize: 36,
                                            getTitlesWidget: (value, meta) {
                                              return Text(
                                                "${value.toInt()}%",
                                                style: const TextStyle(
                                                  color: Colors.white54,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      borderData: FlBorderData(show: false),
                                      lineBarsData: [
                                        LineChartBarData(
                                          spots: _buildCumulativeAccuracySpots(report.answersFlow),
                                          isCurved: true,
                                          curveSmoothness: 0.35,
                                          color: const Color(0xFF38BDF8),
                                          barWidth: 3.5,
                                          isStrokeCapRound: true,
                                          dotData: const FlDotData(show: true),
                                          belowBarData: BarAreaData(
                                            show: true,
                                            gradient: LinearGradient(
                                              colors: [
                                                const Color(0xFF38BDF8).withValues(alpha: 0.35),
                                                Colors.transparent,
                                              ],
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 16),

                        // ===== 5. Category Weakness =====
                        if (report.categoryWeakness.isNotEmpty)
                          _buildGlassCard(
                            title: "تحليل الضعف حسب الفئة",
                            icon: Icons.category_rounded,
                            child: Column(
                              children: report.categoryWeakness.entries.map((e) {
                                final color = _getWeaknessColor(e.value);
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            e.key,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            "${e.value.toStringAsFixed(0)}% أخطاء",
                                            style: TextStyle(
                                              color: color,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: LinearProgressIndicator(
                                          value: (e.value / 100).clamp(0.0, 1.0),
                                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                                          color: color,
                                          minHeight: 8,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                        const SizedBox(height: 16),

                        // ===== 6. Smart Analysis Summary =====
                        _buildGlassCard(
                          title: "التحليل الذكي الشامل",
                          icon: Icons.auto_awesome_rounded,
                          child: Text(
                            report.summary,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                              height: 1.5,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ================= Widgets =================
  Widget _buildGlassCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E163B).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFFA78BFA), size: 22),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          "$label ($value)",
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
      ],
    );
  }
}
