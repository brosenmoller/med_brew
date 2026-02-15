import 'package:med_brew/models/answer_configs.dart' show ImageClickConfig, MultipleChoiceConfig, TypedAnswerConfig;
import 'package:med_brew/models/answer_type.dart' show AnswerType;

class QuestionData {
  final String id;
  final List<String> questionVariants;
  final String? imagePath;
  final AnswerType answerType;
  final String? explanation;

  // Type-specific data
  final MultipleChoiceConfig? multipleChoiceConfig;
  final TypedAnswerConfig? typedAnswerConfig;
  final ImageClickConfig? imageClickConfig;

  // Tags / Quiz groups
  final List<String> quizTags;

  // SRS data
  int repetitions;
  double easeFactor;
  int interval; // in days
  DateTime nextReview;

  QuestionData({
    required this.id,
    required this.questionVariants,
    required this.answerType,
    this.explanation,
    this.imagePath,
    this.multipleChoiceConfig,
    this.typedAnswerConfig,
    this.imageClickConfig,
    required this.quizTags,
    this.repetitions = 0,
    this.easeFactor = 2.5,
    this.interval = 1,
    DateTime? nextReview,
  }) : nextReview = nextReview ?? DateTime.now();
}