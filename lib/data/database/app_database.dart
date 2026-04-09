import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_dart;
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Folders, Quizzes, Questions, QuizQuestions])
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
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // Create the new folders table
        await m.createTable(folders);

        // Migrate existing categories as root-level folders (IDs preserved)
        await customStatement('''
          INSERT INTO folders (id, parent_folder_id, title, image_path, is_permanent, created_at)
          SELECT id, NULL, title, image_path, is_permanent, created_at
          FROM categories
        ''');

        // Add folder_id column to quizzes (nullable → allows root-level quizzes)
        await m.addColumn(quizzes, quizzes.folderId);

        // Carry the old category_id value forward into folder_id
        await customStatement('UPDATE quizzes SET folder_id = category_id');
      }
    },
  );

  // Used by the seed export to mark permanent on the copy
  AppDatabase.fromFile(File file) : super(NativeDatabase(file));

  // Mark everything permanent — called on the seed copy, not the live DB
  Future<void> markAllPermanent() async {
    await customUpdate('UPDATE folders SET is_permanent = 1');
    await customUpdate('UPDATE quizzes SET is_permanent = 1');
    await customUpdate('UPDATE questions SET is_permanent = 1');
  }

  // ─── Export ───────────────────────────────────────────────────

  Future<Map<String, dynamic>> exportToJsonMap() async {
    final allFolders = await getAllFolders();
    final allQuizzes = await getAllQuizzes();
    final seenQuestionIds = <int>{};

    final foldersJson = allFolders.map((f) => {
      'id': f.id.toString(),
      'parentFolderId': f.parentFolderId?.toString(),
      'title': f.title,
      'imagePath': f.imagePath,
    }).toList();

    final quizzesJson = <Map<String, dynamic>>[];
    final questionsJson = <Map<String, dynamic>>[];

    for (final quiz in allQuizzes) {
      final questionList = await getQuestionsForQuiz(quiz.id);
      quizzesJson.add({
        'id': quiz.id.toString(),
        'folderId': quiz.folderId?.toString(),
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

        switch (question.answerType) {
          case 'multipleChoice':
            questionJson['multipleChoiceConfig'] = config;
          case 'typed':
            questionJson['typedAnswerConfig'] = config;
          case 'imageClick':
            questionJson['imageClickConfig'] = config;
          case 'flashcard':
            questionJson['flashcardConfig'] = config;
        }

        questionsJson.add(questionJson);
      }
    }

    return {
      'folders': foldersJson,
      'quizzes': quizzesJson,
      'questions': questionsJson,
    };
  }

  // ─── Import ───────────────────────────────────────────────────

  Future<void> importFromJson(Map<String, dynamic> data) async {
    await transaction(() async {
      final questionsRaw = data['questions'] as List;
      final quizzesRaw = data['quizzes'] as List;

      final Map<String, int> questionIdMap = {};
      final Map<String, int> quizIdMap = {};
      final Map<String, int> folderIdMap = {};

      // 1 — Questions (no dependencies)
      for (final q in questionsRaw) {
        final answerType = q['answerType'] as String;
        final String answerConfig = switch (answerType) {
          'multipleChoice' => jsonEncode(q['multipleChoiceConfig']),
          'typed'          => jsonEncode(q['typedAnswerConfig']),
          'imageClick'     => jsonEncode(q['imageClickConfig']),
          'flashcard'      => jsonEncode(q['flashcardConfig']),
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

      // 2 — Folders (handle both new 'folders' format and legacy 'categories')
      if (data.containsKey('folders')) {
        // New format — two-pass to handle parent references
        final foldersRaw = data['folders'] as List;
        // First pass: insert all folders without parent
        for (final f in foldersRaw) {
          final newId = await insertFolder(FoldersCompanion.insert(
            title: f['title'] as String,
            imagePath: Value(f['imagePath'] as String?),
          ));
          folderIdMap[f['id'] as String] = newId;
        }
        // Second pass: set parent_folder_id
        for (final f in foldersRaw) {
          final parentIdStr = f['parentFolderId'] as String?;
          if (parentIdStr != null) {
            final newId = folderIdMap[f['id'] as String]!;
            final newParentId = folderIdMap[parentIdStr];
            if (newParentId != null) {
              await (update(folders)..where((t) => t.id.equals(newId)))
                  .write(FoldersCompanion(parentFolderId: Value(newParentId)));
            }
          }
        }
      } else if (data.containsKey('categories')) {
        // Legacy format — import categories as root folders
        final categoriesRaw = data['categories'] as List;
        for (final c in categoriesRaw) {
          final newId = await insertFolder(FoldersCompanion.insert(
            title: c['title'] as String,
            imagePath: Value(c['imagePath'] as String?),
          ));
          folderIdMap[c['id'] as String] = newId;
        }
      }

      // 3 — Quizzes + junction rows
      for (final quiz in quizzesRaw) {
        // Determine which folder owns this quiz
        int? targetFolderId;

        if (quiz.containsKey('folderId') && quiz['folderId'] != null) {
          // New format
          targetFolderId = folderIdMap[quiz['folderId'] as String];
        } else if (data.containsKey('categories')) {
          // Legacy: find which category listed this quiz
          final categoriesRaw = data['categories'] as List;
          final owner = categoriesRaw
              .cast<Map<String, dynamic>>()
              .firstWhere(
                (c) => (c['quizIds'] as List).contains(quiz['id']),
                orElse: () => <String, dynamic>{},
              );
          final ownerCatId = owner['id'] as String?;
          if (ownerCatId != null) {
            targetFolderId = folderIdMap[ownerCatId];
          }
        }

        final newQuizId = await insertQuiz(QuizzesCompanion.insert(
          folderId: Value(targetFolderId),
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
    });
  }

  // ─── Folders ──────────────────────────────────────────────────

  Future<List<Folder>> getAllFolders() => select(folders).get();

  Stream<List<Folder>> watchAllFolders() => select(folders).watch();

  Stream<List<Folder>> watchSubfolders(int? parentId) {
    if (parentId == null) {
      return (select(folders)..where((t) => t.parentFolderId.isNull())).watch();
    }
    return (select(folders)..where((t) => t.parentFolderId.equals(parentId))).watch();
  }

  Future<int> insertFolder(FoldersCompanion entry) =>
      into(folders).insert(entry);

  Future<bool> updateFolder(FoldersCompanion entry) =>
      update(folders).replace(entry);

  Future<void> deleteFolder(int id) async {
    // Recursively delete subfolders
    final subs = await (select(folders)
      ..where((t) => t.parentFolderId.equals(id))).get();
    for (final sub in subs) {
      await deleteFolder(sub.id);
    }
    // Delete quizzes in this folder
    final quizzesInFolder = await (select(quizzes)
      ..where((t) => t.folderId.equals(id))).get();
    for (final quiz in quizzesInFolder) {
      await deleteQuiz(quiz.id);
    }
    await (delete(folders)..where((t) => t.id.equals(id))).go();
  }

  // ─── Quizzes ──────────────────────────────────────────────────

  Future<List<Quiz>> getAllQuizzes() => select(quizzes).get();

  Stream<List<Quiz>> watchQuizzesInFolder(int? folderId) {
    if (folderId == null) {
      return (select(quizzes)..where((t) => t.folderId.isNull())).watch();
    }
    return (select(quizzes)..where((t) => t.folderId.equals(folderId))).watch();
  }

  Future<int> insertQuiz(QuizzesCompanion entry) =>
      into(quizzes).insert(entry);

  Future<bool> updateQuiz(QuizzesCompanion entry) =>
      update(quizzes).replace(entry);

  Future<void> deleteQuiz(int id) async {
    await (delete(quizQuestions)..where((t) => t.quizId.equals(id))).go();
    await (delete(quizzes)..where((t) => t.id.equals(id))).go();
  }

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
