// lib/models/incorrect_answer_model.dart
// ---------------------------------------
// This model is used to store information about an incorrect answer
// for one question in the Formula Race App.
//
// Fields:
// - question      → the question text that was asked.
// - userAnswer    → the answer selected by the user.
// - correctAnswer → the actual correct answer.
//
// We use this model to easily pass the incorrect answers list
// from SoloPlayScreen to SummaryScreen.

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class IncorrectAnswer {
  final String question;
  final String userAnswer;
  final String correctAnswer;
  String tip;
  final String imagePath;

  IncorrectAnswer({
    required this.question,
    required this.userAnswer,
    required this.correctAnswer,
    required this.tip,
    required this.imagePath,
  });

  Map<String, dynamic> toJson() => {
    'question': question,
    'userAnswer': userAnswer,
    'correctAnswer': correctAnswer,
    'tip': tip,
  };

  factory IncorrectAnswer.fromJson(Map<String, dynamic> json) {
    return IncorrectAnswer(
      question: json['question'],
      userAnswer: json['userAnswer'],
      correctAnswer: json['correctAnswer'],
      tip: json['tip'] ?? '',
      imagePath: json['imagePath'] ?? '',
    );
  }
}

class IncorrectAnswerManager {
  static const String _key = 'incorrect_answers';

  static Future<void> addIncorrectQuestion(Map<String, dynamic> question, String selectedAnswer) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> storedList = prefs.getStringList(_key) ?? [];

    final existing = storedList.any((item) {
      final q = jsonDecode(item);
      return q['question'] == question['question'];
    });

    if (!existing) {
      final newEntry = jsonEncode({
        'question': question['question'],
        'userAnswer': selectedAnswer,
        'correctAnswer': question['answer'],
      });
      storedList.add(newEntry);
      await prefs.setStringList(_key, storedList);
    }
  }

  static Future<List<IncorrectAnswer>> getIncorrectQuestions() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> storedList = prefs.getStringList(_key) ?? [];

    return storedList.map((item) {
      final Map<String, dynamic> json = jsonDecode(item);
      return IncorrectAnswer.fromJson(json);
    }).toList();
  }

  static Future<void> removeIncorrectQuestion(Map<String, dynamic> questionToRemove) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> storedList = prefs.getStringList(_key) ?? [];

    final updatedList = storedList.where((item) {
      final q = jsonDecode(item);
      return q['question'] != questionToRemove['question'];
    }).toList();

    await prefs.setStringList(_key, updatedList);
  }
}
