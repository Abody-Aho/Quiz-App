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
      appBar: AppBar(
        title: const Text(
          "لوحة الصدارة",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E1A40),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: const Color(0xFF1E1A40),
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

            // ================= Skeleton Loading =================
            if (_cachedSnapshot == null) {
              return Skeletonizer(
                enabled: true,
                effect: const ShimmerEffect(
                  baseColor: Color(0xFF2A255F),
                  highlightColor: Color(0xFF3A35A0),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 6,
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
              return const Center(
                child: Text(
                  "لا توجد بيانات بعد",
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            // ================= Real Data =================
            return Skeletonizer(
              enabled: false,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
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

    Color medalColor;
    IconData? medalIcon;

    if (rank == 1) {
      medalColor = const Color(0xFFFFD700);
      medalIcon = Icons.emoji_events;
    } else if (rank == 2) {
      medalColor = const Color(0xFFC0C0C0);
      medalIcon = Icons.emoji_events;
    } else if (rank == 3) {
      medalColor = const Color(0xFFCD7F32);
      medalIcon = Icons.emoji_events;
    } else {
      medalColor = Colors.white.withValues(alpha: 0.25);
      medalIcon = null;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: medalColor),
      ),
      child: Row(
        children: [
          // ===== Rank =====
          CircleAvatar(
            radius: 18,
            backgroundColor: medalColor,
            child: medalIcon != null
                ? Icon(medalIcon, color: Colors.black)
                : Text(
              rank.toString(),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 14),

          // ===== Avatar =====
          CircleAvatar(
            radius: 26,
            backgroundImage:
            imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
            child: imageUrl.isEmpty
                ? const Icon(Icons.person, color: Colors.purple)
                : null,
          ),

          const SizedBox(width: 14),

          // ===== Name =====
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // ===== Stats =====
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Correct
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle,
                      color: Colors.greenAccent, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    correct.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Wrong
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cancel,
                      color: Colors.redAccent, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    wrong.toString(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
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
