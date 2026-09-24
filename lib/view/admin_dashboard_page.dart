import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

const String kAdminEmail = "abdalwalysamer6@gmail.com";

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _showActiveOnly = false; // Filter active users only (who solved questions)

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Delete User Document & All Subcollections from Firestore
  Future<void> _deleteUserDoc(String docId, String userName) async {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B1537),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
              SizedBox(width: 8),
              Text(
                'حذف حساب مستخدم نهائياً',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Text(
            'هل أنت متأكد من حذف حساب "$userName" وجميع إحصائياته نهائياً من قاعدة البيانات؟',
            style: const TextStyle(color: Colors.white70, fontSize: 15, height: 1.4),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  // Delete answered_questions subcollection
                  final answersSnap = await _firestore
                      .collection('users')
                      .doc(docId)
                      .collection('answered_questions')
                      .get();
                  for (var doc in answersSnap.docs) {
                    await doc.reference.delete();
                  }

                  // Delete reports subcollection
                  final reportsSnap = await _firestore
                      .collection('users')
                      .doc(docId)
                      .collection('reports')
                      .get();
                  for (var doc in reportsSnap.docs) {
                    await doc.reference.delete();
                  }

                  // Delete main user document
                  await _firestore.collection('users').doc(docId).delete();
                  Fluttertoast.showToast(msg: "تم حذف حساب المستخدم وجميع بياناته نهائياً");
                } catch (e) {
                  Fluttertoast.showToast(msg: "حدث خطأ أثناء الحذف: $e");
                }
              },
              child: const Text('حذف نهائي', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
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
          child: Column(
            children: [
              // Header Bar
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
                            Icons.admin_panel_settings_rounded,
                            color: Color(0xFFFFD700),
                            size: 26,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "لوحة تحكم المسؤول",
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

              // Glass TabBar (2 Tabs)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E163B).withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: const Color(0xFFFFD700),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: const Color(0xFFFFD700),
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.analytics_rounded, size: 20),
                      text: "التحليلات والإحصائيات",
                    ),
                    Tab(
                      icon: Icon(Icons.people_rounded, size: 20),
                      text: "إدارة المستخدمين",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildUsersTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= TAB 1: OVERVIEW & ANALYTICS =================
  Widget _buildOverviewTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        int totalUsers = docs.length;
        int totalCorrect = 0;
        int totalWrong = 0;

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final c = (data['correctAnswers'] as num?)?.toInt() ?? 0;
          final w = (data['wrongAnswers'] as num?)?.toInt() ?? 0;
          totalCorrect += c;
          totalWrong += w;
        }

        int totalQuestions = totalCorrect + totalWrong;
        double globalAccuracy = totalQuestions > 0
            ? (totalCorrect / totalQuestions) * 100
            : 0;

        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            // Stats Grid
            Row(
              children: [
                _buildAdminStatCard(
                  title: "المستخدمين",
                  value: "$totalUsers",
                  icon: Icons.people_rounded,
                  color: const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 12),
                _buildAdminStatCard(
                  title: "إجمالي الأسئلة",
                  value: "$totalQuestions",
                  icon: Icons.quiz_rounded,
                  color: const Color(0xFF8B5CF6),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildAdminStatCard(
                  title: "الإجابات الصحيحة",
                  value: "$totalCorrect",
                  icon: Icons.check_circle_rounded,
                  color: const Color(0xFF10B981),
                ),
                const SizedBox(width: 12),
                _buildAdminStatCard(
                  title: "الإجابات الخاطئة",
                  value: "$totalWrong",
                  icon: Icons.cancel_rounded,
                  color: const Color(0xFFEF4444),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Global Accuracy Chart
            _buildGlassCard(
              title: "مؤشر الدقة العام للتطبيق",
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
                                value: globalAccuracy,
                                color: const Color(0xFF10B981),
                                radius: 22,
                                showTitle: false,
                              ),
                              PieChartSectionData(
                                value: (100 - globalAccuracy).clamp(0, 100),
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
                              "${globalAccuracy.toStringAsFixed(1)}%",
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              "دقة المستخدمين",
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
                      _buildLegendItem(
                        "صحيحة",
                        const Color(0xFF10B981),
                        "${globalAccuracy.toStringAsFixed(0)}%",
                      ),
                      const SizedBox(width: 20),
                      _buildLegendItem(
                        "خاطئة",
                        const Color(0xFFEF4444),
                        "${(100 - globalAccuracy).toStringAsFixed(0)}%",
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Top Active Users
            _buildGlassCard(
              title: "أفضل المستخدمين أداءً",
              icon: Icons.emoji_events_rounded,
              child: docs.isEmpty
                  ? const Text(
                      "لا توجد بيانات مستخدمين بعد",
                      style: TextStyle(color: Colors.white70),
                    )
                  : Column(
                      children: docs.take(5).map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = data['displayName'] ?? 'مستخدم Google';
                        final photo = data['photoURL'] ?? '';
                        final c = data['correctAnswers'] ?? 0;
                        final w = data['wrongAnswers'] ?? 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 20,
                                backgroundImage: photo.isNotEmpty
                                    ? NetworkImage(photo)
                                    : null,
                                child: photo.isEmpty
                                    ? const Icon(Icons.person,
                                        color: Colors.white70)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                "$c صحيحة / $w خاطئة",
                                style: const TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.redAccent,
                                  size: 18,
                                ),
                                onPressed: () {
                                  _deleteUserDoc(doc.id, name);
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        );
      },
    );
  }

  // ================= TAB 2: USERS MANAGEMENT =================
  Widget _buildUsersTab() {
    return Column(
      children: [
        // Search Box & Active Filter Toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "بحث باسم المستخدم أو البريد...",
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon:
                      const Icon(Icons.search_rounded, color: Colors.white70),
                  filled: true,
                  fillColor: const Color(0xFF1E163B).withValues(alpha: 0.8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim().toLowerCase();
                  });
                },
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "تصفية المستخدمين:",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text("الكل"),
                        selected: !_showActiveOnly,
                        selectedColor: const Color(0xFF8B5CF6),
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        labelStyle: TextStyle(
                          color:
                              !_showActiveOnly ? Colors.white : Colors.purple,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _showActiveOnly = false);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text("الفعالين فقط"),
                        selected: _showActiveOnly,
                        selectedColor: const Color(0xFF8B5CF6),
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        labelStyle: TextStyle(
                          color:
                              _showActiveOnly ? Colors.white : Colors.purple,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _showActiveOnly = true);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // Users Stream List
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                );
              }

              final allDocs = snapshot.data?.docs ?? [];
              final filteredDocs = allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name =
                    (data['displayName'] ?? '').toString().toLowerCase();
                final email = (data['email'] ?? '').toString().toLowerCase();
                final correct = (data['correctAnswers'] as num?)?.toInt() ?? 0;
                final wrong = (data['wrongAnswers'] as num?)?.toInt() ?? 0;

                bool matchesSearch =
                    name.contains(_searchQuery) || email.contains(_searchQuery);

                if (_showActiveOnly) {
                  return matchesSearch && (correct + wrong > 0);
                }
                return matchesSearch;
              }).toList();

              if (filteredDocs.isEmpty) {
                return const Center(
                  child: Text(
                    "لم يتم العثور على مستخدمين مطبقين للشروط",
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 6,
                ),
                itemCount: filteredDocs.length,
                itemBuilder: (context, index) {
                  final doc = filteredDocs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['displayName'] ?? 'Google User';
                  final email = data['email'] ?? '';
                  final photo = data['photoURL'] ?? '';
                  final correct =
                      (data['correctAnswers'] as num?)?.toInt() ?? 0;
                  final wrong = (data['wrongAnswers'] as num?)?.toInt() ?? 0;
                  final total = correct + wrong;
                  final accuracy = total > 0
                      ? ((correct / total) * 100).toStringAsFixed(1)
                      : "0";

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E163B).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          backgroundImage:
                              photo.isNotEmpty ? NetworkImage(photo) : null,
                          child: photo.isEmpty
                              ? const Icon(Icons.person_rounded,
                                  color: Colors.white70)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (email.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    "صح: $correct",
                                    style: const TextStyle(
                                      color: Color(0xFF10B981),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    "خطأ: $wrong",
                                    style: const TextStyle(
                                      color: Color(0xFFEF4444),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF8B5CF6)
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            "$accuracy%",
                            style: const TextStyle(
                              color: Color(0xFFDDD6FE),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          onPressed: () {
                            _deleteUserDoc(doc.id, name);
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ================= UI HELPERS =================
  Widget _buildAdminStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E163B).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: color.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                Icon(icon, color: const Color(0xFFFFD700), size: 22),
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
