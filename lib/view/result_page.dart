import 'package:confetti/confetti.dart'
    show ConfettiController, ConfettiWidget, BlastDirectionality;
import 'package:flutter/material.dart';
import '../service/quiz_progress_service.dart';
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

  @override
  @override
  void initState() {
    super.initState();

    // ================= Save Final Statistics =================
    final statisticsService = StatisticsService();
    statisticsService.saveResult(
      correct: widget.score,
      wrong: widget.total - widget.score,
    );
    QuizProgressService.clearProgress();

    // ================= Confetti =================
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _confettiController.play();
  }


  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  // ================= Score Result =================
  String getScoreResult() {
    if (widget.score == widget.total) return "Perfect 🎉";
    if (widget.score >= widget.total * 0.7) return "Good 👏";
    if (widget.score >= widget.total * 0.5) return "Average 🙂";
    return "Bad 😢";
  }

  // ================= Score Color =================
  Color getScoreColor() {
    if (widget.score == widget.total) return Colors.greenAccent;
    if (widget.score >= widget.total * 0.7) return Colors.orangeAccent;
    if (widget.score >= widget.total * 0.5) return Colors.deepOrangeAccent;
    return Colors.redAccent;
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        alignment: Alignment.topCenter,
        children: [

          // ================= Background & Card =================
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff1D2671), Color(0xffC33764)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Card(
                elevation: 14,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                margin: const EdgeInsets.symmetric(horizontal: 24),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        size: 80,
                        color: Colors.amberAccent,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "${widget.score} / ${widget.total}",
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        getScoreResult(),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: getScoreColor(),
                        ),
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.home),
                          label: const Text(
                            "Back to Categories",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade800,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ================= Confetti Effect =================
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [
                Colors.green,
                Colors.blue,
                Colors.pink,
                Colors.orange,
                Colors.purple,
              ],
              gravity: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
