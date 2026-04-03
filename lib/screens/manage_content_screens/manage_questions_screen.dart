import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:med_brew/data/database/app_database.dart';
import 'package:med_brew/screens/manage_content_screens/add_question_screen.dart';

class ManageQuestionsScreen extends StatelessWidget {
  final AppDatabase db;
  final Quiz quiz;

  const ManageQuestionsScreen({
    super.key,
    required this.db,
    required this.quiz,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(quiz.title),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(20),
          child: Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Questions',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Question'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddQuestionScreen(
              quizId: quiz.id,
              db: db,
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<Question>>(
        stream: db.watchQuestionsForQuiz(quiz.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final questions = snapshot.data!;
          if (questions.isEmpty) {
            return const Center(
                child: Text('No questions yet. Add one below.'));
          }
          return ReorderableListView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: questions.length,
            onReorder: (oldIndex, newIndex) async {
              if (newIndex > oldIndex) newIndex--;
              await db.reorderQuestion(
                  quizId: quiz.id,
                  questionId: questions[oldIndex].id,
                  newIndex: newIndex);
            },
            itemBuilder: (context, i) {
              final question = questions[i];
              final canEdit = !question.isPermanent || kDebugMode;
              return ListTile(
                key: ValueKey(question.id),
                leading: _answerTypeIcon(question.answerType),
                title: Text(
                  question.questionText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Row(
                  children: [
                    _answerTypeChip(question.answerType),
                    if (question.isPermanent) ...[
                      const SizedBox(width: 6),
                      const _Chip(label: 'Built-in', color: Colors.grey),
                    ],
                  ],
                ),
                trailing: canEdit
                    ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddQuestionScreen(
                            quizId: quiz.id,
                            db: db,
                            question: question,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Delete',
                      onPressed: () => _confirmDelete(context, question),
                    ),
                    const Icon(Icons.drag_handle),
                  ],
                )
                    : const Icon(Icons.drag_handle, color: Colors.grey),
              );
            },
          );
        },
      ),
    );
  }

  Widget _answerTypeIcon(String type) {
    return switch (type) {
      'multipleChoice' => const CircleAvatar(
        child: Icon(Icons.list, size: 18),
      ),
      'typed' => const CircleAvatar(
        child: Icon(Icons.keyboard, size: 18),
      ),
      'imageClick' => const CircleAvatar(
        child: Icon(Icons.touch_app, size: 18),
      ),
      _ => const CircleAvatar(child: Icon(Icons.help, size: 18)),
    };
  }

  Widget _answerTypeChip(String type) {
    final label = switch (type) {
      'multipleChoice' => 'Multiple choice',
      'typed'          => 'Typed',
      'imageClick'     => 'Image click',
      _                => type,
    };
    return _Chip(label: label, color: Colors.blue);
  }

  void _confirmDelete(BuildContext context, Question q) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Question?'),
        content: Text('"${q.questionText}"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await db.deleteQuestion(q.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(fontSize: 11, color: color.withOpacity(0.9))),
    );
  }
}