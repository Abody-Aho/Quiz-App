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
Generate 10 multiple choice questions about:

Category: ${category.title}
Topics: ${category.prompt}

Rules:
- Each question has exactly 4 options
- Only ONE option is correct
- Return ONLY JSON in a valid list format.
- Format:
[
  {
    "question": "text",
    "options": ["A","B","C","D"],
    "correctIndex": 0
  }
]
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
