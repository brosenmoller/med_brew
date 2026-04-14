import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path_dart;
import 'package:uuid/uuid.dart';
import 'package:med_brew/utils/app_storage.dart';
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
      final dir = await getAppStorageDir();
      final file = File(path_dart.join(dir.path, 'med_brew.db'));
      return NativeDatabase.createInBackground(file);
    });
  }

  @override
  int get schemaVersion => 8;

  // UUID generation expression for SQLite
  static const _uuidExpr =
      "lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' || "
      "substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(2))) || "
      "'-' || lower(hex(randomblob(6)))";

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
        // Add sync_id columns and back-fill UUIDs
        await customStatement('ALTER TABLE folders ADD COLUMN sync_id TEXT');
        await customStatement('ALTER TABLE quizzes ADD COLUMN sync_id TEXT');
        await customStatement('ALTER TABLE questions ADD COLUMN sync_id TEXT');
        await customStatement(
            'UPDATE folders SET sync_id = $_uuidExpr WHERE sync_id IS NULL');
        await customStatement(
            'UPDATE quizzes SET sync_id = $_uuidExpr WHERE sync_id IS NULL');
        await customStatement(
            'UPDATE questions SET sync_id = $_uuidExpr WHERE sync_id IS NULL');
      }

      if (from < 6) {
        // Drop is_permanent from all three tables via table reconstruction.
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

      if (from < 7) {
        // Promote syncId to be the primary key (UUID-only IDs).
        // Drop old int autoincrement PKs; TEXT UUIDs become the sole identity.
        await customStatement('PRAGMA foreign_keys = OFF');

        // Step 1: rename old tables
        await customStatement('ALTER TABLE folders RENAME TO folders_v6');
        await customStatement('ALTER TABLE quizzes RENAME TO quizzes_v6');
        await customStatement('ALTER TABLE questions RENAME TO questions_v6');
        await customStatement(
            'ALTER TABLE quiz_questions RENAME TO quiz_questions_v6');

        // Step 2: create new tables with TEXT PKs
        await customStatement('''
          CREATE TABLE "folders" (
            "id"               TEXT NOT NULL,
            "parent_folder_id" TEXT,
            "title"            TEXT NOT NULL,
            "image_path"       TEXT,
            "created_at"       INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP)),
            PRIMARY KEY ("id")
          )
        ''');
        await customStatement('''
          CREATE TABLE "questions" (
            "id"                TEXT NOT NULL,
            "question_text"     TEXT NOT NULL,
            "question_variants" TEXT,
            "answer_type"       TEXT NOT NULL,
            "answer_config"     TEXT NOT NULL,
            "explanation"       TEXT,
            "image_path"        TEXT,
            PRIMARY KEY ("id")
          )
        ''');
        await customStatement('''
          CREATE TABLE "quizzes" (
            "id"            TEXT NOT NULL,
            "folder_id"     TEXT,
            "title"         TEXT NOT NULL,
            "image_path"    TEXT,
            "created_at"    INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP)),
            "language_code" TEXT,
            PRIMARY KEY ("id")
          )
        ''');
        await customStatement('''
          CREATE TABLE "quiz_questions" (
            "quiz_id"     TEXT NOT NULL REFERENCES "quizzes"("id"),
            "question_id" TEXT NOT NULL REFERENCES "questions"("id"),
            "sort_order"  INTEGER NOT NULL DEFAULT 0,
            PRIMARY KEY ("quiz_id", "question_id")
          )
        ''');

        // Step 3: copy data — use COALESCE(sync_id, new uuid) as new TEXT id
        // Folders: resolve parent_folder_id via JOIN on old int id
        await customStatement('''
          INSERT INTO "folders" (id, parent_folder_id, title, image_path, created_at)
          SELECT
            COALESCE(f.sync_id, $_uuidExpr),
            p.sync_id,
            f.title,
            f.image_path,
            f.created_at
          FROM folders_v6 f
          LEFT JOIN folders_v6 p ON f.parent_folder_id = p.id
        ''');

        // Questions (no FK dependencies)
        await customStatement('''
          INSERT INTO "questions" (id, question_text, question_variants, answer_type, answer_config, explanation, image_path)
          SELECT
            COALESCE(sync_id, $_uuidExpr),
            question_text,
            question_variants,
            answer_type,
            answer_config,
            explanation,
            image_path
          FROM questions_v6
        ''');

        // Quizzes: resolve folder_id via JOIN on old int id
        await customStatement('''
          INSERT INTO "quizzes" (id, folder_id, title, image_path, created_at, language_code)
          SELECT
            COALESCE(qz.sync_id, $_uuidExpr),
            f.sync_id,
            qz.title,
            qz.image_path,
            qz.created_at,
            qz.language_code
          FROM quizzes_v6 qz
          LEFT JOIN folders_v6 f ON qz.folder_id = f.id
        ''');

        // QuizQuestions: resolve both FKs via JOIN
        await customStatement('''
          INSERT INTO "quiz_questions" (quiz_id, question_id, sort_order)
          SELECT
            qz.sync_id,
            q.sync_id,
            qq.sort_order
          FROM quiz_questions_v6 qq
          JOIN quizzes_v6 qz ON qq.quiz_id = qz.id
          JOIN questions_v6 q ON qq.question_id = q.id
        ''');

        // Step 4: drop old tables
        await customStatement('DROP TABLE quiz_questions_v6');
        await customStatement('DROP TABLE quizzes_v6');
        await customStatement('DROP TABLE questions_v6');
        await customStatement('DROP TABLE folders_v6');

        await customStatement('PRAGMA foreign_keys = ON');
      }

      if (from < 8) {
        await m.addColumn(questions, questions.imagePathVariants);
      }
    },
  );

  // ─── Export ───────────────────────────────────────────────────

  Future<Map<String, dynamic>> exportToJsonMap() async {
    final allFolders = await getAllFolders();
    final allQuizzes = await getAllQuizzes();

    final foldersJson = allFolders.map((f) => {
      'id': f.id,
      'parentFolderId': f.parentFolderId,
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

  Future<Map<String, dynamic>> exportFolderToJsonMap(String folderId) async {
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
      'id': f.id,
      'parentFolderId': f.parentFolderId,
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

  Future<Map<String, dynamic>> exportQuizToJsonMap(String quizId) async {
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
  Future<Set<String>> _collectFolderSubtree(String folderId) async {
    final result = <String>{folderId};
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
    final seenQuestionIds = <String>{};
    final quizzesJson = <Map<String, dynamic>>[];
    final questionsJson = <Map<String, dynamic>>[];

    for (final quiz in quizList) {
      final questionList = await getQuestionsForQuiz(quiz.id);
      quizzesJson.add({
        'id': quiz.id,
        'folderId': quiz.folderId,
        'title': quiz.title,
        'imagePath': quiz.imagePath,
        'languageCode': quiz.languageCode,
        'questionIds': questionList.map((q) => q.id).toList(),
      });

      for (final question in questionList) {
        if (seenQuestionIds.contains(question.id)) continue;
        seenQuestionIds.add(question.id);

        final config = jsonDecode(question.answerConfig) as Map<String, dynamic>;
        final questionJson = <String, dynamic>{
          'id': question.id,
          'questionVariants': question.questionVariants != null
              ? jsonDecode(question.questionVariants!)
              : [question.questionText],
          'answerType': question.answerType,
          'imagePath': question.imagePath,
          'imagePathVariants': question.imagePathVariants != null
              ? jsonDecode(question.imagePathVariants!)
              : null,
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
  /// Items whose id is already present in the DB are skipped (idempotent).
  Future<int> importFromJson(Map<String, dynamic> data) async {
    int inserted = 0;

    await transaction(() async {
      final questionsRaw = data['questions'] as List;
      final quizzesRaw = data['quizzes'] as List;

      final Map<String, String> questionIdMap = {};
      final Map<String, String> folderIdMap = {};

      // 1 — Questions (no dependencies)
      for (final q in questionsRaw) {
        final importedId = q['id'] as String;

        final existing = await getQuestionById(importedId);
        if (existing != null) {
          questionIdMap[importedId] = existing.id;
          continue;
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

        final importedVariants = q['imagePathVariants'] as List?;
        final newId = await insertQuestion(QuestionsCompanion(
          id: Value(importedId),
          questionText: Value(questionText),
          questionVariants: variants != null && variants.length > 1
              ? Value(jsonEncode(variants))
              : const Value.absent(),
          answerType: Value(answerType),
          answerConfig: Value(answerConfig),
          explanation: Value(q['explanation'] as String?),
          imagePath: Value(q['imagePath'] as String?),
          imagePathVariants: importedVariants != null
              ? Value(jsonEncode(importedVariants.cast<String>()))
              : const Value.absent(),
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

          final existing = await getFolderById(importedId);
          if (existing != null) {
            folderIdMap[importedId] = existing.id;
            continue;
          }

          final newId = await insertFolder(FoldersCompanion(
            id: Value(importedId),
            title: Value(f['title'] as String),
            imagePath: Value(f['imagePath'] as String?),
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
          final newId = await insertFolder(FoldersCompanion(
            title: Value(c['title'] as String),
            imagePath: Value(c['imagePath'] as String?),
          ));
          folderIdMap[c['id'] as String] = newId;
          inserted++;
        }
      }

      // 3 — Quizzes + junction rows
      for (final quiz in quizzesRaw) {
        final importedId = quiz['id'] as String;

        final existing = await getQuizById(importedId);
        if (existing != null) {
          // Quiz already exists — skip entirely (junction rows already set)
          continue;
        }

        String? targetFolderId;
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

        final newQuizId = await insertQuiz(QuizzesCompanion(
          id: Value(importedId),
          folderId: Value(targetFolderId),
          title: Value(quiz['title'] as String),
          imagePath: Value(quiz['imagePath'] as String?),
          languageCode: Value(quiz['languageCode'] as String?),
        ));
        inserted++;

        // Support both new 'questionIds' and legacy 'questionSyncIds'
        final questionIdList = (quiz['questionIds'] ?? quiz['questionSyncIds']) as List? ?? [];
        int order = 0;
        for (final qStringId in questionIdList) {
          final qId = questionIdMap[qStringId as String];
          if (qId == null) continue;
          await into(quizQuestions).insert(QuizQuestionsCompanion.insert(
            quizId: newQuizId,
            questionId: qId,
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

  Stream<List<Folder>> watchSubfolders(String? parentId) {
    if (parentId == null) {
      return (select(folders)..where((t) => t.parentFolderId.isNull())).watch();
    }
    return (select(folders)..where((t) => t.parentFolderId.equals(parentId))).watch();
  }

  Future<String> insertFolder(FoldersCompanion entry) async {
    final id = entry.id.present ? entry.id.value : const Uuid().v4();
    await into(folders).insert(entry.copyWith(id: Value(id)));
    return id;
  }

  Future<bool> updateFolder(FoldersCompanion entry) =>
      update(folders).replace(entry);

  Future<void> deleteFolder(String id) async {
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

  Stream<List<Quiz>> watchQuizzesInFolder(String? folderId) {
    if (folderId == null) {
      return (select(quizzes)..where((t) => t.folderId.isNull())).watch();
    }
    return (select(quizzes)..where((t) => t.folderId.equals(folderId))).watch();
  }

  Future<String> insertQuiz(QuizzesCompanion entry) async {
    final id = entry.id.present ? entry.id.value : const Uuid().v4();
    await into(quizzes).insert(entry.copyWith(id: Value(id)));
    return id;
  }

  Future<bool> updateQuiz(QuizzesCompanion entry) =>
      update(quizzes).replace(entry);

  Future<void> deleteQuiz(String id) async {
    await (delete(quizQuestions)..where((t) => t.quizId.equals(id))).go();
    await (delete(quizzes)..where((t) => t.id.equals(id))).go();
  }

  // ─── Questions ────────────────────────────────────────────────

  Future<List<Question>> getAllQuestions() => select(questions).get();

  Future<List<Question>> getQuestionsForQuiz(String quizId) {
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

  Stream<List<Question>> watchQuestionsForQuiz(String quizId) {
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
    required String quizId,
    required String questionId,
    required int newIndex,
  }) async {
    await (update(quizQuestions)
      ..where((t) =>
          t.quizId.equals(quizId) & t.questionId.equals(questionId)))
        .write(QuizQuestionsCompanion(sortOrder: Value(newIndex)));
  }

  Future<String> insertQuestion(QuestionsCompanion question) async {
    final id = question.id.present ? question.id.value : const Uuid().v4();
    await into(questions).insert(question.copyWith(id: Value(id)));
    return id;
  }

  Future<void> insertQuestionIntoQuiz({
    required QuestionsCompanion question,
    required String quizId,
  }) async {
    final questionId = await insertQuestion(question);
    await into(quizQuestions).insert(
      QuizQuestionsCompanion.insert(
        quizId: quizId,
        questionId: questionId,
      ),
    );
  }

  Future<int> deleteQuestion(String id) =>
      (delete(questions)..where((t) => t.id.equals(id))).go();

  // ─── Lookup helpers ───────────────────────────────────────────

  Future<Folder?> getFolderById(String id) =>
      (select(folders)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Quiz?> getQuizById(String id) =>
      (select(quizzes)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<Question?> getQuestionById(String id) =>
      (select(questions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> updateFolderParentId(String folderId, String parentFolderId) =>
      (update(folders)..where((t) => t.id.equals(folderId)))
          .write(FoldersCompanion(parentFolderId: Value(parentFolderId)));

  Future<void> moveFolderToParent(String folderId, String? newParentId) =>
      (update(folders)..where((t) => t.id.equals(folderId)))
          .write(FoldersCompanion(parentFolderId: Value(newParentId)));

  Future<void> moveQuizToFolder(String quizId, String? newFolderId) =>
      (update(quizzes)..where((t) => t.id.equals(quizId)))
          .write(QuizzesCompanion(folderId: Value(newFolderId)));

  Future<Set<String>> getFolderSubtreeIds(String folderId) =>
      _collectFolderSubtree(folderId);

  /// Deletes every row from every content table. Used by the dev wipe tool.
  Future<void> wipeAllContent() => transaction(() async {
        await delete(quizQuestions).go();
        await delete(questions).go();
        await delete(quizzes).go();
        await delete(folders).go();
      });

  Future<void> insertJunctionRowSafe(String quizId, String questionId, int sortOrder) async {
    try {
      await into(quizQuestions).insert(QuizQuestionsCompanion.insert(
        quizId: quizId,
        questionId: questionId,
        sortOrder: Value(sortOrder),
      ));
    } catch (_) {} // Ignore duplicate junction rows
  }
}
