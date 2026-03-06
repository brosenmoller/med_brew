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
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'How well did you know this?',
          style: Theme.of(context).textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Row(
          children: SrsQuality.values.map((quality) {
            final nextDue = _computeNextReviewForQuality(quality);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _SrsChip(
                  quality: quality,
                  nextReview: _formatDuration(nextDue),
                  onTap: () => onAnswered?.call(quality),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  DateTime _computeNextReviewForQuality(SrsQuality quality) {
    final userData = SrsService().getUserData(question);
    final simulated = userData.copy();
    simulated.updateAfterAnswer(quality);
    return simulated.nextReview;
  }

  String _formatDuration(DateTime nextReview) {
    final diff = nextReview.difference(DateTime.now());
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

class _SrsChip extends StatelessWidget {
  final SrsQuality quality;
  final String nextReview;
  final VoidCallback onTap;

  const _SrsChip({
    required this.quality,
    required this.nextReview,
    required this.onTap,
  });

  Color _color() {
    switch (quality) {
      case SrsQuality.again:
        return Colors.red.shade400;
      case SrsQuality.hard:
        return Colors.orange.shade400;
      case SrsQuality.good:
        return Colors.blue.shade500;
      case SrsQuality.easy:
        return Colors.green.shade500;
    }
  }

  String _label() {
    switch (quality) {
      case SrsQuality.again:
        return 'Again';
      case SrsQuality.hard:
        return 'Hard';
      case SrsQuality.good:
        return 'Good';
      case SrsQuality.easy:
        return 'Easy';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: _color(),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_label(),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(nextReview,
              style: const TextStyle(fontSize: 12, color: Colors.white70)),
        ],
      ),
    );
  }
}