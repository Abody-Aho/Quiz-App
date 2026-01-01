import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';

import '../core/class/config.dart';
import '../model/model.dart';
import '../secrets.dart';

class GroqAIService {
  Future<List<Question>> generateQuizByCategory(Category category) async {
    if (!await checkIConnection()) {
      Fluttertoast.showToast(
        msg: "لا يوجد اتصال بالإنترنت",
        gravity: ToastGravity.BOTTOM,
      );
      return [];
    }

    final prompt = """
You are an expert exam designer and senior subject-matter specialist.

Generate exactly 10 high-quality, advanced multiple-choice questions based on the following:

Category: ${category.title}
Scope and Topics: ${category.prompt}

Strict requirements:
- Questions must be academically strong, clear, and professionally written.
- Language must be PERFECT and grammatically correct (Arabic or English, matching the category).
- Do NOT mix languages under any circumstances.
- Each question must test deep understanding, not superficial facts.
- Avoid ambiguity, vague wording, or trick questions.
- Do NOT repeat questions, options, or concepts.
- Each question must have EXACTLY 4 distinct options.
- Only ONE option is correct.
- Incorrect options must be plausible but clearly wrong.
- Difficulty level: Medium to Hard (professional / university level).
- Do NOT include explanations, comments, markdown, or extra text.

Output rules (VERY IMPORTANT):
- Return ONLY valid JSON.
- JSON must be a list of exactly 10 objects.
- Follow this format strictly:

[
  {
    "question": "Question text here",
    "options": ["Option A", "Option B", "Option C", "Option D"],
    "correctIndex": 0
  }
]

If the output is not valid JSON, it is considered incorrect.
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
