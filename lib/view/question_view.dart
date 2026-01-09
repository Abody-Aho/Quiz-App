import 'package:exam/view/result_page.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../core/class/route_transitions.dart';
import '../model/model.dart';
import '../service/groq_ai_service.dart';
import '../widget/options_widget.dart';

class QuestionView extends StatefulWidget {
  final Category category;
  final String language;
  final String level;
  const QuestionView({super.key, required this.category, required this.language, required this.level});

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

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    questions = await aiService.generateQuizByCategory(widget.category,widget.level);
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int totalQuestions =
    isLoading ? 10 : (questions.isEmpty ? 0 : questions.length);

    final double progress = (isLoading || questions.isEmpty)
        ? 0
        : _questionNumber / questions.length;

    return Scaffold(
      body: Skeletonizer(
        enabled: isLoading,
        effect: const PulseEffect(
          from: Color(0xFFE6E4FF),
          to: Color(0xFFF3F2FF),
        ),
        child: Container(
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
                          "Question $_questionNumber / $totalQuestions",
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
                          ? const Center(
                        child: Text(
                          "لا توجد أسئلة",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                          : PageView.builder(
                        controller: _controller,
                        physics:
                        const NeverScrollableScrollPhysics(),
                        itemCount: questions.length,
                        itemBuilder: (context, index) {
                          return buildQuestion(questions[index]);
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ================= Next Button =================
                    if (!isLoading &&
                        questions.isNotEmpty &&
                        questions[_questionNumber - 1].isConfirmed)
                      buildButton()
                    else
                      const SizedBox(height: 55),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= Skeleton =================
  Widget buildSkeletonQuestion() {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(height: 30, width: double.infinity, color: Colors.white),
            const SizedBox(height: 24),
            ...List.generate(
              4,
                  (index) => Container(
                height: 50,
                margin: const EdgeInsets.only(bottom: 16),
                color: Colors.white,
              ),
            ),
          ],
        ),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.text,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ================= Options =================
                    OptionsWidget(
                      question: question,
                      onClickedOption: (option) {
                        if (question.isConfirmed) return;

                        setState(() {
                          question.selectedOption = option;
                        });
                      },
                    ),

                    const SizedBox(height: 16),

                    // ================= Confirm Button =================
                    if (question.selectedOption != null &&
                        !question.isConfirmed)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple.shade900,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              question.isConfirmed = true;
                              if (question.selectedOption!.isCorrect) {
                                _score++;
                              }
                            });
                          },
                          child: Text(
                            widget.language == 'en'
                                ? "Confirm Answer" : "تأكيد الاجابة",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
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
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
            setState(() {
              _questionNumber++;
            });
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
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
