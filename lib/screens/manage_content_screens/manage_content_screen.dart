import 'package:flutter/material.dart';
import 'package:med_brew/data/database/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:med_brew/services/question_service.dart';
import 'manage_quizzes_screen.dart';

class ManageContentScreen extends StatelessWidget {
  final AppDatabase db;

  const ManageContentScreen({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Categories')),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Category'),
        onPressed: () => _showCategoryDialog(context),
      ),
      body: StreamBuilder<List<Category>>(
        stream: db.watchAllCategories(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final categories = snapshot.data!;
          if (categories.isEmpty) {
            return const Center(
              child: Text('No categories yet. Add one below.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final cat = categories[i];
              return ListTile(
                leading: cat.imagePath != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    cat.imagePath!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image),
                  ),
                )
                    : const CircleAvatar(child: Icon(Icons.folder)),
                title: Text(cat.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: cat.isPermanent
                    ? const Text('Built-in',
                    style: TextStyle(color: Colors.grey, fontSize: 12))
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!cat.isPermanent) ...[
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit',
                        onPressed: () =>
                            _showCategoryDialog(context, existing: cat),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        tooltip: 'Delete',
                        onPressed: () =>
                            _confirmDelete(context, cat),
                      ),
                    ],
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ManageQuizzesScreen(
                      db: db,
                      category: cat,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, {Category? existing}) {
    final titleController =
    TextEditingController(text: existing?.title ?? '');
    final imageController =
    TextEditingController(text: existing?.imagePath ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add Category' : 'Edit Category'),
        content: Form(
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
              const SizedBox(height: 12),
              TextFormField(
                controller: imageController,
                decoration: const InputDecoration(
                  labelText: 'Image path (optional)',
                  hintText: 'assets/images/...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
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
              final imagePath = imageController.text.trim();

              if (existing == null) {
                await db.insertCategory(CategoriesCompanion.insert(
                  title: titleController.text.trim(),
                  imagePath: Value(imagePath.isEmpty ? null : imagePath),
                ));
              } else {
                await db.updateCategory(CategoriesCompanion(
                  id: Value(existing.id),
                  title: Value(titleController.text.trim()),
                  imagePath: Value(imagePath.isEmpty ? null : imagePath),
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
    );
  }

  void _confirmDelete(BuildContext context, Category cat) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text(
            'This will delete "${cat.title}" and all its quizzes and questions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await db.deleteCategory(cat.id);
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