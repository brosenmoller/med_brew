import 'package:drift/drift.dart';

@DataClassName('Folder')
class Folders extends Table {
  TextColumn get id => text()();
  TextColumn get parentFolderId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get imagePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('Quiz')
class Quizzes extends Table {
  TextColumn get id => text()();
  // Nullable: quizzes can be at the root (no folder)
  TextColumn get folderId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get imagePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  // Optional BCP-47 language tag for the quiz content (e.g. 'en', 'nl', 'de').
  // Null means the quiz is language-neutral / applicable to all languages.
  TextColumn get languageCode => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

class Questions extends Table {
  TextColumn get id => text()();
  TextColumn get questionText => text()();
  // Store variants as JSON string: '["Variant A", "Variant B"]'
  TextColumn get questionVariants => text().nullable()();
  TextColumn get answerType => text()(); // 'multipleChoice' | 'typed' | 'imageClick' | 'flashcard'
  // Store the full config as a JSON blob — flexible for all answer types
  TextColumn get answerConfig => text()();
  TextColumn get explanation => text().nullable()();
  TextColumn get imagePath => text().nullable()();
  @override
  Set<Column> get primaryKey => {id};
}

// Junction table — a question can belong to multiple quizzes
class QuizQuestions extends Table {
  TextColumn get quizId => text().references(Quizzes, #id)();
  TextColumn get questionId => text().references(Questions, #id)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {quizId, questionId};
}
