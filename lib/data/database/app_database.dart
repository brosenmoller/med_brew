import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_dart;
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Categories, Quizzes, Questions, QuizQuestions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(path_dart.join(dir.path, 'med_brew.db'));

      if (!file.existsSync()) {
        final data = await rootBundle.load('assets/seed.db');
        final bytes = data.buffer.asUint8List();
        await file.writeAsBytes(bytes, flush: true);
      }

      return NativeDatabase.createInBackground(file);
    });
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      // Possible future migrations
    },
  );

  // used by the seed export to mark permanent on the copy
  AppDatabase.fromFile(File file) : super(NativeDatabase(file));

  // Mark everything permanent — called on the seed copy, not the live DB
  Future<void> markAllPermanent() async {
    await customUpdate('UPDATE categories SET is_permanent = 1');
    await customUpdate('UPDATE quizzes SET is_permanent = 1');
    await customUpdate('UPDATE questions SET is_permanent = 1');
  }

  // Export all content as a single combined JSON map
  Future<Map<String, dynamic>> exportToJsonMap() async {
    final categories = await getAllCategories();
    final categoriesJson = <Map<String, dynamic>>[];
    final quizzesJson = <Map<String, dynamic>>[];
    final questionsJson = <Map<String, dynamic>>[];
    final seenQuestionIds = <int>{};

    for (final category in categories) {
      final quizList = await getQuizzesForCategory(category.id);
      categoriesJson.add({
        'id': category.id.toString(),
        'title': category.title,
        'imagePath': category.imagePath,
        'quizIds': quizList.map((q) => q.id.toString()).toList(),
      });

      for (final quiz in quizList) {
        final questionList = await getQuestionsForQuiz(quiz.id);
        quizzesJson.add({
          'id': quiz.id.toString(),
          'title': quiz.title,
          'imagePath': quiz.imagePath,
          'questionIds': questionList.map((q) => q.id.toString()).toList(),
        });

        for (final question in questionList) {
          if (seenQuestionIds.contains(question.id)) continue;
          seenQuestionIds.add(question.id);

          final config = jsonDecode(question.answerConfig) as Map<String, dynamic>;
          final questionJson = <String, dynamic>{
            'id': question.id.toString(),
            'questionVariants': question.questionVariants != null
                ? jsonDecode(question.questionVariants!)
                : [question.questionText],
            'answerType': question.answerType,
            'imagePath': question.imagePath,
            'explanation': question.explanation,
          };

          // Store config under the original key names for compatibility
          switch (question.answerType) {
            case 'multipleChoice':
              questionJson['multipleChoiceConfig'] = config;
            case 'typed':
              questionJson['typedAnswerConfig'] = config;
            case 'imageClick':
              questionJson['imageClickConfig'] = config;
          }

          questionsJson.add(questionJson);
        }
      }
    }

    return {
      'categories': categoriesJson,
      'quizzes': quizzesJson,
      'questions': questionsJson,
    };
  }

