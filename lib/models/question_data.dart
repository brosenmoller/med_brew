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
  });
}