import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exam/view/result_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../core/class/route_transitions.dart';
import '../model/model.dart';
import '../service/groq_ai_service.dart';
import '../service/quiz_progress_service.dart';
import '../service/statistics_service.dart';
import '../widget/options_widget.dart';

class QuestionView extends StatefulWidget {
  final Category category;
  final String language;
  final String level;

  const QuestionView({
    super.key,
    required this.category,
    required this.language,
    required this.level,
  });

  @override
  State<QuestionView> createState() => _QuestionViewState();
}

class _QuestionViewState extends State<QuestionView> {
  final GroqAIService aiService = GroqAIService();
  final PageController _controller = PageController();

  List<Question> questions = [];
  bool isLoading = true;

  int _questionNumber = 1;
  int _score = 0;

  // ================= Restore Progress =================
  Future<void> _restoreProgress() async {
    final prefs = await SharedPreferences.getInstance();
    _score = prefs.getInt('quiz_score') ?? 0;
    _questionNumber = prefs.getInt('quiz_question') ?? 1;
  }

  @override
  void initState() {
    super.initState();
    _initQuiz();
  }

  Future<void> _initQuiz() async {
    await _restoreProgress();
    await loadQuestions();
  }

  // ================= Load Questions =================
  Future<void> loadQuestions() async {
    questions = await aiService.loadQuizQuestions(
      widget.category,
      widget.level,
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;

      if (questions.isEmpty) {
        _questionNumber = 0;
      } else {
        if (_questionNumber < 1) {
          _questionNumber = 1;
        }
        if (_questionNumber > questions.length) {
          _questionNumber = questions.length;
        }
      }
    });

    if (_questionNumber > 1) {
      _controller.jumpToPage(_questionNumber - 1);
    }
  }

  // ================= Save Answer =================
  Future<void> saveAnsweredQuestion(Question question) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final selected = question.selectedOption!;
    final correctIndex =
    question.options.indexWhere((o) => o.isCorrect);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('answered_questions')
        .add({
      'question': question.text,
      'options': question.options.map((o) => o.text).toList(),
      'correctIndex': correctIndex,
      'selectedIndex': selected.index,
      'isCorrect': selected.isCorrect,
      'categoryId': widget.category.id,
      'level': widget.level,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final int totalQuestions =
    isLoading ? 10 : (questions.isEmpty ? 0 : questions.length);

    final double progress = questions.isEmpty
        ? 0
        : (_questionNumber.clamp(1, questions.length)) /
        questions.length;

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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Directionality(
              textDirection: widget.category.direction,
              child: Column(
                children: [
                  // ================= Header =================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back,
                            color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        totalQuestions == 0
                            ? ""
                            : "Question $_questionNumber / $totalQuestions",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ================= Progress =================
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white24,
                    color: Colors.white,
                  ),

                  const SizedBox(height: 20),

                  // ================= Content =================
                  Expanded(
                    child: isLoading
                        ? buildSkeletonQuestion()
                        : questions.isEmpty
                        ? buildNoQuestionsView()
                        : PageView.builder(
                      controller: _controller,
                      physics:
                      const NeverScrollableScrollPhysics(),
                      itemCount: questions.length,
                      itemBuilder: (context, index) {
                        return buildQuestion(
                            questions[index]);
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ================= Next Button =================
                  if (!isLoading &&
                      questions.isNotEmpty &&
                      questions[_questionNumber - 1]
                          .isConfirmed)
                    buildButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= Skeleton =================
  Widget buildSkeletonQuestion() {
    return Skeletonizer(
      enabled: true,
      effect: const ShimmerEffect(
        baseColor: Color(0xFFE6E4FF),
        highlightColor: Color(0xFFF3F2FF),
      ),
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      // ===== Skeleton Question Title =====
                      Container(
                        height: 28,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ===== Skeleton Options =====
                      ...List.generate(
                        4,
                            (_) => Container(
                          height: 50,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }


  Widget buildNoQuestionsView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off,
              size: 60, color: Colors.white70),
          SizedBox(height: 16),
          Text(
            "لا يوجد اتصال بالإنترنت\nولا يوجد اختبار محفوظ",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ================= Question =================
  Widget buildQuestion(Question question) {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.text,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    OptionsWidget(
                      question: question,
                      onClickedOption: (option) {
                        if (question.isConfirmed) {
                          return;
                        }
                        setState(() {
                          question.selectedOption =
                              option;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    if (question.selectedOption !=
                        null &&
                        !question.isConfirmed)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style:
                          ElevatedButton.styleFrom(
                            backgroundColor:
                            Colors.purple.shade900,
                            foregroundColor:
                            Colors.white,
                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(
                                  15),
                            ),
                          ),
                          onPressed: () async {
                            if (question.isConfirmed) {
                              return;
                            }

                            final bool isCorrect =
                                question.selectedOption!
                                    .isCorrect;

                            setState(() {
                              question.isConfirmed =
                              true;
                              if (isCorrect) _score++;
                            });

                            await saveAnsweredQuestion(
                                question);

                            await StatisticsService()
                                .saveSingleAnswer(
                              isCorrect: isCorrect,
                            );

                            await QuizProgressService
                                .saveProgress(
                              score: _score,
                              questionNumber:
                              _questionNumber,
                            );
                          },
                          child: Text(
                            widget.language == 'en'
                                ? "Confirm Answer"
                                : "تأكيد الاجابة",
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                FontWeight.bold),
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
    );
  }

  // ================= Next Button =================
  Widget buildButton() {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: () {
          if (_questionNumber < questions.length) {
            _controller.nextPage(
              duration:
              const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );

            setState(() {
              _questionNumber++;
            });

            QuizProgressService.saveProgress(
              score: _score,
              questionNumber: _questionNumber,
            );
          } else {
            Navigator.pushReplacement(
              context,
              AppRoute.fadeSlide(
                ResultPage(
                  score: _score,
                  total: questions.length,
                ),
              ),
            );
          }
        },
        child: Text(
          _questionNumber < questions.length
              ? "Next Question"
              : "See Result",
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
