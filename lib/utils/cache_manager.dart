import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CacheManager {
  static Future<void> cacheTests(List<Map<String, dynamic>> tests) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cached_tests', jsonEncode(tests));
    await prefs.setString('tests_cached_at', DateTime.now().toIso8601String());
  }

  static Future<List<Map<String, dynamic>>?> getCachedTests() async {
    final prefs = await SharedPreferences.getInstance();
    final String? testsJson = prefs.getString('cached_tests');

    if (testsJson != null) {
      List<dynamic> decoded = jsonDecode(testsJson);
      return decoded.map((item) => item as Map<String, dynamic>).toList();
    }
    return null;
  }

  static Future<void> cacheTestQuestions(int testId, List<Map<String, dynamic>> questions) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('test_$testId', jsonEncode(questions));
  }

  static Future<List<Map<String, dynamic>>?> getCachedTestQuestions(int testId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? questionsJson = prefs.getString('test_$testId');

    if (questionsJson != null) {
      List<dynamic> decoded = jsonDecode(questionsJson);
      return decoded.map((item) => item as Map<String, dynamic>).toList();
    }
    return null;
  }
}