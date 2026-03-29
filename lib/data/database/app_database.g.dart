// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, Category> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _imagePathMeta =
      const VerificationMeta('imagePath');
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
      'image_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isPermanentMeta =
      const VerificationMeta('isPermanent');
  @override
  late final GeneratedColumn<bool> isPermanent = GeneratedColumn<bool>(
      'is_permanent', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_permanent" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, title, imagePath, isPermanent, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(Insertable<Category> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(_imagePathMeta,
          imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta));
    }
    if (data.containsKey('is_permanent')) {
      context.handle(
          _isPermanentMeta,
          isPermanent.isAcceptableOrUnknown(
              data['is_permanent']!, _isPermanentMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Category map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Category(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      imagePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_path']),
      isPermanent: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_permanent'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class Category extends DataClass implements Insertable<Category> {
  final int id;
  final String title;
  final String? imagePath;
  final bool isPermanent;
  final DateTime createdAt;
  const Category(
      {required this.id,
      required this.title,
      this.imagePath,
      required this.isPermanent,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['is_permanent'] = Variable<bool>(isPermanent);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      title: Value(title),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      isPermanent: Value(isPermanent),
      createdAt: Value(createdAt),
    );
  }

  factory Category.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Category(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      isPermanent: serializer.fromJson<bool>(json['isPermanent']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'imagePath': serializer.toJson<String?>(imagePath),
      'isPermanent': serializer.toJson<bool>(isPermanent),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Category copyWith(
          {int? id,
          String? title,
          Value<String?> imagePath = const Value.absent(),
          bool? isPermanent,
          DateTime? createdAt}) =>
      Category(
        id: id ?? this.id,
        title: title ?? this.title,
        imagePath: imagePath.present ? imagePath.value : this.imagePath,
        isPermanent: isPermanent ?? this.isPermanent,
        createdAt: createdAt ?? this.createdAt,
      );
  Category copyWithCompanion(CategoriesCompanion data) {
    return Category(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      isPermanent:
          data.isPermanent.present ? data.isPermanent.value : this.isPermanent,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Category(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('imagePath: $imagePath, ')
          ..write('isPermanent: $isPermanent, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, imagePath, isPermanent, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Category &&
          other.id == this.id &&
          other.title == this.title &&
          other.imagePath == this.imagePath &&
          other.isPermanent == this.isPermanent &&
          other.createdAt == this.createdAt);
}

class CategoriesCompanion extends UpdateCompanion<Category> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> imagePath;
  final Value<bool> isPermanent;
  final Value<DateTime> createdAt;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.isPermanent = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.imagePath = const Value.absent(),
    this.isPermanent = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : title = Value(title);
  static Insertable<Category> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? imagePath,
    Expression<bool>? isPermanent,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (imagePath != null) 'image_path': imagePath,
      if (isPermanent != null) 'is_permanent': isPermanent,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  CategoriesCompanion copyWith(
      {Value<int>? id,
      Value<String>? title,
      Value<String?>? imagePath,
      Value<bool>? isPermanent,
      Value<DateTime>? createdAt}) {
    return CategoriesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      imagePath: imagePath ?? this.imagePath,
      isPermanent: isPermanent ?? this.isPermanent,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (isPermanent.present) {
      map['is_permanent'] = Variable<bool>(isPermanent.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('imagePath: $imagePath, ')
          ..write('isPermanent: $isPermanent, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $QuizzesTable extends Quizzes with TableInfo<$QuizzesTable, Quiz> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuizzesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
      'category_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES categories (id)'));
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _imagePathMeta =
      const VerificationMeta('imagePath');
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
      'image_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isPermanentMeta =
      const VerificationMeta('isPermanent');
  @override
  late final GeneratedColumn<bool> isPermanent = GeneratedColumn<bool>(
      'is_permanent', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_permanent" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns =>
      [id, categoryId, title, imagePath, isPermanent, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quizzes';
  @override
  VerificationContext validateIntegrity(Insertable<Quiz> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('image_path')) {
      context.handle(_imagePathMeta,
          imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta));
    }
    if (data.containsKey('is_permanent')) {
      context.handle(
          _isPermanentMeta,
          isPermanent.isAcceptableOrUnknown(
              data['is_permanent']!, _isPermanentMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Quiz map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Quiz(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      imagePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_path']),
      isPermanent: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_permanent'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $QuizzesTable createAlias(String alias) {
    return $QuizzesTable(attachedDatabase, alias);
  }
}

class Quiz extends DataClass implements Insertable<Quiz> {
  final int id;
  final int categoryId;
  final String title;
  final String? imagePath;
  final bool isPermanent;
  final DateTime createdAt;
  const Quiz(
      {required this.id,
      required this.categoryId,
      required this.title,
      this.imagePath,
      required this.isPermanent,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['category_id'] = Variable<int>(categoryId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['is_permanent'] = Variable<bool>(isPermanent);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  QuizzesCompanion toCompanion(bool nullToAbsent) {
    return QuizzesCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      title: Value(title),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      isPermanent: Value(isPermanent),
      createdAt: Value(createdAt),
    );
  }

  factory Quiz.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Quiz(
      id: serializer.fromJson<int>(json['id']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      title: serializer.fromJson<String>(json['title']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      isPermanent: serializer.fromJson<bool>(json['isPermanent']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'categoryId': serializer.toJson<int>(categoryId),
      'title': serializer.toJson<String>(title),
      'imagePath': serializer.toJson<String?>(imagePath),
      'isPermanent': serializer.toJson<bool>(isPermanent),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Quiz copyWith(
          {int? id,
          int? categoryId,
          String? title,
          Value<String?> imagePath = const Value.absent(),
          bool? isPermanent,
          DateTime? createdAt}) =>
      Quiz(
        id: id ?? this.id,
        categoryId: categoryId ?? this.categoryId,
        title: title ?? this.title,
        imagePath: imagePath.present ? imagePath.value : this.imagePath,
        isPermanent: isPermanent ?? this.isPermanent,
        createdAt: createdAt ?? this.createdAt,
      );
  Quiz copyWithCompanion(QuizzesCompanion data) {
    return Quiz(
      id: data.id.present ? data.id.value : this.id,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      title: data.title.present ? data.title.value : this.title,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      isPermanent:
          data.isPermanent.present ? data.isPermanent.value : this.isPermanent,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Quiz(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('title: $title, ')
          ..write('imagePath: $imagePath, ')
          ..write('isPermanent: $isPermanent, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, categoryId, title, imagePath, isPermanent, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Quiz &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.title == this.title &&
          other.imagePath == this.imagePath &&
          other.isPermanent == this.isPermanent &&
          other.createdAt == this.createdAt);
}

class QuizzesCompanion extends UpdateCompanion<Quiz> {
  final Value<int> id;
  final Value<int> categoryId;
  final Value<String> title;
  final Value<String?> imagePath;
  final Value<bool> isPermanent;
  final Value<DateTime> createdAt;
  const QuizzesCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.title = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.isPermanent = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  QuizzesCompanion.insert({
    this.id = const Value.absent(),
    required int categoryId,
    required String title,
    this.imagePath = const Value.absent(),
    this.isPermanent = const Value.absent(),
    this.createdAt = const Value.absent(),
  })  : categoryId = Value(categoryId),
        title = Value(title);
  static Insertable<Quiz> custom({
    Expression<int>? id,
    Expression<int>? categoryId,
    Expression<String>? title,
    Expression<String>? imagePath,
    Expression<bool>? isPermanent,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (title != null) 'title': title,
      if (imagePath != null) 'image_path': imagePath,
      if (isPermanent != null) 'is_permanent': isPermanent,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  QuizzesCompanion copyWith(
      {Value<int>? id,
      Value<int>? categoryId,
      Value<String>? title,
      Value<String?>? imagePath,
      Value<bool>? isPermanent,
      Value<DateTime>? createdAt}) {
    return QuizzesCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      imagePath: imagePath ?? this.imagePath,
      isPermanent: isPermanent ?? this.isPermanent,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (isPermanent.present) {
      map['is_permanent'] = Variable<bool>(isPermanent.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuizzesCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('title: $title, ')
          ..write('imagePath: $imagePath, ')
          ..write('isPermanent: $isPermanent, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $QuestionsTable extends Questions
    with TableInfo<$QuestionsTable, Question> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuestionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _questionTextMeta =
      const VerificationMeta('questionText');
  @override
  late final GeneratedColumn<String> questionText = GeneratedColumn<String>(
      'question_text', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _questionVariantsMeta =
      const VerificationMeta('questionVariants');
  @override
  late final GeneratedColumn<String> questionVariants = GeneratedColumn<String>(
      'question_variants', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _answerTypeMeta =
      const VerificationMeta('answerType');
  @override
  late final GeneratedColumn<String> answerType = GeneratedColumn<String>(
      'answer_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _answerConfigMeta =
      const VerificationMeta('answerConfig');
  @override
  late final GeneratedColumn<String> answerConfig = GeneratedColumn<String>(
      'answer_config', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _explanationMeta =
      const VerificationMeta('explanation');
  @override
  late final GeneratedColumn<String> explanation = GeneratedColumn<String>(
      'explanation', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _imagePathMeta =
      const VerificationMeta('imagePath');
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
      'image_path', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isPermanentMeta =
      const VerificationMeta('isPermanent');
  @override
  late final GeneratedColumn<bool> isPermanent = GeneratedColumn<bool>(
      'is_permanent', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("is_permanent" IN (0, 1))'),
      defaultValue: const Constant(false));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        questionText,
        questionVariants,
        answerType,
        answerConfig,
        explanation,
        imagePath,
        isPermanent
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'questions';
  @override
  VerificationContext validateIntegrity(Insertable<Question> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('question_text')) {
      context.handle(
          _questionTextMeta,
          questionText.isAcceptableOrUnknown(
              data['question_text']!, _questionTextMeta));
    } else if (isInserting) {
      context.missing(_questionTextMeta);
    }
    if (data.containsKey('question_variants')) {
      context.handle(
          _questionVariantsMeta,
          questionVariants.isAcceptableOrUnknown(
              data['question_variants']!, _questionVariantsMeta));
    }
    if (data.containsKey('answer_type')) {
      context.handle(
          _answerTypeMeta,
          answerType.isAcceptableOrUnknown(
              data['answer_type']!, _answerTypeMeta));
    } else if (isInserting) {
      context.missing(_answerTypeMeta);
    }
    if (data.containsKey('answer_config')) {
      context.handle(
          _answerConfigMeta,
          answerConfig.isAcceptableOrUnknown(
              data['answer_config']!, _answerConfigMeta));
    } else if (isInserting) {
      context.missing(_answerConfigMeta);
    }
    if (data.containsKey('explanation')) {
      context.handle(
          _explanationMeta,
          explanation.isAcceptableOrUnknown(
              data['explanation']!, _explanationMeta));
    }
    if (data.containsKey('image_path')) {
      context.handle(_imagePathMeta,
          imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta));
    }
    if (data.containsKey('is_permanent')) {
      context.handle(
          _isPermanentMeta,
          isPermanent.isAcceptableOrUnknown(
              data['is_permanent']!, _isPermanentMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Question map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Question(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      questionText: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}question_text'])!,
      questionVariants: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}question_variants']),
      answerType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}answer_type'])!,
      answerConfig: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}answer_config'])!,
      explanation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}explanation']),
      imagePath: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}image_path']),
      isPermanent: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_permanent'])!,
    );
  }

  @override
  $QuestionsTable createAlias(String alias) {
    return $QuestionsTable(attachedDatabase, alias);
  }
}

class Question extends DataClass implements Insertable<Question> {
  final int id;
  final String questionText;
  final String? questionVariants;
  final String answerType;
  final String answerConfig;
  final String? explanation;
  final String? imagePath;
  final bool isPermanent;
  const Question(
      {required this.id,
      required this.questionText,
      this.questionVariants,
      required this.answerType,
      required this.answerConfig,
      this.explanation,
      this.imagePath,
      required this.isPermanent});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['question_text'] = Variable<String>(questionText);
    if (!nullToAbsent || questionVariants != null) {
      map['question_variants'] = Variable<String>(questionVariants);
    }
    map['answer_type'] = Variable<String>(answerType);
    map['answer_config'] = Variable<String>(answerConfig);
    if (!nullToAbsent || explanation != null) {
      map['explanation'] = Variable<String>(explanation);
    }
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['is_permanent'] = Variable<bool>(isPermanent);
    return map;
  }

  QuestionsCompanion toCompanion(bool nullToAbsent) {
    return QuestionsCompanion(
      id: Value(id),
      questionText: Value(questionText),
      questionVariants: questionVariants == null && nullToAbsent
          ? const Value.absent()
          : Value(questionVariants),
      answerType: Value(answerType),
      answerConfig: Value(answerConfig),
      explanation: explanation == null && nullToAbsent
          ? const Value.absent()
          : Value(explanation),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      isPermanent: Value(isPermanent),
    );
  }

  factory Question.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Question(
      id: serializer.fromJson<int>(json['id']),
      questionText: serializer.fromJson<String>(json['questionText']),
      questionVariants: serializer.fromJson<String?>(json['questionVariants']),
      answerType: serializer.fromJson<String>(json['answerType']),
      answerConfig: serializer.fromJson<String>(json['answerConfig']),
      explanation: serializer.fromJson<String?>(json['explanation']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      isPermanent: serializer.fromJson<bool>(json['isPermanent']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'questionText': serializer.toJson<String>(questionText),
      'questionVariants': serializer.toJson<String?>(questionVariants),
      'answerType': serializer.toJson<String>(answerType),
      'answerConfig': serializer.toJson<String>(answerConfig),
      'explanation': serializer.toJson<String?>(explanation),
      'imagePath': serializer.toJson<String?>(imagePath),
      'isPermanent': serializer.toJson<bool>(isPermanent),
    };
  }

  Question copyWith(
          {int? id,
          String? questionText,
          Value<String?> questionVariants = const Value.absent(),
          String? answerType,
          String? answerConfig,
          Value<String?> explanation = const Value.absent(),
          Value<String?> imagePath = const Value.absent(),
          bool? isPermanent}) =>
      Question(
        id: id ?? this.id,
        questionText: questionText ?? this.questionText,
        questionVariants: questionVariants.present
            ? questionVariants.value
            : this.questionVariants,
        answerType: answerType ?? this.answerType,
        answerConfig: answerConfig ?? this.answerConfig,
        explanation: explanation.present ? explanation.value : this.explanation,
        imagePath: imagePath.present ? imagePath.value : this.imagePath,
        isPermanent: isPermanent ?? this.isPermanent,
      );
  Question copyWithCompanion(QuestionsCompanion data) {
    return Question(
      id: data.id.present ? data.id.value : this.id,
      questionText: data.questionText.present
          ? data.questionText.value
          : this.questionText,
      questionVariants: data.questionVariants.present
          ? data.questionVariants.value
          : this.questionVariants,
      answerType:
          data.answerType.present ? data.answerType.value : this.answerType,
      answerConfig: data.answerConfig.present
          ? data.answerConfig.value
          : this.answerConfig,
      explanation:
          data.explanation.present ? data.explanation.value : this.explanation,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      isPermanent:
          data.isPermanent.present ? data.isPermanent.value : this.isPermanent,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Question(')
          ..write('id: $id, ')
          ..write('questionText: $questionText, ')
          ..write('questionVariants: $questionVariants, ')
          ..write('answerType: $answerType, ')
          ..write('answerConfig: $answerConfig, ')
          ..write('explanation: $explanation, ')
          ..write('imagePath: $imagePath, ')
          ..write('isPermanent: $isPermanent')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, questionText, questionVariants,
      answerType, answerConfig, explanation, imagePath, isPermanent);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Question &&
          other.id == this.id &&
          other.questionText == this.questionText &&
          other.questionVariants == this.questionVariants &&
          other.answerType == this.answerType &&
          other.answerConfig == this.answerConfig &&
          other.explanation == this.explanation &&
          other.imagePath == this.imagePath &&
          other.isPermanent == this.isPermanent);
}

class QuestionsCompanion extends UpdateCompanion<Question> {
  final Value<int> id;
  final Value<String> questionText;
  final Value<String?> questionVariants;
  final Value<String> answerType;
  final Value<String> answerConfig;
  final Value<String?> explanation;
  final Value<String?> imagePath;
  final Value<bool> isPermanent;
  const QuestionsCompanion({
    this.id = const Value.absent(),
    this.questionText = const Value.absent(),
    this.questionVariants = const Value.absent(),
    this.answerType = const Value.absent(),
    this.answerConfig = const Value.absent(),
    this.explanation = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.isPermanent = const Value.absent(),
  });
  QuestionsCompanion.insert({
    this.id = const Value.absent(),
    required String questionText,
    this.questionVariants = const Value.absent(),
    required String answerType,
    required String answerConfig,
    this.explanation = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.isPermanent = const Value.absent(),
  })  : questionText = Value(questionText),
        answerType = Value(answerType),
        answerConfig = Value(answerConfig);
  static Insertable<Question> custom({
    Expression<int>? id,
    Expression<String>? questionText,
    Expression<String>? questionVariants,
    Expression<String>? answerType,
    Expression<String>? answerConfig,
    Expression<String>? explanation,
    Expression<String>? imagePath,
    Expression<bool>? isPermanent,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (questionText != null) 'question_text': questionText,
      if (questionVariants != null) 'question_variants': questionVariants,
      if (answerType != null) 'answer_type': answerType,
      if (answerConfig != null) 'answer_config': answerConfig,
      if (explanation != null) 'explanation': explanation,
      if (imagePath != null) 'image_path': imagePath,
      if (isPermanent != null) 'is_permanent': isPermanent,
    });
  }

  QuestionsCompanion copyWith(
      {Value<int>? id,
      Value<String>? questionText,
      Value<String?>? questionVariants,
      Value<String>? answerType,
      Value<String>? answerConfig,
      Value<String?>? explanation,
      Value<String?>? imagePath,
      Value<bool>? isPermanent}) {
    return QuestionsCompanion(
      id: id ?? this.id,
      questionText: questionText ?? this.questionText,
      questionVariants: questionVariants ?? this.questionVariants,
      answerType: answerType ?? this.answerType,
      answerConfig: answerConfig ?? this.answerConfig,
      explanation: explanation ?? this.explanation,
      imagePath: imagePath ?? this.imagePath,
      isPermanent: isPermanent ?? this.isPermanent,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (questionText.present) {
      map['question_text'] = Variable<String>(questionText.value);
    }
    if (questionVariants.present) {
      map['question_variants'] = Variable<String>(questionVariants.value);
    }
    if (answerType.present) {
      map['answer_type'] = Variable<String>(answerType.value);
    }
    if (answerConfig.present) {
      map['answer_config'] = Variable<String>(answerConfig.value);
    }
    if (explanation.present) {
      map['explanation'] = Variable<String>(explanation.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (isPermanent.present) {
      map['is_permanent'] = Variable<bool>(isPermanent.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuestionsCompanion(')
          ..write('id: $id, ')
          ..write('questionText: $questionText, ')
          ..write('questionVariants: $questionVariants, ')
          ..write('answerType: $answerType, ')
          ..write('answerConfig: $answerConfig, ')
          ..write('explanation: $explanation, ')
          ..write('imagePath: $imagePath, ')
          ..write('isPermanent: $isPermanent')
          ..write(')'))
        .toString();
  }
}

class $QuizQuestionsTable extends QuizQuestions
    with TableInfo<$QuizQuestionsTable, QuizQuestion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $QuizQuestionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _quizIdMeta = const VerificationMeta('quizId');
  @override
  late final GeneratedColumn<int> quizId = GeneratedColumn<int>(
      'quiz_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES quizzes (id)'));
  static const VerificationMeta _questionIdMeta =
      const VerificationMeta('questionId');
  @override
  late final GeneratedColumn<int> questionId = GeneratedColumn<int>(
      'question_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES questions (id)'));
  static const VerificationMeta _sortOrderMeta =
      const VerificationMeta('sortOrder');
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
      'sort_order', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [quizId, questionId, sortOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'quiz_questions';
  @override
  VerificationContext validateIntegrity(Insertable<QuizQuestion> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('quiz_id')) {
      context.handle(_quizIdMeta,
          quizId.isAcceptableOrUnknown(data['quiz_id']!, _quizIdMeta));
    } else if (isInserting) {
      context.missing(_quizIdMeta);
    }
    if (data.containsKey('question_id')) {
      context.handle(
          _questionIdMeta,
          questionId.isAcceptableOrUnknown(
              data['question_id']!, _questionIdMeta));
    } else if (isInserting) {
      context.missing(_questionIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(_sortOrderMeta,
          sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {quizId, questionId};
  @override
  QuizQuestion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return QuizQuestion(
      quizId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}quiz_id'])!,
      questionId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}question_id'])!,
      sortOrder: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sort_order'])!,
    );
  }

  @override
  $QuizQuestionsTable createAlias(String alias) {
    return $QuizQuestionsTable(attachedDatabase, alias);
  }
}

class QuizQuestion extends DataClass implements Insertable<QuizQuestion> {
  final int quizId;
  final int questionId;
  final int sortOrder;
  const QuizQuestion(
      {required this.quizId,
      required this.questionId,
      required this.sortOrder});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['quiz_id'] = Variable<int>(quizId);
    map['question_id'] = Variable<int>(questionId);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  QuizQuestionsCompanion toCompanion(bool nullToAbsent) {
    return QuizQuestionsCompanion(
      quizId: Value(quizId),
      questionId: Value(questionId),
      sortOrder: Value(sortOrder),
    );
  }

  factory QuizQuestion.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return QuizQuestion(
      quizId: serializer.fromJson<int>(json['quizId']),
      questionId: serializer.fromJson<int>(json['questionId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'quizId': serializer.toJson<int>(quizId),
      'questionId': serializer.toJson<int>(questionId),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  QuizQuestion copyWith({int? quizId, int? questionId, int? sortOrder}) =>
      QuizQuestion(
        quizId: quizId ?? this.quizId,
        questionId: questionId ?? this.questionId,
        sortOrder: sortOrder ?? this.sortOrder,
      );
  QuizQuestion copyWithCompanion(QuizQuestionsCompanion data) {
    return QuizQuestion(
      quizId: data.quizId.present ? data.quizId.value : this.quizId,
      questionId:
          data.questionId.present ? data.questionId.value : this.questionId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('QuizQuestion(')
          ..write('quizId: $quizId, ')
          ..write('questionId: $questionId, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(quizId, questionId, sortOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is QuizQuestion &&
          other.quizId == this.quizId &&
          other.questionId == this.questionId &&
          other.sortOrder == this.sortOrder);
}

class QuizQuestionsCompanion extends UpdateCompanion<QuizQuestion> {
  final Value<int> quizId;
  final Value<int> questionId;
  final Value<int> sortOrder;
  final Value<int> rowid;
  const QuizQuestionsCompanion({
    this.quizId = const Value.absent(),
    this.questionId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  QuizQuestionsCompanion.insert({
    required int quizId,
    required int questionId,
    this.sortOrder = const Value.absent(),
    this.rowid = const Value.absent(),
  })  : quizId = Value(quizId),
        questionId = Value(questionId);
  static Insertable<QuizQuestion> custom({
    Expression<int>? quizId,
    Expression<int>? questionId,
    Expression<int>? sortOrder,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (quizId != null) 'quiz_id': quizId,
      if (questionId != null) 'question_id': questionId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (rowid != null) 'rowid': rowid,
    });
  }

  QuizQuestionsCompanion copyWith(
      {Value<int>? quizId,
      Value<int>? questionId,
      Value<int>? sortOrder,
      Value<int>? rowid}) {
    return QuizQuestionsCompanion(
      quizId: quizId ?? this.quizId,
      questionId: questionId ?? this.questionId,
      sortOrder: sortOrder ?? this.sortOrder,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (quizId.present) {
      map['quiz_id'] = Variable<int>(quizId.value);
    }
    if (questionId.present) {
      map['question_id'] = Variable<int>(questionId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('QuizQuestionsCompanion(')
          ..write('quizId: $quizId, ')
          ..write('questionId: $questionId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $QuizzesTable quizzes = $QuizzesTable(this);
  late final $QuestionsTable questions = $QuestionsTable(this);
  late final $QuizQuestionsTable quizQuestions = $QuizQuestionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [categories, quizzes, questions, quizQuestions];
}

typedef $$CategoriesTableCreateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  required String title,
  Value<String?> imagePath,
  Value<bool> isPermanent,
  Value<DateTime> createdAt,
});
typedef $$CategoriesTableUpdateCompanionBuilder = CategoriesCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String?> imagePath,
  Value<bool> isPermanent,
  Value<DateTime> createdAt,
});

final class $$CategoriesTableReferences
    extends BaseReferences<_$AppDatabase, $CategoriesTable, Category> {
  $$CategoriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$QuizzesTable, List<Quiz>> _quizzesRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.quizzes,
          aliasName:
              $_aliasNameGenerator(db.categories.id, db.quizzes.categoryId));

  $$QuizzesTableProcessedTableManager get quizzesRefs {
    final manager = $$QuizzesTableTableManager($_db, $_db.quizzes)
        .filter((f) => f.categoryId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_quizzesRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$CategoriesTableFilterComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPermanent => $composableBuilder(
      column: $table.isPermanent, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> quizzesRefs(
      Expression<bool> Function($$QuizzesTableFilterComposer f) f) {
    final $$QuizzesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.quizzes,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuizzesTableFilterComposer(
              $db: $db,
              $table: $db.quizzes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CategoriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPermanent => $composableBuilder(
      column: $table.isPermanent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$CategoriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CategoriesTable> {
  $$CategoriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<bool> get isPermanent => $composableBuilder(
      column: $table.isPermanent, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> quizzesRefs<T extends Object>(
      Expression<T> Function($$QuizzesTableAnnotationComposer a) f) {
    final $$QuizzesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.quizzes,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuizzesTableAnnotationComposer(
              $db: $db,
              $table: $db.quizzes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$CategoriesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (Category, $$CategoriesTableReferences),
    Category,
    PrefetchHooks Function({bool quizzesRefs})> {
  $$CategoriesTableTableManager(_$AppDatabase db, $CategoriesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CategoriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CategoriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CategoriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> imagePath = const Value.absent(),
            Value<bool> isPermanent = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              CategoriesCompanion(
            id: id,
            title: title,
            imagePath: imagePath,
            isPermanent: isPermanent,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String title,
            Value<String?> imagePath = const Value.absent(),
            Value<bool> isPermanent = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              CategoriesCompanion.insert(
            id: id,
            title: title,
            imagePath: imagePath,
            isPermanent: isPermanent,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$CategoriesTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({quizzesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (quizzesRefs) db.quizzes],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (quizzesRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable:
                            $$CategoriesTableReferences._quizzesRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$CategoriesTableReferences(db, table, p0)
                                .quizzesRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$CategoriesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CategoriesTable,
    Category,
    $$CategoriesTableFilterComposer,
    $$CategoriesTableOrderingComposer,
    $$CategoriesTableAnnotationComposer,
    $$CategoriesTableCreateCompanionBuilder,
    $$CategoriesTableUpdateCompanionBuilder,
    (Category, $$CategoriesTableReferences),
    Category,
    PrefetchHooks Function({bool quizzesRefs})>;
typedef $$QuizzesTableCreateCompanionBuilder = QuizzesCompanion Function({
  Value<int> id,
  required int categoryId,
  required String title,
  Value<String?> imagePath,
  Value<bool> isPermanent,
  Value<DateTime> createdAt,
});
typedef $$QuizzesTableUpdateCompanionBuilder = QuizzesCompanion Function({
  Value<int> id,
  Value<int> categoryId,
  Value<String> title,
  Value<String?> imagePath,
  Value<bool> isPermanent,
  Value<DateTime> createdAt,
});

final class $$QuizzesTableReferences
    extends BaseReferences<_$AppDatabase, $QuizzesTable, Quiz> {
  $$QuizzesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CategoriesTable _categoryIdTable(_$AppDatabase db) =>
      db.categories.createAlias(
          $_aliasNameGenerator(db.quizzes.categoryId, db.categories.id));

  $$CategoriesTableProcessedTableManager? get categoryId {
    if ($_item.categoryId == null) return null;
    final manager = $$CategoriesTableTableManager($_db, $_db.categories)
        .filter((f) => f.id($_item.categoryId!));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$QuizQuestionsTable, List<QuizQuestion>>
      _quizQuestionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.quizQuestions,
              aliasName:
                  $_aliasNameGenerator(db.quizzes.id, db.quizQuestions.quizId));

  $$QuizQuestionsTableProcessedTableManager get quizQuestionsRefs {
    final manager = $$QuizQuestionsTableTableManager($_db, $_db.quizQuestions)
        .filter((f) => f.quizId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_quizQuestionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$QuizzesTableFilterComposer
    extends Composer<_$AppDatabase, $QuizzesTable> {
  $$QuizzesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPermanent => $composableBuilder(
      column: $table.isPermanent, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$CategoriesTableFilterComposer get categoryId {
    final $$CategoriesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableFilterComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> quizQuestionsRefs(
      Expression<bool> Function($$QuizQuestionsTableFilterComposer f) f) {
    final $$QuizQuestionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.quizQuestions,
        getReferencedColumn: (t) => t.quizId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuizQuestionsTableFilterComposer(
              $db: $db,
              $table: $db.quizQuestions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$QuizzesTableOrderingComposer
    extends Composer<_$AppDatabase, $QuizzesTable> {
  $$QuizzesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPermanent => $composableBuilder(
      column: $table.isPermanent, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$CategoriesTableOrderingComposer get categoryId {
    final $$CategoriesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableOrderingComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$QuizzesTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuizzesTable> {
  $$QuizzesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<bool> get isPermanent => $composableBuilder(
      column: $table.isPermanent, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$CategoriesTableAnnotationComposer get categoryId {
    final $$CategoriesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.categoryId,
        referencedTable: $db.categories,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$CategoriesTableAnnotationComposer(
              $db: $db,
              $table: $db.categories,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> quizQuestionsRefs<T extends Object>(
      Expression<T> Function($$QuizQuestionsTableAnnotationComposer a) f) {
    final $$QuizQuestionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.quizQuestions,
        getReferencedColumn: (t) => t.quizId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuizQuestionsTableAnnotationComposer(
              $db: $db,
              $table: $db.quizQuestions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$QuizzesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $QuizzesTable,
    Quiz,
    $$QuizzesTableFilterComposer,
    $$QuizzesTableOrderingComposer,
    $$QuizzesTableAnnotationComposer,
    $$QuizzesTableCreateCompanionBuilder,
    $$QuizzesTableUpdateCompanionBuilder,
    (Quiz, $$QuizzesTableReferences),
    Quiz,
    PrefetchHooks Function({bool categoryId, bool quizQuestionsRefs})> {
  $$QuizzesTableTableManager(_$AppDatabase db, $QuizzesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuizzesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuizzesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuizzesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> categoryId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<String?> imagePath = const Value.absent(),
            Value<bool> isPermanent = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              QuizzesCompanion(
            id: id,
            categoryId: categoryId,
            title: title,
            imagePath: imagePath,
            isPermanent: isPermanent,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int categoryId,
            required String title,
            Value<String?> imagePath = const Value.absent(),
            Value<bool> isPermanent = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              QuizzesCompanion.insert(
            id: id,
            categoryId: categoryId,
            title: title,
            imagePath: imagePath,
            isPermanent: isPermanent,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$QuizzesTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {categoryId = false, quizQuestionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (quizQuestionsRefs) db.quizQuestions
              ],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$QuizzesTableReferences._categoryIdTable(db),
                    referencedColumn:
                        $$QuizzesTableReferences._categoryIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (quizQuestionsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$QuizzesTableReferences
                            ._quizQuestionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$QuizzesTableReferences(db, table, p0)
                                .quizQuestionsRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.quizId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$QuizzesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $QuizzesTable,
    Quiz,
    $$QuizzesTableFilterComposer,
    $$QuizzesTableOrderingComposer,
    $$QuizzesTableAnnotationComposer,
    $$QuizzesTableCreateCompanionBuilder,
    $$QuizzesTableUpdateCompanionBuilder,
    (Quiz, $$QuizzesTableReferences),
    Quiz,
    PrefetchHooks Function({bool categoryId, bool quizQuestionsRefs})>;
typedef $$QuestionsTableCreateCompanionBuilder = QuestionsCompanion Function({
  Value<int> id,
  required String questionText,
  Value<String?> questionVariants,
  required String answerType,
  required String answerConfig,
  Value<String?> explanation,
  Value<String?> imagePath,
  Value<bool> isPermanent,
});
typedef $$QuestionsTableUpdateCompanionBuilder = QuestionsCompanion Function({
  Value<int> id,
  Value<String> questionText,
  Value<String?> questionVariants,
  Value<String> answerType,
  Value<String> answerConfig,
  Value<String?> explanation,
  Value<String?> imagePath,
  Value<bool> isPermanent,
});

final class $$QuestionsTableReferences
    extends BaseReferences<_$AppDatabase, $QuestionsTable, Question> {
  $$QuestionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$QuizQuestionsTable, List<QuizQuestion>>
      _quizQuestionsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.quizQuestions,
              aliasName: $_aliasNameGenerator(
                  db.questions.id, db.quizQuestions.questionId));

  $$QuizQuestionsTableProcessedTableManager get quizQuestionsRefs {
    final manager = $$QuizQuestionsTableTableManager($_db, $_db.quizQuestions)
        .filter((f) => f.questionId.id($_item.id));

    final cache = $_typedResult.readTableOrNull(_quizQuestionsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$QuestionsTableFilterComposer
    extends Composer<_$AppDatabase, $QuestionsTable> {
  $$QuestionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get questionText => $composableBuilder(
      column: $table.questionText, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get questionVariants => $composableBuilder(
      column: $table.questionVariants,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get answerType => $composableBuilder(
      column: $table.answerType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get answerConfig => $composableBuilder(
      column: $table.answerConfig, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get explanation => $composableBuilder(
      column: $table.explanation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isPermanent => $composableBuilder(
      column: $table.isPermanent, builder: (column) => ColumnFilters(column));

  Expression<bool> quizQuestionsRefs(
      Expression<bool> Function($$QuizQuestionsTableFilterComposer f) f) {
    final $$QuizQuestionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.quizQuestions,
        getReferencedColumn: (t) => t.questionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuizQuestionsTableFilterComposer(
              $db: $db,
              $table: $db.quizQuestions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$QuestionsTableOrderingComposer
    extends Composer<_$AppDatabase, $QuestionsTable> {
  $$QuestionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get questionText => $composableBuilder(
      column: $table.questionText,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get questionVariants => $composableBuilder(
      column: $table.questionVariants,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get answerType => $composableBuilder(
      column: $table.answerType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get answerConfig => $composableBuilder(
      column: $table.answerConfig,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get explanation => $composableBuilder(
      column: $table.explanation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get imagePath => $composableBuilder(
      column: $table.imagePath, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isPermanent => $composableBuilder(
      column: $table.isPermanent, builder: (column) => ColumnOrderings(column));
}

class $$QuestionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuestionsTable> {
  $$QuestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get questionText => $composableBuilder(
      column: $table.questionText, builder: (column) => column);

  GeneratedColumn<String> get questionVariants => $composableBuilder(
      column: $table.questionVariants, builder: (column) => column);

  GeneratedColumn<String> get answerType => $composableBuilder(
      column: $table.answerType, builder: (column) => column);

  GeneratedColumn<String> get answerConfig => $composableBuilder(
      column: $table.answerConfig, builder: (column) => column);

  GeneratedColumn<String> get explanation => $composableBuilder(
      column: $table.explanation, builder: (column) => column);

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<bool> get isPermanent => $composableBuilder(
      column: $table.isPermanent, builder: (column) => column);

  Expression<T> quizQuestionsRefs<T extends Object>(
      Expression<T> Function($$QuizQuestionsTableAnnotationComposer a) f) {
    final $$QuizQuestionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.quizQuestions,
        getReferencedColumn: (t) => t.questionId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuizQuestionsTableAnnotationComposer(
              $db: $db,
              $table: $db.quizQuestions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$QuestionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $QuestionsTable,
    Question,
    $$QuestionsTableFilterComposer,
    $$QuestionsTableOrderingComposer,
    $$QuestionsTableAnnotationComposer,
    $$QuestionsTableCreateCompanionBuilder,
    $$QuestionsTableUpdateCompanionBuilder,
    (Question, $$QuestionsTableReferences),
    Question,
    PrefetchHooks Function({bool quizQuestionsRefs})> {
  $$QuestionsTableTableManager(_$AppDatabase db, $QuestionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuestionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuestionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuestionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> questionText = const Value.absent(),
            Value<String?> questionVariants = const Value.absent(),
            Value<String> answerType = const Value.absent(),
            Value<String> answerConfig = const Value.absent(),
            Value<String?> explanation = const Value.absent(),
            Value<String?> imagePath = const Value.absent(),
            Value<bool> isPermanent = const Value.absent(),
          }) =>
              QuestionsCompanion(
            id: id,
            questionText: questionText,
            questionVariants: questionVariants,
            answerType: answerType,
            answerConfig: answerConfig,
            explanation: explanation,
            imagePath: imagePath,
            isPermanent: isPermanent,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String questionText,
            Value<String?> questionVariants = const Value.absent(),
            required String answerType,
            required String answerConfig,
            Value<String?> explanation = const Value.absent(),
            Value<String?> imagePath = const Value.absent(),
            Value<bool> isPermanent = const Value.absent(),
          }) =>
              QuestionsCompanion.insert(
            id: id,
            questionText: questionText,
            questionVariants: questionVariants,
            answerType: answerType,
            answerConfig: answerConfig,
            explanation: explanation,
            imagePath: imagePath,
            isPermanent: isPermanent,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$QuestionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({quizQuestionsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (quizQuestionsRefs) db.quizQuestions
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (quizQuestionsRefs)
                    await $_getPrefetchedData(
                        currentTable: table,
                        referencedTable: $$QuestionsTableReferences
                            ._quizQuestionsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$QuestionsTableReferences(db, table, p0)
                                .quizQuestionsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.questionId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$QuestionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $QuestionsTable,
    Question,
    $$QuestionsTableFilterComposer,
    $$QuestionsTableOrderingComposer,
    $$QuestionsTableAnnotationComposer,
    $$QuestionsTableCreateCompanionBuilder,
    $$QuestionsTableUpdateCompanionBuilder,
    (Question, $$QuestionsTableReferences),
    Question,
    PrefetchHooks Function({bool quizQuestionsRefs})>;
typedef $$QuizQuestionsTableCreateCompanionBuilder = QuizQuestionsCompanion
    Function({
  required int quizId,
  required int questionId,
  Value<int> sortOrder,
  Value<int> rowid,
});
typedef $$QuizQuestionsTableUpdateCompanionBuilder = QuizQuestionsCompanion
    Function({
  Value<int> quizId,
  Value<int> questionId,
  Value<int> sortOrder,
  Value<int> rowid,
});

final class $$QuizQuestionsTableReferences
    extends BaseReferences<_$AppDatabase, $QuizQuestionsTable, QuizQuestion> {
  $$QuizQuestionsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $QuizzesTable _quizIdTable(_$AppDatabase db) => db.quizzes.createAlias(
      $_aliasNameGenerator(db.quizQuestions.quizId, db.quizzes.id));

  $$QuizzesTableProcessedTableManager? get quizId {
    if ($_item.quizId == null) return null;
    final manager = $$QuizzesTableTableManager($_db, $_db.quizzes)
        .filter((f) => f.id($_item.quizId!));
    final item = $_typedResult.readTableOrNull(_quizIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $QuestionsTable _questionIdTable(_$AppDatabase db) =>
      db.questions.createAlias(
          $_aliasNameGenerator(db.quizQuestions.questionId, db.questions.id));

  $$QuestionsTableProcessedTableManager? get questionId {
    if ($_item.questionId == null) return null;
    final manager = $$QuestionsTableTableManager($_db, $_db.questions)
        .filter((f) => f.id($_item.questionId!));
    final item = $_typedResult.readTableOrNull(_questionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$QuizQuestionsTableFilterComposer
    extends Composer<_$AppDatabase, $QuizQuestionsTable> {
  $$QuizQuestionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnFilters(column));

  $$QuizzesTableFilterComposer get quizId {
    final $$QuizzesTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.quizId,
        referencedTable: $db.quizzes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuizzesTableFilterComposer(
              $db: $db,
              $table: $db.quizzes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$QuestionsTableFilterComposer get questionId {
    final $$QuestionsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.questionId,
        referencedTable: $db.questions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuestionsTableFilterComposer(
              $db: $db,
              $table: $db.questions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$QuizQuestionsTableOrderingComposer
    extends Composer<_$AppDatabase, $QuizQuestionsTable> {
  $$QuizQuestionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get sortOrder => $composableBuilder(
      column: $table.sortOrder, builder: (column) => ColumnOrderings(column));

  $$QuizzesTableOrderingComposer get quizId {
    final $$QuizzesTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.quizId,
        referencedTable: $db.quizzes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuizzesTableOrderingComposer(
              $db: $db,
              $table: $db.quizzes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$QuestionsTableOrderingComposer get questionId {
    final $$QuestionsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.questionId,
        referencedTable: $db.questions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuestionsTableOrderingComposer(
              $db: $db,
              $table: $db.questions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$QuizQuestionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $QuizQuestionsTable> {
  $$QuizQuestionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  $$QuizzesTableAnnotationComposer get quizId {
    final $$QuizzesTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.quizId,
        referencedTable: $db.quizzes,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuizzesTableAnnotationComposer(
              $db: $db,
              $table: $db.quizzes,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$QuestionsTableAnnotationComposer get questionId {
    final $$QuestionsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.questionId,
        referencedTable: $db.questions,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$QuestionsTableAnnotationComposer(
              $db: $db,
              $table: $db.questions,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$QuizQuestionsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $QuizQuestionsTable,
    QuizQuestion,
    $$QuizQuestionsTableFilterComposer,
    $$QuizQuestionsTableOrderingComposer,
    $$QuizQuestionsTableAnnotationComposer,
    $$QuizQuestionsTableCreateCompanionBuilder,
    $$QuizQuestionsTableUpdateCompanionBuilder,
    (QuizQuestion, $$QuizQuestionsTableReferences),
    QuizQuestion,
    PrefetchHooks Function({bool quizId, bool questionId})> {
  $$QuizQuestionsTableTableManager(_$AppDatabase db, $QuizQuestionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$QuizQuestionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$QuizQuestionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$QuizQuestionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> quizId = const Value.absent(),
            Value<int> questionId = const Value.absent(),
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              QuizQuestionsCompanion(
            quizId: quizId,
            questionId: questionId,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int quizId,
            required int questionId,
            Value<int> sortOrder = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              QuizQuestionsCompanion.insert(
            quizId: quizId,
            questionId: questionId,
            sortOrder: sortOrder,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$QuizQuestionsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({quizId = false, questionId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (quizId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.quizId,
                    referencedTable:
                        $$QuizQuestionsTableReferences._quizIdTable(db),
                    referencedColumn:
                        $$QuizQuestionsTableReferences._quizIdTable(db).id,
                  ) as T;
                }
                if (questionId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.questionId,
                    referencedTable:
                        $$QuizQuestionsTableReferences._questionIdTable(db),
                    referencedColumn:
                        $$QuizQuestionsTableReferences._questionIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$QuizQuestionsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $QuizQuestionsTable,
    QuizQuestion,
    $$QuizQuestionsTableFilterComposer,
    $$QuizQuestionsTableOrderingComposer,
    $$QuizQuestionsTableAnnotationComposer,
    $$QuizQuestionsTableCreateCompanionBuilder,
    $$QuizQuestionsTableUpdateCompanionBuilder,
    (QuizQuestion, $$QuizQuestionsTableReferences),
    QuizQuestion,
    PrefetchHooks Function({bool quizId, bool questionId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db, _db.categories);
  $$QuizzesTableTableManager get quizzes =>
      $$QuizzesTableTableManager(_db, _db.quizzes);
  $$QuestionsTableTableManager get questions =>
      $$QuestionsTableTableManager(_db, _db.questions);
  $$QuizQuestionsTableTableManager get quizQuestions =>
      $$QuizQuestionsTableTableManager(_db, _db.quizQuestions);
}
