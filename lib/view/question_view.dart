import 'package:exam/view/result_page.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';
import '../model/model.dart';
import '../service/groq_ai_service.dart';
import '../widget/options_widget.dart';

class QuestionView extends StatefulWidget {
  final Category category;
  const QuestionView({super.key, required this.category});

  @override
  State<QuestionView> createState() => _QuestionViewState();
}

class _QuestionViewState extends State<QuestionView> {
  final GroqAIService aiService = GroqAIService();
  final PageController _controller = PageController();

  List<Question> questions = [];
  bool isLoading = true;
  bool _isLocked = false;

  int _questionNumber = 1;
  int _score = 0;

  @override
  void initState() {
    super.initState();
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    questions = await aiService.generateQuizByCategory(widget.category);
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back,
                              color: Colors.white),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        Text(
                          "Question $_questionNumber / ${isLoading ? 10 : questions.length}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // 🔹 Progress
                    LinearProgressIndicator(
                      value: isLoading
                          ? null
                          : _questionNumber / questions.length,
                      backgroundColor: Colors.white24,
                      color: Colors.white,
                    ),

                    const SizedBox(height: 20),

                    Expanded(
                      child: PageView.builder(
                        controller: _controller,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: isLoading ? 1 : questions.length,
                        itemBuilder: (context, index) {
                          return isLoading
                              ? buildSkeletonQuestion()
                              : buildQuestion(questions[index]);
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (!isLoading)
                      _isLocked ? buildButton() : const SizedBox(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget buildSkeletonQuestion() {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24, width: double.infinity),
            const SizedBox(height: 24),
            ...List.generate(
              4,
                  (index) => Container(
                height: 50,
                margin: const EdgeInsets.only(bottom: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget buildQuestion(Question question) {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
            OptionsWidget(
              question: question,
              onClickedOption: (option) {
                if (question.isLocked) return;

                setState(() {
                  question.isLocked = true;
                  question.selectedOption = option;
                  _isLocked = true;
                  if (option.isCorrect) _score++;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

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
              _isLocked = false;
            });
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ResultPage(score: _score, total: questions.length),
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