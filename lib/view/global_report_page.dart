import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../model/cognitive_report.dart';
import '../service/cloud_report_service.dart';
import '../service/global_cognitive_analyzer.dart';

class GlobalReportPage extends StatefulWidget {
  const GlobalReportPage({super.key});

  @override
  State<GlobalReportPage> createState() => _GlobalReportPageState();
}

class _GlobalReportPageState extends State<GlobalReportPage> {
  Future<CognitiveReport?>? _futureReport;

  @override
  void initState() {
    super.initState();
    _futureReport = _loadGlobalReport();
  }

  Future<CognitiveReport?> _loadGlobalReport() async {
    final reports = await CloudReportService.getAllReports();

    if (reports.isEmpty) {
      return null;
    }

    return GlobalCognitiveAnalyzer.analyzeAll(reports);
  }

  Color _getWeaknessColor(double value) {
    if (value >= 70) return Colors.redAccent;
    if (value >= 40) return Colors.orangeAccent;
    return Colors.greenAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff1D2671), Color(0xffC33764)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: FutureBuilder<CognitiveReport?>(
            future: _futureReport,
            builder: (context, snapshot) {
              // ================= Loading =================
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }

              // ================= No Data =================
              if (!snapshot.hasData || snapshot.data == null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.insert_chart_outlined,
                          size: 80, color: Colors.white70),
                      const SizedBox(height: 16),
                      const Text(
                        "لا يوجد تقارير محفوظة بعد\nقم بحل بعض الاختبارات أولاً",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                );
              }

              final report = snapshot.data!;

              // ================= Main UI =================
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [

                    // ================= Header =================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          "التقرير المعرفي الشامل",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ================= Content =================
                    Expanded(
                      child: ListView(
                        children: [

                          // ===== Overview =====
                          _buildCard(
                            title: "الملخص العام لكل الاختبارات",
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoRow("إجمالي الإجابات الصحيحة",
                                    "${report.totalCorrect}"),
                                _buildInfoRow("إجمالي الإجابات الخاطئة",
                                    "${report.totalWrong}"),
                                _buildInfoRow("الدقة العامة",
                                    "${report.accuracy.toStringAsFixed(1)}%"),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ===== Accuracy Pie =====
                          _buildCard(
                            title: "مؤشر الدقة العام",
                            child: SizedBox(
                              height: 180,
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 4,
                                  centerSpaceRadius: 50,
                                  sections: [
                                    PieChartSectionData(
                                      value: report.accuracy,
                                      color: Colors.greenAccent,
                                      radius: 40,
                                      title:
                                      "${report.accuracy.toStringAsFixed(0)}%",
                                      titleStyle: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    PieChartSectionData(
                                      value: 100 - report.accuracy,
                                      color: Colors.white24,
                                      radius: 40,
                                      title: "",
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ===== Trend =====
                          _buildCard(
                            title: "الاتجاه العام للأداء",
                            child: Text(
                              report.performanceTrend,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ===== Line Chart =====
                          if (report.answersFlow.isNotEmpty)
                            _buildCard(
                              title: "منحنى الأداء التراكمي",
                              child: SizedBox(
                                height: 200,
                                child: LineChart(
                                  LineChartData(
                                    minY: 0,
                                    maxY: 1,
                                    gridData:
                                    FlGridData(show: false),
                                    titlesData:
                                    FlTitlesData(show: false),
                                    borderData:
                                    FlBorderData(show: false),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: report.answersFlow
                                            .asMap()
                                            .entries
                                            .map((e) => FlSpot(
                                          e.key.toDouble() + 1,
                                          e.value ? 1 : 0,
                                        ))
                                            .toList(),
                                        isCurved: true,
                                        color: Colors.cyanAccent,
                                        barWidth: 4,
                                        dotData:
                                        FlDotData(show: true),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                          const SizedBox(height: 16),

                          // ===== Category Weakness =====
                          _buildCard(
                            title: "الضعف حسب الفئات (تراكمي)",
                            child: Column(
                              children: report.categoryWeakness.entries
                                  .map((e) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 6),
                                  child: Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        e.key,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        "${e.value.toStringAsFixed(0)}% أخطاء",
                                        style: TextStyle(
                                          color: _getWeaknessColor(
                                              e.value),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ===== Summary =====
                          _buildCard(
                            title: "التحليل الذكي الشامل",
                            child: Text(
                              report.summary,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ================= Reusable Card =================
  Widget _buildCard({required String title, required Widget child}) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Card(
        elevation: 12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: Colors.purple.shade900.withValues(alpha: 0.85),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
