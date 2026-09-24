import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  QuerySnapshot? _cachedSnapshot;

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
                            Icons.emoji_events_rounded,
                            color: Colors.amberAccent,
                            size: 24,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "لوحة الصدارة",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
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

              // Firestore Stream
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .orderBy('correctAnswers', descending: true)
                      .limit(100)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      _cachedSnapshot = snapshot.data;
                    }

                    // Skeleton Loading
                    if (_cachedSnapshot == null) {
                      return Skeletonizer(
                        enabled: true,
                        effect: const ShimmerEffect(
                          baseColor: Color(0xFF2A2450),
                          highlightColor: Color(0xFF3D3570),
                        ),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(18),
                          itemCount: 8,
                          itemBuilder: (context, index) {
                            return _leaderboardItem(
                              index: index,
                              name: "Loading User",
                              imageUrl: "",
                              correct: 0,
                              wrong: 0,
                            );
                          },
                        ),
                      );
                    }

                    final docs = _cachedSnapshot!.docs;

                    if (docs.isEmpty) {
                      return Center(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.leaderboard_rounded,
                                size: 54,
                                color: Colors.white38,
                              ),
                              SizedBox(height: 12),
                              Text(
                                "لا توجد بيانات متصدرين بعد",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // Real Data List
                    return Skeletonizer(
                      enabled: false,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;

                          return _leaderboardItem(
                            index: index,
                            name: data['displayName'] ?? 'Google User',
                            imageUrl: data['photoURL'] ?? '',
                            correct: data['correctAnswers'] ?? 0,
                            wrong: data['wrongAnswers'] ?? 0,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= Leaderboard Item =================
  Widget _leaderboardItem({
    required int index,
    required String name,
    required String imageUrl,
    required int correct,
    required int wrong,
  }) {
    final rank = index + 1;

    Color badgeColor;
    Color strokeColor;
    IconData? trophyIcon;

    if (rank == 1) {
      badgeColor = const Color(0xFFFFD700); // Gold
      strokeColor = const Color(0xFFFFD700);
      trophyIcon = Icons.emoji_events_rounded;
    } else if (rank == 2) {
      badgeColor = const Color(0xFFE2E8F0); // Silver
      strokeColor = const Color(0xFFCBD5E1);
      trophyIcon = Icons.emoji_events_rounded;
    } else if (rank == 3) {
      badgeColor = const Color(0xFFF97316); // Bronze
      strokeColor = const Color(0xFFF97316);
      trophyIcon = Icons.emoji_events_rounded;
    } else {
      badgeColor = Colors.white.withValues(alpha: 0.12);
      strokeColor = Colors.white.withValues(alpha: 0.15);
      trophyIcon = null;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E163B).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: strokeColor,
          width: rank <= 3 ? 1.8 : 1.0,
        ),
        boxShadow: rank <= 3
            ? [
                BoxShadow(
                  color: strokeColor.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: badgeColor,
              shape: BoxShape.circle,
              boxShadow: rank <= 3
                  ? [
                      BoxShadow(
                        color: badgeColor.withValues(alpha: 0.4),
                        blurRadius: 8,
                      )
                    ]
                  : [],
            ),
            alignment: Alignment.center,
            child: trophyIcon != null
                ? Icon(trophyIcon, color: Colors.black87, size: 22)
                : Text(
                    rank.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
          ),

          const SizedBox(width: 12),

          // User Avatar
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: strokeColor.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            child: CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              backgroundImage:
                  imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
              child: imageUrl.isEmpty
                  ? const Icon(Icons.person_rounded,
                      color: Colors.white70, size: 24)
                  : null,
            ),
          ),

          const SizedBox(width: 12),

          // User Name
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Stats Badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Correct Answers
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    correct.toString(),
                    style: const TextStyle(
                      color: Color(0xFF34D399),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Wrong Answers
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cancel_rounded,
                    color: Color(0xFFEF4444),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    wrong.toString(),
                    style: const TextStyle(
                      color: Color(0xFFF87171),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
