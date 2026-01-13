import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class QuizCacheService {
  // أضفنا اللغة للمفتاح لتمييز الاختبارات
  static String _key(String categoryId, String level, String language) {
    return 'quiz_${categoryId}_${level}_$language';
  }

  static Future<void> saveQuiz({
    required String categoryId,
    required String level,
    required String language, // أضفنا اللغة هنا
    required List<Map<String, dynamic>> quiz,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key(categoryId, level, language),
      jsonEncode(quiz),
    );
  }

  static Future<List<Map<String, dynamic>>?> loadQuiz({
    required String categoryId,
    required String level,
    required String language, // أضفنا اللغة هنا
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key(categoryId, level, language));
    if (jsonString == null) return null;
    return List<Map<String, dynamic>>.from(
      jsonDecode(jsonString),
    );
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
