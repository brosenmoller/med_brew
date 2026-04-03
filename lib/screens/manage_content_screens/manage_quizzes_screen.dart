import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:med_brew/data/database/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:med_brew/screens/manage_content_screens/edit_quiz_screen.dart';
import 'package:med_brew/services/question_service.dart';
import 'package:med_brew/widgets/image_picker_field.dart';
import 'manage_questions_screen.dart';

class ManageQuizzesScreen extends StatelessWidget {
  final AppDatabase db;
  final Category category;

  const ManageQuizzesScreen({
    super.key,
    required this.db,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category.title),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(20),
          child: Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('Quizzes',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Quiz'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditQuizScreen(db: db, categoryId: category.id),
          ),
        ),
      ),
      body: StreamBuilder<List<Quiz>>(
        stream: db.watchQuizzesForCategory(category.id),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final quizzes = snapshot.data!;
          if (quizzes.isEmpty) {
            return const Center(child: Text('No quizzes yet. Add one below.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: quizzes.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final quiz = quizzes[i];
              final canEdit = !quiz.isPermanent || kDebugMode;
              return ListTile(
                leading: quiz.imagePath != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    quiz.imagePath!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image),
                  ),
                )
                    : const CircleAvatar(child: Icon(Icons.quiz)),
                title: Text(quiz.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: quiz.isPermanent
                    ? const Text('Built-in',
                    style: TextStyle(color: Colors.grey, fontSize: 12))
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canEdit) ...[
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditQuizScreen(
                              db: db,
                              categoryId: category.id,
                              existing: quiz,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        tooltip: 'Delete',
                        onPressed: () => _confirmDelete(context, quiz),
                      ),
                    ],
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ManageQuestionsScreen(db: db, quiz: quiz),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showQuizDialog(BuildContext context, {Quiz? existing}) {
    final titleController =
    TextEditingController(text: existing?.title ?? '');
    String? imagePath = existing?.imagePath;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add Quiz' : 'Edit Quiz'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.trim().isEmpty ? 'Required' : null,
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  ImagePickerField(
                    label: 'Quiz image (optional)',
                    initialPath: imagePath,
                    onChanged: (path) =>
                        setDialogState(() => imagePath = path),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                if (existing == null) {
                  await db.insertQuiz(QuizzesCompanion.insert(
                    categoryId: category.id,
                    title: titleController.text.trim(),
                    imagePath: Value(imagePath),
                  ));
                } else {
                  await db.updateQuiz(QuizzesCompanion(
                    id: Value(existing.id),
                    categoryId: Value(existing.categoryId),
                    title: Value(titleController.text.trim()),
                    imagePath: Value(imagePath),
                    isPermanent: Value(existing.isPermanent),
                  ));
                }
                await QuestionService().refresh();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: Text(existing == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Quiz quiz) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Quiz?'),
        content:
        Text('This will delete "${quiz.title}" and all its questions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await db.deleteQuiz(quiz.id);
              await QuestionService().refresh();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}