import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_dart;
import 'package:uuid/uuid.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Folders, Quizzes, Questions, QuizQuestions])
class AppDatabase extends _$AppDatabase {
  /// The single live instance, set once in main.dart via [AppDatabase()].
  static late final AppDatabase instance;

  AppDatabase() : super(_openConnection()) {
    instance = this;
  }

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(path_dart.join(dir.path, 'med_brew.db'));
      return NativeDatabase.createInBackground(file);
    });
  }

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // Create the new folders table (current schema, no is_permanent)
        await m.createTable(folders);

        // Migrate existing categories as root-level folders (IDs preserved)
        await customStatement('''
          INSERT INTO folders (id, parent_folder_id, title, image_path, created_at)
          SELECT id, NULL, title, image_path, created_at
          FROM categories
        ''');

        // Add folder_id column to quizzes (nullable → allows root-level quizzes)
        await m.addColumn(quizzes, quizzes.folderId);

        // Carry the old category_id value forward into folder_id
        await customStatement('UPDATE quizzes SET folder_id = category_id');
      }

      if (from < 3) {
        // Rebuild quizzes table to drop the legacy category_id column
        // (NOT NULL, no default) that caused INSERT failures for new quizzes.
        // SQLite doesn't support DROP COLUMN, so we use table reconstruction.
        await customStatement('''
          CREATE TABLE quizzes_new (
            "id"           INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            "folder_id"    INTEGER,
            "title"        TEXT NOT NULL,
            "image_path"   TEXT,
            "is_permanent" INTEGER NOT NULL DEFAULT 0,
            "created_at"   INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP))
          )
        ''');
        await customStatement('''
          INSERT INTO quizzes_new (id, folder_id, title, image_path, is_permanent, created_at)
          SELECT id, folder_id, title, image_path, is_permanent, created_at
          FROM quizzes
        ''');
        await customStatement('DROP TABLE quizzes');
        await customStatement('ALTER TABLE quizzes_new RENAME TO quizzes');
      }

      if (from < 4) {
        await m.addColumn(quizzes, quizzes.languageCode);
      }

      if (from < 5) {
        await m.addColumn(folders, folders.syncId);
        await m.addColumn(quizzes, quizzes.syncId);
        await m.addColumn(questions, questions.syncId);
        // Back-fill UUIDs for all rows (is_permanent distinction is removed in v6)
        const uuidExpr =
            "lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' || "
            "substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(2))) || "
            "'-' || lower(hex(randomblob(6)))";
        await customStatement(
            'UPDATE folders SET sync_id = $uuidExpr WHERE sync_id IS NULL');
        await customStatement(
            'UPDATE quizzes SET sync_id = $uuidExpr WHERE sync_id IS NULL');
        await customStatement(
            'UPDATE questions SET sync_id = $uuidExpr WHERE sync_id IS NULL');
      }

      if (from < 6) {
        // Drop is_permanent from all three tables via table reconstruction.
        // SQLite does not support DROP COLUMN reliably on older versions.
        await customStatement('''
          CREATE TABLE folders_new (
            "id"               INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            "parent_folder_id" INTEGER,
            "title"            TEXT NOT NULL,
            "image_path"       TEXT,
            "created_at"       INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP)),
            "sync_id"          TEXT
          )
        ''');
        await customStatement('''
          INSERT INTO folders_new (id, parent_folder_id, title, image_path, created_at, sync_id)
          SELECT id, parent_folder_id, title, image_path, created_at, sync_id FROM folders
        ''');
        await customStatement('DROP TABLE folders');
        await customStatement('ALTER TABLE folders_new RENAME TO folders');

        await customStatement('''
          CREATE TABLE quizzes_new (
            "id"            INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            "folder_id"     INTEGER,
            "title"         TEXT NOT NULL,
            "image_path"    TEXT,
            "created_at"    INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP)),
            "language_code" TEXT,
            "sync_id"       TEXT
          )
        ''');
        await customStatement('''
          INSERT INTO quizzes_new (id, folder_id, title, image_path, created_at, language_code, sync_id)
          SELECT id, folder_id, title, image_path, created_at, language_code, sync_id FROM quizzes
        ''');
        await customStatement('DROP TABLE quizzes');
        await customStatement('ALTER TABLE quizzes_new RENAME TO quizzes');

        await customStatement('''
          CREATE TABLE questions_new (
            "id"                INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
            "question_text"     TEXT NOT NULL,
            "question_variants" TEXT,
            "answer_type"       TEXT NOT NULL,
            "answer_config"     TEXT NOT NULL,
            "explanation"       TEXT,
            "image_path"        TEXT,
            "sync_id"           TEXT
          )
        ''');
        await customStatement('''
          INSERT INTO questions_new (id, question_text, question_variants, answer_type, answer_config, explanation, image_path, sync_id)
          SELECT id, question_text, question_variants, answer_type, answer_config, explanation, image_path, sync_id FROM questions
        ''');
        await customStatement('DROP TABLE questions');
        await customStatement('ALTER TABLE questions_new RENAME TO questions');
      }
    },
  );

  // ─── Export ───────────────────────────────────────────────────

  Future<Map<String, dynamic>> exportToJsonMap() async {
    final allFolders = await getAllFolders();
    final allQuizzes = await getAllQuizzes();

    final foldersJson = allFolders.map((f) => {
      'id': f.id.toString(),
      'syncId': f.syncId,
      'parentFolderId': f.parentFolderId?.toString(),
      'title': f.title,
      'imagePath': f.imagePath,
    }).toList();

    final quizzesAndQuestions = await _buildJsonForQuizzes(allQuizzes);

    return {
      'folders': foldersJson,
      'quizzes': quizzesAndQuestions['quizzes'],
      'questions': quizzesAndQuestions['questions'],
    };
  }

  Future<Map<String, dynamic>> exportFolderToJsonMap(int folderId) async {
    final folderIds = await _collectFolderSubtree(folderId);
    final folderList = <Folder>[];
    for (final id in folderIds) {
      final f = await (select(folders)..where((t) => t.id.equals(id))).getSingleOrNull();
      if (f != null) folderList.add(f);
    }
    final folderIdsList = folderIds.toList();
    final quizList = await (select(quizzes)
      ..where((t) => t.folderId.isIn(folderIdsList))).get();

    final foldersJson = folderList.map((f) => {
      'id': f.id.toString(),
      'syncId': f.syncId,
      'parentFolderId': f.parentFolderId?.toString(),
      'title': f.title,
      'imagePath': f.imagePath,
    }).toList();

    final quizzesAndQuestions = await _buildJsonForQuizzes(quizList);

    return {
      'folders': foldersJson,
      'quizzes': quizzesAndQuestions['quizzes'],
      'questions': quizzesAndQuestions['questions'],
    };
  }

  Future<Map<String, dynamic>> exportQuizToJsonMap(int quizId) async {
    final quiz = await (select(quizzes)..where((t) => t.id.equals(quizId))).getSingleOrNull();
    if (quiz == null) return {'folders': [], 'quizzes': [], 'questions': []};
    final quizzesAndQuestions = await _buildJsonForQuizzes([quiz]);
    return {
      'folders': <Map<String, dynamic>>[],
      'quizzes': quizzesAndQuestions['quizzes'],
      'questions': quizzesAndQuestions['questions'],
    };
  }

  /// Collects the given folder and all its descendants, returning their IDs.
  Future<Set<int>> _collectFolderSubtree(int folderId) async {
    final result = <int>{folderId};
    final children = await (select(folders)
      ..where((t) => t.parentFolderId.equals(folderId))).get();
    for (final child in children) {
      result.addAll(await _collectFolderSubtree(child.id));
    }
    return result;
  }

  /// Builds the quizzes + questions JSON for the given list of quizzes.
  Future<Map<String, List<Map<String, dynamic>>>> _buildJsonForQuizzes(
      List<Quiz> quizList) async {
    final seenQuestionIds = <int>{};
    final quizzesJson = <Map<String, dynamic>>[];
    final questionsJson = <Map<String, dynamic>>[];

    for (final quiz in quizList) {
      final questionList = await getQuestionsForQuiz(quiz.id);
      quizzesJson.add({
        'id': quiz.id.toString(),
        'syncId': quiz.syncId,
        'folderId': quiz.folderId?.toString(),
        'title': quiz.title,
        'imagePath': quiz.imagePath,
        'languageCode': quiz.languageCode,
        'questionIds': questionList.map((q) => q.id.toString()).toList(),
        'questionSyncIds': questionList.map((q) => q.syncId).toList(),
      });

      for (final question in questionList) {
        if (seenQuestionIds.contains(question.id)) continue;
        seenQuestionIds.add(question.id);

        final config = jsonDecode(question.answerConfig) as Map<String, dynamic>;
        final questionJson = <String, dynamic>{
          'id': question.id.toString(),
          'syncId': question.syncId,
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

    return {'quizzes': quizzesJson, 'questions': questionsJson};
  }

  // ─── Import ───────────────────────────────────────────────────

  /// Imports content from a JSON map.
  /// Returns the number of new items inserted.
  /// Items whose syncId is already present in the DB are skipped (idempotent).
  Future<int> importFromJson(Map<String, dynamic> data) async {
    int inserted = 0;

    await transaction(() async {
      final questionsRaw = data['questions'] as List;
      final quizzesRaw = data['quizzes'] as List;

      final Map<String, int> questionIdMap = {};
      final Map<String, int> folderIdMap = {};

      // 1 — Questions (no dependencies)
      for (final q in questionsRaw) {
        final importedId = q['id'] as String;
        final syncId = q['syncId'] as String?;

        if (syncId != null) {
          final existing = await getQuestionBySyncId(syncId);
          if (existing != null) {
            questionIdMap[importedId] = existing.id;
            continue;
          }
        }

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

        final newId = await insertQuestion(QuestionsCompanion.insert(
          questionText: questionText,
          questionVariants: variants != null && variants.length > 1
              ? Value(jsonEncode(variants))
              : const Value.absent(),
          answerType: answerType,
          answerConfig: answerConfig,
          explanation: Value(q['explanation'] as String?),
          imagePath: Value(q['imagePath'] as String?),
          syncId: syncId != null ? Value(syncId) : const Value.absent(),
        ));
        questionIdMap[importedId] = newId;
        inserted++;
      }

      // 2 — Folders
      if (data.containsKey('folders')) {
        final foldersRaw = data['folders'] as List;
        // First pass: insert all folders without parent
        for (final f in foldersRaw) {
          final importedId = f['id'] as String;
          final syncId = f['syncId'] as String?;

          if (syncId != null) {
            final existing = await getFolderBySyncId(syncId);
            if (existing != null) {
              folderIdMap[importedId] = existing.id;
              continue;
            }
          }

          final newId = await insertFolder(FoldersCompanion.insert(
            title: f['title'] as String,
            imagePath: Value(f['imagePath'] as String?),
            syncId: syncId != null ? Value(syncId) : const Value.absent(),
          ));
          folderIdMap[importedId] = newId;
          inserted++;
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
          inserted++;
        }
      }

      // 3 — Quizzes + junction rows
      for (final quiz in quizzesRaw) {
        final importedId = quiz['id'] as String;
        final syncId = quiz['syncId'] as String?;

        if (syncId != null) {
          final existing = await getQuizBySyncId(syncId);
          if (existing != null) {
            // Quiz already exists — skip entirely (junction rows already set)
            continue;
          }
        }

        int? targetFolderId;
        if (quiz.containsKey('folderId') && quiz['folderId'] != null) {
          targetFolderId = folderIdMap[quiz['folderId'] as String];
        } else if (data.containsKey('categories')) {
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
          languageCode: Value(quiz['languageCode'] as String?),
          syncId: syncId != null ? Value(syncId) : const Value.absent(),
        ));
        inserted++;

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

    return inserted;
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

  Future<int> insertFolder(FoldersCompanion entry) async {
    final id = await into(folders).insert(entry);
    // Auto-assign UUID if syncId was not provided
    if (!entry.syncId.present) {
      await (update(folders)..where((t) => t.id.equals(id)))
          .write(FoldersCompanion(syncId: Value(const Uuid().v4())));
    }
    return id;
  }

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

  Future<int> insertQuiz(QuizzesCompanion entry) async {
    final id = await into(quizzes).insert(entry);
    if (!entry.syncId.present) {
      await (update(quizzes)..where((t) => t.id.equals(id)))
          .write(QuizzesCompanion(syncId: Value(const Uuid().v4())));
    }
    return id;
  }

  Future<bool> updateQuiz(QuizzesCompanion entry) =>
      update(quizzes).replace(entry);

  Future<void> deleteQuiz(int id) async {
    await (delete(quizQuestions)..where((t) => t.quizId.equals(id))).go();
    await (delete(quizzes)..where((t) => t.id.equals(id))).go();
  }

  // ─── Questions ────────────────────────────────────────────────

  Future<List<Question>> getAllQuestions() => select(questions).get();

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

  Future<int> insertQuestion(QuestionsCompanion question) async {
    final questionId = await into(questions).insert(question);
    if (!question.syncId.present) {
      await (update(questions)..where((t) => t.id.equals(questionId)))
          .write(QuestionsCompanion(syncId: Value(const Uuid().v4())));
    }
    return questionId;
  }

  Future<void> insertQuestionIntoQuiz({
    required QuestionsCompanion question,
    required int quizId,
  }) async {
    final questionId = await insertQuestion(question);
    await into(quizQuestions).insert(
      QuizQuestionsCompanion.insert(
        quizId: quizId,
        questionId: questionId,
      ),
    );
  }

  Future<int> deleteQuestion(int id) =>
      (delete(questions)..where((t) => t.id.equals(id))).go();

  // ─── Sync helpers ─────────────────────────────────────────────

  Future<Folder?> getFolderBySyncId(String syncId) =>
      (select(folders)..where((t) => t.syncId.equals(syncId))).getSingleOrNull();

  Future<Quiz?> getQuizBySyncId(String syncId) =>
      (select(quizzes)..where((t) => t.syncId.equals(syncId))).getSingleOrNull();

  Future<Question?> getQuestionBySyncId(String syncId) =>
      (select(questions)..where((t) => t.syncId.equals(syncId))).getSingleOrNull();

  Future<String?> getFolderSyncIdById(int id) async {
    final row = await (select(folders)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.syncId;
  }

  Future<String?> getQuizSyncIdById(int id) async {
    final row = await (select(quizzes)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.syncId;
  }

  Future<String?> getQuestionSyncIdById(int id) async {
    final row = await (select(questions)..where((t) => t.id.equals(id))).getSingleOrNull();
    return row?.syncId;
  }

  Future<int> insertFolderForSync({
    required String syncId,
    required String title,
    String? imagePath,
  }) =>
      into(folders).insert(FoldersCompanion.insert(
        title: title,
        imagePath: Value(imagePath),
        syncId: Value(syncId),
      ));

  Future<int> insertQuizForSync({
    required String syncId,
    required String title,
    int? folderId,
    String? imagePath,
    String? languageCode,
  }) =>
      into(quizzes).insert(QuizzesCompanion.insert(
        title: title,
        folderId: Value(folderId),
        imagePath: Value(imagePath),
        languageCode: Value(languageCode),
        syncId: Value(syncId),
      ));

  Future<int> insertQuestionForSync({
    required String syncId,
    required String questionText,
    String? questionVariants,
    required String answerType,
    required String answerConfig,
    String? explanation,
    String? imagePath,
  }) =>
      into(questions).insert(QuestionsCompanion.insert(
        questionText: questionText,
        questionVariants:
            questionVariants != null ? Value(questionVariants) : const Value.absent(),
        answerType: answerType,
        answerConfig: answerConfig,
        explanation: Value(explanation),
        imagePath: Value(imagePath),
        syncId: Value(syncId),
      ));

  Future<void> updateFolderParentId(int folderId, int parentFolderId) =>
      (update(folders)..where((t) => t.id.equals(folderId)))
          .write(FoldersCompanion(parentFolderId: Value(parentFolderId)));

  /// Deletes every row from every content table. Used by the dev wipe tool.
  Future<void> wipeAllContent() => transaction(() async {
        await delete(quizQuestions).go();
        await delete(questions).go();
        await delete(quizzes).go();
        await delete(folders).go();
      });

  Future<void> insertJunctionRowSafe(int quizId, int questionId, int sortOrder) async {
    try {
      await into(quizQuestions).insert(QuizQuestionsCompanion.insert(
        quizId: quizId,
        questionId: questionId,
        sortOrder: Value(sortOrder),
      ));
    } catch (_) {} // Ignore duplicate junction rows
  }
}
