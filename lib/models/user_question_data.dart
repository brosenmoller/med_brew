import 'package:hive/hive.dart';
part 'user_question_data.g.dart';
enum SrsQuality { again, hard, good, easy }

@HiveType(typeId: 0)
class UserQuestionData extends HiveObject {
  @HiveField(0)
  final String questionId; // reference to QuestionData

  @HiveField(1)
  int streak;

  @HiveField(2)
  double easeFactor;

  @HiveField(3)
  int interval; // in days

  @HiveField(4)
  DateTime lastReviewed;

  @HiveField(5)
  DateTime nextReview;

  @HiveField(6)
  bool spacedRepetitionEnabled;

  UserQuestionData({
    required this.questionId,
    this.streak = 0,
    this.easeFactor = 2.5, // default Anki starting EF
    this.interval = 0,
    this.spacedRepetitionEnabled = false,
    DateTime? lastReviewed,
    DateTime? nextReview,
  })  : lastReviewed = lastReviewed ?? DateTime.now(),
        nextReview = nextReview ?? DateTime.now();

  /// Updates the SRS fields using IRAS/SM2 logic
  void updateAfterAnswer(SrsQuality quality) {
    final now = DateTime.now();
    lastReviewed = now;

    if (quality == SrsQuality.again) {
      // Again: reset interval
      streak = 0;
      interval = 1;
    } else {
      streak++;
      double factorMultiplier;
      switch (quality) {
        case SrsQuality.hard:
          factorMultiplier = 0.9;
          break;
        case SrsQuality.good:
          factorMultiplier = 1.0;
          break;
        case SrsQuality.easy:
          factorMultiplier = 1.2;
          break;
        default:
          factorMultiplier = 1.0;
      }

      easeFactor *= factorMultiplier;
      easeFactor = easeFactor.clamp(1.3, 2.5); // min/max EF

      if (streak == 1) {
        interval = 1;
      } else if (streak == 2) {
        interval = 6;
      } else {
        interval = (interval * easeFactor).round();
      }
    }

    nextReview = now.add(Duration(days: interval));
  }

  bool get isDue =>spacedRepetitionEnabled && nextReview.isBefore(DateTime.now());
}
