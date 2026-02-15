import 'package:med_brew/models/question_data.dart';
import 'package:med_brew/models/answer_type.dart';
import 'package:med_brew/models/answer_configs.dart';

class QuestionRepository {
  static final List<QuestionData> allQuestions = [

    QuestionData(
      id: "q1",
      questionVariants: ["What is the longest bone?"],
      answerType: AnswerType.multipleChoice,
      multipleChoiceConfig: MultipleChoiceConfig(
        options: ["Femur", "Tibia", "Humerus", "Fibula"],
        correctIndex: 0,
      ),
      quizTags: ["Skeleton", "Femur Quiz"],
    ),

    QuestionData(
      id: "q2",
      questionVariants: ["What muscle flexes the elbow?"],
      answerType: AnswerType.typed,
      typedAnswerConfig: TypedAnswerConfig(
        acceptedAnswers: ["Biceps", "Biceps brachii"],
      ),
      quizTags: ["Muscles", "Arm Muscles"],
    ),

  ];
}