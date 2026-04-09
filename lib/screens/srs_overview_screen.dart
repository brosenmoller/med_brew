import 'package:flutter/material.dart';
import 'package:med_brew/models/question_data.dart';
import 'package:med_brew/screens/srs_session_screen.dart';
import 'package:med_brew/services/question_service.dart';
import 'package:med_brew/services/srs_service.dart';

class SrsOverviewScreen extends StatefulWidget {
  const SrsOverviewScreen({super.key});

  @override
  State<SrsOverviewScreen> createState() => _SrsOverviewScreenState();
}

class _SrsOverviewScreenState extends State<SrsOverviewScreen> {
  final QuestionService questionService = QuestionService();
  final SrsService srsService = SrsService();

  @override
  Widget build(BuildContext context) {
    // Collect all quizzes that have at least one SRS-enabled question,
    // grouped by their immediate parent folder title.
    final allQuizzes = questionService.getAllQuizzes();

    // groupTitle → { quizId → [SRS-enabled questions] }
    final srsData = <String, Map<String, List<QuestionData>>>{};

    for (final quiz in allQuizzes) {
      final questions = quiz.questionIds
          .map((qId) => questionService.getQuestion(qId))
          .whereType<QuestionData>()
          .where((q) => srsService.getUserData(q).spacedRepetitionEnabled)
          .toList();

      if (questions.isEmpty) continue;

      final groupTitle = quiz.parentFolderId != null
          ? (questionService.getFolder(quiz.parentFolderId!)?.title ??
              'Unknown folder')
          : 'General';

      srsData.putIfAbsent(groupTitle, () => {})[quiz.id] = questions;
    }

    if (srsData.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Spaced Repetition')),
        body: const Center(
            child: Text('No spaced repetition questions available')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Spaced Repetition')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: srsData.entries.map((groupEntry) {
            final groupName = groupEntry.key;
            final quizMap = groupEntry.value;

            final hasDueInGroup = quizMap.values.any(
              (qs) => qs.any((q) => srsService.getUserData(q).isDue),
            );

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ExpansionTile(
                initiallyExpanded: hasDueInGroup,
                title: Text(groupName,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                children: quizMap.entries.map((quizEntry) {
                  final quizId = quizEntry.key;
                  final questions = quizEntry.value;
                  final quizTitle =
                      questionService.getQuiz(quizId)?.title ?? quizId;

                  final dueQuestions = questions
                      .where((q) => srsService.getUserData(q).isDue)
                      .toList();
                  final hasDue = dueQuestions.isNotEmpty;

                  final String timingText;
                  if (hasDue) {
                    final dueDates = dueQuestions
                        .map((q) => srsService.getUserData(q).nextReview);
                    final oldest = dueDates.fold(
                        dueDates.first,
                        (a, b) => a.isBefore(b) ? a : b);
                    timingText =
                        'oldest due: ${_fmt(DateTime.now().difference(oldest))} ago';
                  } else {
                    final upcoming = questions
                        .map((q) => srsService.getUserData(q).nextReview);
                    final next = upcoming.fold(
                        upcoming.first,
                        (a, b) => a.isBefore(b) ? a : b);
                    timingText =
                        'next due: ${_fmt(next.difference(DateTime.now()))}';
                  }

                  return ListTile(
                    title: Text(quizTitle),
                    subtitle: Text(
                        '${dueQuestions.length} questions due, $timingText'),
                    trailing: hasDue
                        ? ElevatedButton(
                            onPressed: () =>
                                _start(context, dueQuestions, quizTitle),
                            child: const Text('Start'),
                          )
                        : null,
                  );
                }).toList(),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _start(BuildContext context, List<QuestionData> questions,
      String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SrsSessionScreen(questions: questions, sessionTitle: title),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  String _fmt(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d';
    if (d.inHours > 0) return '${d.inHours}h';
    if (d.inMinutes > 0) return '${d.inMinutes}m';
    return 'now';
  }
}
