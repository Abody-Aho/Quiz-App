import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exam/view/result_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../core/class/route_transitions.dart';
import '../model/model.dart';
import '../service/behavior_logger.dart';
import '../service/groq_ai_service.dart';
import '../service/quiz_progress_service.dart';
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
    _questionNumber = 1;
  }

  @override
  void initState() {
    super.initState();
    BehaviorLogger.startSession();
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
        : (_questionNumber.clamp(1, questions.length)) / questions.length;

    final bool isArabic = widget.category.direction == TextDirection.rtl;

    return Scaffold(
      body: Container(
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Directionality(
              textDirection: widget.category.direction,
              child: Column(
                children: [
                  // ================= Top Bar =================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back Button
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
                          child: Icon(
                            isArabic
                                ? Icons.arrow_forward_ios_rounded
                                : Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),

                      // Question Counter Badge
                      if (totalQuestions > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF6C63FF).withValues(alpha: 0.4),
                                const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.quiz_outlined,
                                color: Color(0xFFA78BFA),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isArabic
                                    ? "السؤال $_questionNumber من $totalQuestions"
                                    : "Question $_questionNumber of $totalQuestions",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Category Icon/Title Chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildSmallCategoryImage(widget.category.image),
                            const SizedBox(width: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 80),
                              child: Text(
                                widget.category.title,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ================= Progress Bar =================
                  Container(
                    height: 10,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      children: [
                        AnimatedFractionallySizedBox(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          widthFactor: progress.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF6C63FF),
                                  Color(0xFF8B5CF6),
                                  Color(0xFFEC4899),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF8B5CF6)
                                      .withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ================= Content Area =================
                  Expanded(
                    child: isLoading
                        ? buildSkeletonQuestion()
                        : questions.isEmpty
                            ? buildNoQuestionsView()
                            : PageView.builder(
                                controller: _controller,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: questions.length,
                                itemBuilder: (context, index) {
                                  return buildQuestionCard(
                                    questions[index],
                                    isArabic,
                                  );
                                },
                              ),
                  ),

                  const SizedBox(height: 14),

                  // ================= Bottom Action Button =================
                  if (!isLoading &&
                      questions.isNotEmpty &&
                      questions[_questionNumber - 1].isConfirmed)
                    buildNextButton(isArabic),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= Small Image Helper =================
  Widget _buildSmallCategoryImage(String imagePath) {
    if (imagePath.isEmpty) {
      return const Icon(Icons.code, size: 16, color: Colors.white70);
    }
    if (imagePath.startsWith('asset')) {
      return Image.asset(imagePath, height: 18, width: 18, fit: BoxFit.cover);
    }
    return Image.file(File(imagePath), height: 18, width: 18, fit: BoxFit.cover);
  }

  // ================= Skeleton Loader =================
  Widget buildSkeletonQuestion() {
    return Skeletonizer(
      enabled: true,
      effect: const ShimmerEffect(
        baseColor: Color(0xFF2A2450),
        highlightColor: Color(0xFF3D3570),
      ),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 28,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 20,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 30),
            ...List.generate(
              4,
              (_) => Container(
                height: 56,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= Empty View =================
  Widget buildNoQuestionsView() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 64, color: Color(0xFFA78BFA)),
            SizedBox(height: 18),
            Text(
              "لا يوجد اتصال بالإنترنت\nولا يوجد اختبار محفوظ لهذا المجال",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= Question Card =================
  Widget buildQuestionCard(Question question, bool isArabic) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E163B).withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question Number Tag
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          color: Color(0xFFA78BFA),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isArabic ? "سؤال الاختبار" : "Question Detail",
                          style: const TextStyle(
                            color: Color(0xFFDDD6FE),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Question Text
                  Text(
                    question.text,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Options
                  OptionsWidget(
                    question: question,
                    isArabic: isArabic,
                    onClickedOption: (option) {
                      if (question.isConfirmed) return;
                      setState(() {
                        question.selectedOption = option;
                      });
                    },
                  ),

                  const SizedBox(height: 16),

                  // Confirm Answer Button (inside scroll card)
                  if (question.selectedOption != null && !question.isConfirmed)
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
                                  .withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          icon: const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          label: Text(
                            isArabic ? "تأكيد الإجابة" : "Confirm Answer",
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          onPressed: () async {
                            if (question.isConfirmed) return;

                            final bool isCorrect =
                                question.selectedOption!.isCorrect;

                            setState(() {
                              question.isConfirmed = true;
                              if (isCorrect) _score++;
                              BehaviorLogger.logAnswer(
                                questionIndex: _questionNumber,
                                isCorrect: isCorrect,
                                category: widget.category.title,
                              );
                            });

                            await saveAnsweredQuestion(question);
                            await QuizProgressService.saveProgress(
                              score: _score,
                              questionNumber: _questionNumber,
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= Next Button =================
  Widget buildNextButton(bool isArabic) {
    final bool isLast = _questionNumber >= questions.length;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEC4899).withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          onPressed: () {
            if (_questionNumber < questions.length) {
              _controller.nextPage(
                duration: const Duration(milliseconds: 300),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                isLast
                    ? (isArabic ? "مشاهدة النتيجة" : "See Result")
                    : (isArabic ? "السؤال التالي" : "Next Question"),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                isLast
                    ? Icons.emoji_events_rounded
                    : (isArabic
                        ? Icons.arrow_back_rounded
                        : Icons.arrow_forward_rounded),
                color: Colors.white,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
