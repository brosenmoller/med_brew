import 'package:flutter/material.dart';
import 'package:med_brew/models/question_data.dart';
import 'package:med_brew/models/quiz_data.dart';
import 'package:med_brew/screens/quiz_session_screen.dart';
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
    final entries = <_QuizEntry>[];

    for (final quiz in questionService.getAllQuizzes()) {
      final questions = quiz.questionIds
          .map((id) => questionService.getQuestion(id))
          .whereType<QuestionData>()
          .where((q) => srsService.getUserData(q).spacedRepetitionEnabled)
          .toList();

      if (questions.isEmpty) continue;

      final dueQuestions =
          questions.where((q) => srsService.getUserData(q).isDue).toList();

      final dueDates =
          dueQuestions.map((q) => srsService.getUserData(q).nextReview);

      final DateTime? oldestDue = dueQuestions.isEmpty
          ? null
          : dueDates.reduce((a, b) => a.isBefore(b) ? a : b);

      final upcomingDates =
          questions.map((q) => srsService.getUserData(q).nextReview);
      final DateTime nextUpcoming =
          upcomingDates.reduce((a, b) => a.isBefore(b) ? a : b);

      final folderTitle = quiz.parentFolderId != null
          ? questionService.getFolder(quiz.parentFolderId!)?.title
          : null;

      entries.add(_QuizEntry(
        quiz: quiz,
        quizTitle: quiz.title,
        folderTitle: folderTitle,
        dueQuestions: dueQuestions,
        allQuestions: questions,
        oldestDue: oldestDue,
        nextUpcoming: nextUpcoming,
      ));
    }

    if (entries.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Spaced Repetition')),
        body: const Center(
            child: Text('No spaced repetition questions available')),
      );
    }

    // Due entries first (most overdue at top), then upcoming (soonest first).
    entries.sort((a, b) {
      final aDue = a.oldestDue != null;
      final bDue = b.oldestDue != null;
      if (aDue && bDue) return a.oldestDue!.compareTo(b.oldestDue!);
      if (aDue) return -1;
      if (bDue) return 1;
      return a.nextUpcoming.compareTo(b.nextUpcoming);
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Spaced Repetition')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: entries.length,
            itemBuilder: (context, index) => _QuizCard(
              entry: entries[index],
              onStart: _start,
              onStartNormal: _startNormal,
              onRemoveSrs: _removeSrs,
            ),
          ),
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

  void _startNormal(BuildContext context, QuizData quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizSessionScreen(quizData: quiz),
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _removeSrs(BuildContext context, _QuizEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove from spaced repetition?'),
        content: Text(
          'All SRS progress for "${entry.quizTitle}" will be lost. '
          'This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if ((confirmed ?? false) && mounted) {
      for (final q in entry.allQuestions) {
        await srsService.setQuestionSrs(q, false);
      }
      setState(() {});
    }
  }
}

// ── Popup menu actions ────────────────────────────────────────────────────────

enum _CardAction { startNormal, removeSrs }

// ── Card widget ───────────────────────────────────────────────────────────────

class _QuizCard extends StatelessWidget {
  final _QuizEntry entry;
  final void Function(BuildContext, List<QuestionData>, String) onStart;
  final void Function(BuildContext, QuizData) onStartNormal;
  final void Function(BuildContext, _QuizEntry) onRemoveSrs;

  const _QuizCard({
    required this.entry,
    required this.onStart,
    required this.onStartNormal,
    required this.onRemoveSrs,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasDue = entry.dueQuestions.isNotEmpty;

    final accentColor =
        hasDue ? colorScheme.error : colorScheme.outlineVariant;

    final String timeLabel;
    final Color timeColor;
    if (hasDue) {
      final overdue =
          DateTime.now().difference(entry.oldestDue!);
      timeLabel = 'oldest ${_fmt(overdue)} overdue';
      timeColor = colorScheme.error;
    } else {
      final until = entry.nextUpcoming.difference(DateTime.now());
      timeLabel = 'next in ${_fmt(until)}';
      timeColor = colorScheme.outline;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: hasDue ? 2 : 1,
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Colored left accent bar
              Container(width: 4, color: accentColor),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Left: title + tags
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              entry.quizTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (entry.folderTitle != null)
                                  _Tag(
                                    label: entry.folderTitle!,
                                    icon: Icons.folder_outlined,
                                    color: colorScheme.secondary,
                                  ),
                                _Tag(
                                  label: hasDue
                                      ? '${entry.dueQuestions.length} due'
                                      : '${entry.allQuestions.length} cards',
                                  icon: hasDue
                                      ? Icons.schedule
                                      : Icons.style_outlined,
                                  color: hasDue
                                      ? colorScheme.error
                                      : colorScheme.outline,
                                ),
                                _Tag(
                                  label: timeLabel,
                                  color: timeColor,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Right: start button + overflow menu
                      const SizedBox(width: 8),
                      if (hasDue)
                        FilledButton(
                          onPressed: () => onStart(
                              context,
                              entry.dueQuestions,
                              entry.quizTitle),
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.error,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                          child: const Text('Start'),
                        ),
                      PopupMenuButton<_CardAction>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (action) {
                          if (action == _CardAction.startNormal) {
                            onStartNormal(context, entry.quiz);
                          } else if (action == _CardAction.removeSrs) {
                            onRemoveSrs(context, entry);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: _CardAction.startNormal,
                            child: ListTile(
                              leading: Icon(Icons.play_arrow_outlined),
                              title: Text('Start normal quiz'),
                              subtitle: Text('No SRS scheduling'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          PopupMenuItem(
                            value: _CardAction.removeSrs,
                            child: ListTile(
                              leading: Icon(Icons.remove_circle_outline,
                                  color: Colors.red),
                              title: Text('Remove from SRS',
                                  style: TextStyle(color: Colors.red)),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    if (d.inDays > 0) return '${d.inDays}d';
    if (d.inHours > 0) return '${d.inHours}h';
    if (d.inMinutes > 0) return '${d.inMinutes}m';
    return 'now';
  }
}

// ── Small pill tag ────────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;

  const _Tag({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    final bg = color.withOpacity(0.1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data class ────────────────────────────────────────────────────────────────

class _QuizEntry {
  final QuizData quiz;
  final String quizTitle;
  final String? folderTitle;
  final List<QuestionData> dueQuestions;
  final List<QuestionData> allQuestions;
  final DateTime? oldestDue;
  final DateTime nextUpcoming;

  const _QuizEntry({
    required this.quiz,
    required this.quizTitle,
    required this.folderTitle,
    required this.dueQuestions,
    required this.allQuestions,
    required this.oldestDue,
    required this.nextUpcoming,
  });
}
