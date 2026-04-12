import 'package:drift/drift.dart';

@DataClassName('Folder')
class Folders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get parentFolderId => integer().nullable()();
  TextColumn get title => text()();
  TextColumn get imagePath => text().nullable()();
  BoolColumn get isPermanent => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get syncId => text().nullable()();
}

@DataClassName('Quiz')
class Quizzes extends Table {
  IntColumn get id => integer().autoIncrement()();
  // Nullable: quizzes can be at the root (no folder)
  IntColumn get folderId => integer().nullable()();
  TextColumn get title => text()();
  TextColumn get imagePath => text().nullable()();
  BoolColumn get isPermanent => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  // Optional BCP-47 language tag for the quiz content (e.g. 'en', 'nl', 'de').
  // Null means the quiz is language-neutral / applicable to all languages.
  TextColumn get languageCode => text().nullable()();
  TextColumn get syncId => text().nullable()();
}

class Questions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get questionText => text()();
  // Store variants as JSON string: '["Variant A", "Variant B"]'
  TextColumn get questionVariants => text().nullable()();
  TextColumn get answerType => text()(); // 'multipleChoice' | 'typed' | 'imageClick' | 'flashcard'
  // Store the full config as a JSON blob — flexible for all answer types
  TextColumn get answerConfig => text()();
  TextColumn get explanation => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  BoolColumn get isPermanent => boolean().withDefault(const Constant(false))();
  TextColumn get syncId => text().nullable()();
}

// Junction table — a question can belong to multiple quizzes
class QuizQuestions extends Table {
  IntColumn get quizId => integer().references(Quizzes, #id)();
  IntColumn get questionId => integer().references(Questions, #id)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {quizId, questionId};
}
