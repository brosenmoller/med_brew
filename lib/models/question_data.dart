import 'package:med_brew/models/answer_configs.dart' show FlashcardConfig, ImageClickConfig, MultipleChoiceConfig, TypedAnswerConfig;
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
  final FlashcardConfig? flashcardConfig;

  QuestionData({
    required this.id,
    required this.questionVariants,
    required this.answerType,
    this.explanation,
    this.imagePath,
    this.multipleChoiceConfig,
    this.typedAnswerConfig,
    this.imageClickConfig,
    this.flashcardConfig,
  });

  factory QuestionData.fromJson(Map<String, dynamic> json) {
    return QuestionData(
      id: json['id'] as String,
      questionVariants: List<String>.from(json['questionVariants'] ?? []),
      imagePath: json['imagePath'] as String?,
      answerType: AnswerType.values.firstWhere(
            (e) => e.toString().split('.').last == json['answerType'],
      ),
      explanation: json['explanation'] as String?,
      multipleChoiceConfig: json['multipleChoiceConfig'] != null
          ? MultipleChoiceConfig.fromJson(json['multipleChoiceConfig']) : null,
      typedAnswerConfig: json['typedAnswerConfig'] != null
          ? TypedAnswerConfig.fromJson(json['typedAnswerConfig']) : null,
      imageClickConfig: json['imageClickConfig'] != null
          ? ImageClickConfig.fromJson(json['imageClickConfig']) : null,
      flashcardConfig: json['flashcardConfig'] != null
          ? FlashcardConfig.fromJson(json['flashcardConfig']) : null,
    );
  }
}