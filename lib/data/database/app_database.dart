import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
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

      if (!file.existsSync()) {
        final data = await rootBundle.load('assets/seed.db');
        final bytes = data.buffer.asUint8List();
        await file.writeAsBytes(bytes, flush: true);
      }

      return NativeDatabase.createInBackground(file);
    });
  }

  @override
  int get schemaVersion => 5;

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
        // Back-fill UUIDs for all non-permanent rows using SQLite randomblob
        const uuidExpr =
            "lower(hex(randomblob(4))) || '-' || lower(hex(randomblob(2))) || '-4' || "
            "substr(lower(hex(randomblob(2))),2) || '-' || lower(hex(randomblob(2))) || "
            "'-' || lower(hex(randomblob(6)))";
        await customStatement(
            'UPDATE folders SET sync_id = $uuidExpr WHERE is_permanent = 0 AND sync_id IS NULL');
        await customStatement(
            'UPDATE quizzes SET sync_id = $uuidExpr WHERE is_permanent = 0 AND sync_id IS NULL');
        await customStatement(
            'UPDATE questions SET sync_id = $uuidExpr WHERE is_permanent = 0 AND sync_id IS NULL');
      }
    },
  );

  /// Bump this whenever new built-in content is added to assets/seed.db.
  /// Existing installs whose stored seedVersion is lower will receive the
  /// new content automatically on next launch.
  static const int kSeedVersion = 1;

  // Used by the seed export to mark permanent on the copy
  AppDatabase.fromFile(File file) : super(NativeDatabase(file));

  // Mark everything permanent — called on the seed copy, not the live DB
  Future<void> markAllPermanent() async {
    await customUpdate('UPDATE folders SET is_permanent = 1');
    await customUpdate('UPDATE quizzes SET is_permanent = 1');
    await customUpdate('UPDATE questions SET is_permanent = 1');
  }

  // ─── Seed merge ───────────────────────────────────────────────
  //
  // Called once per kSeedVersion bump. Opens the bundled seed as a
  // temporary database, finds any permanent items not yet present in this
  // database (matched by syncId, with a title fallback for pre-v5 rows that
  // have no syncId), and inserts them. Custom user content is never touched.

  Future<void> mergeNewSeedContent() async {
    final data = await rootBundle.load('assets/seed.db');
    final dir = await getApplicationDocumentsDirectory();
    final tempFile =
        File(path_dart.join(dir.path, '_seed_merge.db'));
    await tempFile.writeAsBytes(data.buffer.asUint8List());
    // The temp seed file is a completely separate SQLite file from the live DB,
    // so there is no shared executor and no risk of corruption.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    final seedDb = AppDatabase.fromFile(tempFile);
    try {
      await _applyMissingSeedContent(seedDb);
    } finally {
      await seedDb.close();
      if (tempFile.existsSync()) tempFile.deleteSync();
    }
  }

  Future<void> _applyMissingSeedContent(AppDatabase seed) async {
    // Build lookup maps of what this DB already has (by syncId).
    final mySyncedFolders = {
      for (final f in await (select(folders)
            ..where((t) => t.syncId.isNotNull()))
          .get())
        f.syncId!: f.id,
    };
    final mySyncedQuizzes = {
      for (final q in await (select(quizzes)
            ..where((t) => t.syncId.isNotNull()))
          .get())
        q.syncId!: q.id,
    };
    final mySyncedQuestions = {
      for (final q in await (select(questions)
            ..where((t) => t.syncId.isNotNull()))
          .get())
        q.syncId!: q.id,
    };

    final seedFolders = await seed.select(seed.folders).get();
    final seedQuizzes = await seed.select(seed.quizzes).get();
    final seedQuestions = await seed.select(seed.questions).get();
    final seedJunctions = await seed.select(seed.quizQuestions).get();

    // Translate seed-local IDs → this DB's IDs (needed to wire relationships).
    final folderIdMap = <int, int>{};
    final questionIdMap = <int, int>{};

    await transaction(() async {
      // 1. Questions
      for (final q in seedQuestions) {
        // Items with no syncId cannot be tracked — skip.
        if (q.syncId == null) continue;

        if (mySyncedQuestions.containsKey(q.syncId)) {
          questionIdMap[q.id] = mySyncedQuestions[q.syncId]!;
          continue;
        }

        // Old installs: permanent rows have null syncId. Match by text + type
        // to avoid duplicating existing content and assign the stable syncId.
        final titleMatch = await (select(questions)
              ..where((t) =>
                  t.questionText.equals(q.questionText) &
                  t.answerType.equals(q.answerType) &
                  t.isPermanent.equals(true) &
                  t.syncId.isNull()))
            .getSingleOrNull();
        if (titleMatch != null) {
          await (update(questions)..where((t) => t.id.equals(titleMatch.id)))
              .write(QuestionsCompanion(syncId: Value(q.syncId)));
          questionIdMap[q.id] = titleMatch.id;
          continue;
        }

        final localId = await into(questions).insert(QuestionsCompanion(
          questionText: Value(q.questionText),
          questionVariants: Value(q.questionVariants),
          answerType: Value(q.answerType),
          answerConfig: Value(q.answerConfig),
          explanation: Value(q.explanation),
          imagePath: Value(q.imagePath),
          isPermanent: const Value(true),
          syncId: Value(q.syncId),
        ));
        questionIdMap[q.id] = localId;
      }

      // 2. Folders — first pass: insert without parent
      for (final f in seedFolders) {
        if (f.syncId == null) continue;

        if (mySyncedFolders.containsKey(f.syncId)) {
          folderIdMap[f.id] = mySyncedFolders[f.syncId]!;
          continue;
        }

        // Fallback for old installs: match permanent folder by title.
        final titleMatch = await (select(folders)
              ..where((t) =>
                  t.title.equals(f.title) &
                  t.isPermanent.equals(true) &
                  t.syncId.isNull()))
            .getSingleOrNull();
        if (titleMatch != null) {
          await (update(folders)..where((t) => t.id.equals(titleMatch.id)))
              .write(FoldersCompanion(syncId: Value(f.syncId)));
          folderIdMap[f.id] = titleMatch.id;
          continue;
        }

        final localId = await into(folders).insert(FoldersCompanion(
          title: Value(f.title),
          imagePath: Value(f.imagePath),
          isPermanent: const Value(true),
          syncId: Value(f.syncId),
        ));
        folderIdMap[f.id] = localId;
      }
      // Second pass: wire parent relationships for newly inserted folders.
      for (final f in seedFolders) {
        if (f.syncId == null || f.parentFolderId == null) continue;
        if (mySyncedFolders.containsKey(f.syncId)) continue; // pre-existing, leave alone
        final localId = folderIdMap[f.id];
        final parentLocalId = folderIdMap[f.parentFolderId!];
        if (localId != null && parentLocalId != null) {
          await (update(folders)..where((t) => t.id.equals(localId)))
              .write(FoldersCompanion(parentFolderId: Value(parentLocalId)));
        }
      }

      // 3. Quizzes + junction rows
      for (final qz in seedQuizzes) {
        if (qz.syncId == null) continue;

        int quizLocalId;

        if (mySyncedQuizzes.containsKey(qz.syncId)) {
          quizLocalId = mySyncedQuizzes[qz.syncId]!;
        } else {
          // Fallback for old installs.
          final folderId =
              qz.folderId != null ? folderIdMap[qz.folderId!] : null;
          final titleMatch = await (select(quizzes)
                ..where((t) =>
                    t.title.equals(qz.title) &
                    t.isPermanent.equals(true) &
                    t.syncId.isNull()))
              .getSingleOrNull();
          if (titleMatch != null) {
            await (update(quizzes)
                  ..where((t) => t.id.equals(titleMatch.id)))
                .write(QuizzesCompanion(syncId: Value(qz.syncId)));
            quizLocalId = titleMatch.id;
          } else {
            quizLocalId = await into(quizzes).insert(QuizzesCompanion(
              title: Value(qz.title),
              folderId: Value(folderId),
              imagePath: Value(qz.imagePath),
              languageCode: Value(qz.languageCode),
              isPermanent: const Value(true),
              syncId: Value(qz.syncId),
            ));
          }
        }

        // Add any junction rows the quiz has in the seed (insertJunctionRowSafe
        // ignores rows that already exist, so this is safe to run every time).
        for (final j
            in seedJunctions.where((j) => j.quizId == qz.id)) {
          final qLocalId = questionIdMap[j.questionId];
          if (qLocalId == null) continue;
          await insertJunctionRowSafe(quizLocalId, qLocalId, j.sortOrder);
        }
      }
    });
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
        'languageCode': quiz.languageCode,
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
          languageCode: Value(quiz['languageCode'] as String?),
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
    if (!question.syncId.present) {
      await (update(questions)..where((t) => t.id.equals(questionId)))
          .write(QuestionsCompanion(syncId: Value(const Uuid().v4())));
    }
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

  Future<List<Folder>> getNonPermanentFolders() =>
      (select(folders)..where((t) => t.isPermanent.equals(false))).get();

  Future<List<Quiz>> getNonPermanentQuizzes() =>
      (select(quizzes)..where((t) => t.isPermanent.equals(false))).get();

  Future<List<Question>> getNonPermanentQuestions() =>
      (select(questions)..where((t) => t.isPermanent.equals(false))).get();

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
