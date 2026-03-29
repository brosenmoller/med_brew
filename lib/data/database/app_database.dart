import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Categories, Quizzes, Questions, QuizQuestions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'med_brew.db'));
      return NativeDatabase.createInBackground(file);
    });
  }
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedPermanentData();
    },
  );

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

  // ─── Seed permanent/built-in data ─────────────────────────────
  Future<void> _seedPermanentData() async {
    // Category
    final skeletonId = await insertCategory(CategoriesCompanion.insert(
      title: 'Skeleton',
      imagePath: Value('assets/images/skull.jpg'),
      isPermanent: const Value(true),
    ));

    // Quiz
    final femurQuizId = await insertQuiz(QuizzesCompanion.insert(
      categoryId: skeletonId,
      title: 'Femur Quiz',
      isPermanent: const Value(true),
    ));

    // Question
    await insertQuestionIntoQuiz(
      quizId: femurQuizId,
      question: QuestionsCompanion.insert(
        questionText: 'What is the longest bone?',
        answerType: 'multipleChoice',
        answerConfig: '{"options":["Femur","Tibia","Humerus","Fibula"],"correctIndex":0}',
        explanation: const Value('The femur is the longest bone in the human body.'),
        isPermanent: const Value(true),
      ),
    );
  }
}