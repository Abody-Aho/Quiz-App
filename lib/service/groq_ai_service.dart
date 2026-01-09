import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';

import '../core/class/config.dart';
import '../model/model.dart';
import '../secrets.dart';

class GroqAIService {
  Future<List<Question>> generateQuizByCategory(Category category,String level,) async {
    if (!await checkIConnection()) {
      Fluttertoast.showToast(
        msg: "لا يوجد اتصال بالإنترنت",
        gravity: ToastGravity.BOTTOM,
      );
      return [];
    }

    final prompt = """
You are an expert exam designer and senior subject-matter specialist.

Your task is to generate EXACTLY 10 high-quality multiple-choice questions strictly according to the provided difficulty level.

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
- Do NOT include explanations, hints, markdown, comments, or extra text.

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
          "temperature": 0.1,
        }),
      );

      if (res.statusCode != 200) {
        Fluttertoast.showToast(
          msg: "خطأ في السيرفر، حاول لاحقًا",
        );
        return [];
      }

      final body = jsonDecode(utf8.decode(res.bodyBytes));
      String content = body['choices'][0]['message']['content'];
      content = _extractJson(content);

      final List data = jsonDecode(content);

      return data.map<Question>((q) {
        return Question(
          text: q['question'],
          options: List.generate(4, (i) {
            return Option(
              text: q['options'][i],
              isCorrect: i == q['correctIndex'],
            );
          }),
        );
      }).toList();
    } on SocketException {
      Fluttertoast.showToast(
        msg: "تحقق من اتصال الإنترنت",
      );
      return [];
    } catch (e) {
      Fluttertoast.showToast(
        msg: "حدث خطأ غير متوقع",
      );
      return [];
    }
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
