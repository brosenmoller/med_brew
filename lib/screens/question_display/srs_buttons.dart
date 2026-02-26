import 'package:flutter/material.dart';
import 'package:med_brew/models/question_data.dart';
import 'package:med_brew/models/user_question_data.dart';
import 'package:med_brew/services/srs_service.dart';

class SrsButtons extends StatelessWidget {
  final QuestionData question;
  final Function(SrsQuality quality)? onAnswered;

  const SrsButtons({
    super.key,
    required this.question,
    this.onAnswered,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: SrsQuality.values.map((quality) {
        final nextDue = _computeNextReviewForQuality(quality);
        final label = "${_qualityLabel(quality)} (${_formatDuration(nextDue)})";

        return _srsButton(label, () async {
          await SrsService().updateAfterAnswer(question, quality);
          if (onAnswered != null) onAnswered!(quality);
        });
      }).toList(),
    );
  }

  Widget _srsButton(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          child: Text(label),
        ),
      ),
    );
  }

  String _qualityLabel(SrsQuality quality) {
    switch (quality) {
      case SrsQuality.again:
        return "Again";
      case SrsQuality.hard:
        return "Hard";
      case SrsQuality.good:
        return "Good";
      case SrsQuality.easy:
        return "Easy";
    }
  }

  /// Simulate next review datetime if this quality is chosen
  DateTime _computeNextReviewForQuality(SrsQuality quality) {
    final userData = SrsService().getUserData(question);
    final simulated = userData.copy();
    simulated.updateAfterAnswer(quality);
    return simulated.nextReview;
  }

  /// Format the interval nicely for display
  String _formatDuration(DateTime nextReview) {
    final now = DateTime.now();
    final diff = nextReview.difference(now);

    if (diff.inMinutes < 60) {
      return "${diff.inMinutes}m";
    } else if (diff.inHours < 24) {
      return "${diff.inHours}h";
    } else {
      return "${diff.inDays}d";
    }
  }
}
