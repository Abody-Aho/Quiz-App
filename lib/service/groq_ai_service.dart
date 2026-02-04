import 'dart:convert';
import 'package:exam/service/connectivity_service.dart';
import 'package:exam/service/quiz_cache_service.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';
import '../model/model.dart';
import '../secrets.dart';

class GroqAIService {
  // ================= Generate New Quiz (Online Only) =================
  Future<List<Question>> generateQuizByCategory(
    Category category,
    String level,
  ) async {
    final seed = DateTime.now().microsecondsSinceEpoch;
    final prompt =
    """
You are an expert exam designer and senior subject-matter specialist.

Your task is to generate EXACTLY 10 high-quality multiple-choice questions strictly according to the provided difficulty level.

Randomization Seed:
$seed
Use this seed to intentionally maximize variation and avoid similarity with any previous questions.

Category:
${category.title}

Scope and Topics:
${category.prompt}

Difficulty Level (MANDATORY):
$level

Rules and constraints:
- The difficulty of ALL questions must strictly follow the provided difficulty level.
- Questions must be academically strong, clear, precise, and professionally written.
- The language must be PERFECT and grammatically correct.
- Use ONLY ONE language (Arabic or English) matching the category language.
- Do NOT mix languages under any circumstances.
- Questions must test real understanding, reasoning, and application (not memorization unless the level requires it).
- Avoid ambiguity, vague phrasing, trick questions, or misleading wording.
- Do NOT repeat questions, concepts, or answer options.
- Each question must have EXACTLY 4 distinct answer options.
- Only ONE option is correct.
- Incorrect options must be realistic, logical, and clearly incorrect.

ANTI-REPETITION RULES (MANDATORY):
- Each generated question MUST be conceptually and structurally DIFFERENT from typical or common questions in this topic.
- Do NOT rephrase common or previously generated questions.
- Avoid standard definitions or textbook-style questions unless absolutely required by the difficulty.
- Prefer uncommon scenarios, edge cases, indirect reasoning, comparisons, or practical use cases.
- Each question must focus on a DIFFERENT subtopic or analytical angle within the provided scope.
- Assume the user has already taken similar tests before and expects NEW questions every time.

Output format rules (CRITICAL):
- Return ONLY valid JSON.
- The output must be a JSON array of EXACTLY 10 objects.
- Follow this structure STRICTLY:

[
  {
    "question": "Question text here",
    "options": ["Option A", "Option B", "Option C", "Option D"],
    "correctIndex": 0
  }
]

Any output that is not valid JSON or does not follow the exact structure is considered incorrect.
""";

    try {
      final res = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $groqApiKey',
        },
        body: jsonEncode({
          "model": "llama-3.1-8b-instant",
          "messages": [
            {"role": "user", "content": prompt},
          ],
          "temperature": 0.9,
          "top_p": 0.9,
        }),
      );

      if (res.statusCode != 200) return [];

      final body = jsonDecode(utf8.decode(res.bodyBytes));
      String content = body['choices'][0]['message']['content'];
      content = _extractJson(content);

      final List data = jsonDecode(content);
      final List<Question> questions = [];

      for (final q in data) {
        try {
          int correctIndex = q['correctIndex'] ?? 0;
          final List optionsRaw = q['options'];

          final options = List.generate(4, (i) {
            return Option(
              text: optionsRaw[i].toString(),
              isCorrect: i == correctIndex,
              index: i,
            );
          });

          questions.add(Question(text: q['question'].toString(), options: options));
        } catch (_) { continue; }
      }
      return questions;
    } catch (_) {
      return [];
    }
  }

  // ================= Offline / Online Logic =================
  Future<List<Question>> loadQuizQuestions(
    Category category,
    String level,
  ) async {
    try {
      // تمرير اللغة للكاش لتمييز الاختبارات
      final cachedQuiz = await QuizCacheService.loadQuiz(
        categoryId: category.id,
        level: level,
        language: category.language,
      );

      // 1. إذا لا يوجد إنترنت
      if (!await ConnectivityService.hasInternet()) {
        if (cachedQuiz != null && cachedQuiz.isNotEmpty) {
          return cachedQuiz.map((e) => Question.fromJson(e)).toList();
        }
        return [];
      }

      // 2. يوجد إنترنت → حاول التوليد
      final questions = await generateQuizByCategory(category, level);

      if (questions.isNotEmpty) {
        // حفظ في الكاش مع تحديد اللغة
        await QuizCacheService.saveQuiz(
          categoryId: category.id,
          level: level,
          language: category.language,
          quiz: questions.map((q) => q.toJson()).toList(),
        );
        Fluttertoast.showToast(msg: "تم إنشاء إسئله جديدة");
        return questions;
      }

      // 3. فشل التوليد → ارجع للكاش
      if (cachedQuiz != null && cachedQuiz.isNotEmpty) {
        Fluttertoast.showToast(msg: "تم استخدام اسئلة محفوظة سابقاً");
        return cachedQuiz.map((e) => Question.fromJson(e)).toList();
      }
    } catch (e) {
      print("Error loading questions: $e");
    }
    return [];
  }

  String _extractJson(String text) {
    final start = text.indexOf('[');
    final end = text.lastIndexOf(']');
    if (start != -1 && end != -1 && end > start) {
      return text.substring(start, end + 1);
    }
    return text;
  }
}
