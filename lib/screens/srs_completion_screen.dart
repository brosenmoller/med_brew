import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:med_brew/models/question_data.dart';
import 'package:med_brew/models/quiz_data.dart';
import 'package:med_brew/screens/srs_session_screen.dart';
import 'package:med_brew/services/question_service.dart';
import 'package:med_brew/services/srs_service.dart';

class SrsCompletionScreen extends StatelessWidget {
  final String completedQuizTitle;
  final int reviewedCount;

  const SrsCompletionScreen({
    super.key,
    required this.completedQuizTitle,
    required this.reviewedCount,
  });

  /// Quizzes that still have due questions right now.
  List<({QuizData quiz, List<QuestionData> due})> _dueQuizzes() {
    final qs = QuestionService();
    final srs = SrsService();
    final result = <({QuizData quiz, List<QuestionData> due})>[];

    for (final quiz in qs.getAllQuizzes()) {
      final due = quiz.questionIds
          .map((id) => qs.getQuestion(id))
          .whereType<QuestionData>()
          .where((q) =>
              srs.getUserData(q).spacedRepetitionEnabled &&
              srs.getUserData(q).isDue)
          .toList();
      if (due.isNotEmpty) result.add((quiz: quiz, due: due));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final due = _dueQuizzes();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Complete'),
        centerTitle: true,
      ),
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.escape)) {
            Navigator.pop(context);
          }
        },
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.all(24),
          children: [
            // ── Summary ──────────────────────────────────────────────
            const Icon(Icons.check_circle_outline,
                size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              completedQuizTitle,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '$reviewedCount question${reviewedCount == 1 ? '' : 's'} reviewed',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // ── Due quizzes / all-caught-up ───────────────────────────
            if (due.isEmpty) ...[
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    'All caught up!',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'No more questions due right now.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ] else ...[
              Text(
                'Still due',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: Colors.grey),
              ),
              const SizedBox(height: 8),
              ...due.map((entry) => _DueQuizTile(
                    quizTitle: entry.quiz.title,
                    dueCount: entry.due.length,
                    onStart: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SrsSessionScreen(
                          questions: entry.due,
                          sessionTitle: entry.quiz.title,
                        ),
                      ),
                    ),
                  )),
            ],

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Spaced Repetition'),
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }
}

class _DueQuizTile extends StatelessWidget {
  final String quizTitle;
  final int dueCount;
  final VoidCallback onStart;

  const _DueQuizTile({
    required this.quizTitle,
    required this.dueCount,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(quizTitle),
        subtitle: Text('$dueCount question${dueCount == 1 ? '' : 's'} due'),
        trailing: FilledButton(
          onPressed: onStart,
          child: const Text('Start'),
        ),
      ),
    );
  }
}