// Import from the combined JSON format — merges into existing data
  Future<void> importFromJson(Map<String, dynamic> data) async {
    final questionsRaw = data['questions'] as List;
    final quizzesRaw = data['quizzes'] as List;
    final categoriesRaw = data['categories'] as List;

    final Map<String, int> questionIdMap = {};
    final Map<String, int> quizIdMap = {};
    final Map<String, int> categoryIdMap = {};

    // 1 — Questions (no dependencies)
    for (final q in questionsRaw) {
      final answerType = q['answerType'] as String;
      final String answerConfig = switch (answerType) {
        'multipleChoice' => jsonEncode(q['multipleChoiceConfig']),
        'typed'          => jsonEncode(q['typedAnswerConfig']),
        'imageClick'     => jsonEncode(q['imageClickConfig']),
        _                => '{}',
      };

      final variants = (q['questionVariants'] as List?)?.cast<String>();
      final questionText = variants?.first ?? '';

      final newId = await into(questions).insert(QuestionsCompanion.insert(
        questionText: questionText,
        questionVariants: variants != null && variants.length > 1
            ? Value(jsonEncode(variants))
            : const Value.absent(),
        answerType: answerType,
        answerConfig: answerConfig,
        explanation: Value(q['explanation'] as String?),
        imagePath: Value(q['imagePath'] as String?),
      ));
      questionIdMap[q['id'] as String] = newId;
    }

    // 2 — Categories
    for (final category in categoriesRaw) {
      final newId = await insertCategory(CategoriesCompanion.insert(
        title: category['title'] as String,
        imagePath: Value(category['imagePath'] as String?),
      ));
      categoryIdMap[category['id'] as String] = newId;
    }

    // 3 — Quizzes + junction rows
    for (final quiz in quizzesRaw) {
      // Find which category owns this quiz

      final owner = categoriesRaw
          .cast<Map<String, dynamic>>()
          .firstWhere(
            (c) => (c['quizIds'] as List).contains(quiz['id']),
        orElse: () => <String, dynamic>{},
      );

      final ownerCatId = owner['id'] as String?;

      if (ownerCatId == null) continue;
      final catIntId = categoryIdMap[ownerCatId];
      if (catIntId == null) continue;

      final newQuizId = await insertQuiz(QuizzesCompanion.insert(
        categoryId: catIntId,
        title: quiz['title'] as String,
        imagePath: Value(quiz['imagePath'] as String?),
      ));
      quizIdMap[quiz['id'] as String] = newQuizId;

      int order = 0;
      for (final qStringId in (quiz['questionIds'] as List)) {
        final qIntId = questionIdMap[qStringId as String];
        if (qIntId == null) continue;
        await into(quizQuestions).insert(QuizQuestionsCompanion.insert(
          quizId: newQuizId,
          questionId: qIntId,
          sortOrder: Value(order++),
        ));
      }
    }
  }

  // ─── Categories ───────────────────────────────────────────────
  Future<List<Category>> getAllCategories() => select(categories).get();

  Stream<List<Category>> watchAllCategories() => select(categories).watch();

  Future<int> insertCategory(CategoriesCompanion entry) =>
      into(categories).insert(entry);

  Future<bool> updateCategory(CategoriesCompanion entry) =>
      update(categories).replace(entry);

  Future<int> deleteCategory(int id) =>
      (delete(categories)..where((t) => t.id.equals(id))).go();

  // ─── Quizzes ──────────────────────────────────────────────────
  Future<List<Quiz>> getQuizzesForCategory(int categoryId) =>
      (select(quizzes)..where((t) => t.categoryId.equals(categoryId))).get();

  Stream<List<Quiz>> watchQuizzesForCategory(int categoryId) =>
      (select(quizzes)..where((t) => t.categoryId.equals(categoryId))).watch();

  Future<int> insertQuiz(QuizzesCompanion entry) =>
      into(quizzes).insert(entry);

  // ─── Questions ────────────────────────────────────────────────
  Future<List<Question>> getQuestionsForQuiz(int quizId) {
    final query = select(questions).join([
      innerJoin(
        quizQuestions,
        quizQuestions.questionId.equalsExp(questions.id),
      ),
    ])
      ..where(quizQuestions.quizId.equals(quizId))
      ..orderBy([OrderingTerm(expression: quizQuestions.sortOrder)]);

    return query.map((row) => row.readTable(questions)).get();
  }

  // Quizzes
  Future<bool> updateQuiz(QuizzesCompanion entry) =>
      update(quizzes).replace(entry);

  Future<void> deleteQuiz(int id) async {
    // Delete junction rows first, then the quiz itself
    await (delete(quizQuestions)..where((t) => t.quizId.equals(id))).go();
    await (delete(quizzes)..where((t) => t.id.equals(id))).go();
  }

// Questions — stream version for ManageQuestionsScreen
  Stream<List<Question>> watchQuestionsForQuiz(int quizId) {
    final query = select(questions).join([
      innerJoin(
        quizQuestions,
        quizQuestions.questionId.equalsExp(questions.id),
      ),
    ])
      ..where(quizQuestions.quizId.equals(quizId))
      ..orderBy([OrderingTerm(expression: quizQuestions.sortOrder)]);

    return query.map((row) => row.readTable(questions)).watch();
  }

// Reorder — updates the sortOrder of the moved question
  Future<void> reorderQuestion({
    required int quizId,
    required int questionId,
    required int newIndex,
  }) async {
    await (update(quizQuestions)
      ..where((t) =>
      t.quizId.equals(quizId) & t.questionId.equals(questionId)))
        .write(QuizQuestionsCompanion(sortOrder: Value(newIndex)));
  }

  Future<void> insertQuestionIntoQuiz({
    required QuestionsCompanion question,
    required int quizId,
  }) async {
    final questionId = await into(questions).insert(question);
    await into(quizQuestions).insert(
      QuizQuestionsCompanion.insert(
        quizId: quizId,
        questionId: questionId,
      ),
    );
  }

  Future<int> deleteQuestion(int id) =>
      (delete(questions)..where((t) => t.id.equals(id))).go();
}