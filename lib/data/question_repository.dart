import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:med_brew/models/answer_type.dart';
import 'package:med_brew/models/question_data.dart';

class QuestionRepository {
  static List<QuestionData> _questions = [];

  /// Load questions from JSON asset
  static Future<void> loadQuestions(String assetPath) async {
    final jsonString = await rootBundle.loadString(assetPath);
    final List<dynamic> jsonData = json.decode(jsonString);
    _questions = jsonData.map((q) => QuestionData.fromJson(q)).toList();
  }

  /// Get all questions
  static List<QuestionData> get allQuestions => _questions;

  /// Filter questions by tag
  static List<QuestionData> byTag(String tag) => _questions.where((q) => q.quizTags.contains(tag)).toList();

  /// Filter questions by type
  static List<QuestionData> byType(AnswerType type) => _questions.where((q) => q.answerType == type).toList();
}