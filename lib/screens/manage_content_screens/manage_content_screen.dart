import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:med_brew/data/database/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:med_brew/services/question_service.dart';
import 'package:med_brew/widgets/image_picker_field.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'manage_quizzes_screen.dart';

class ManageContentScreen extends StatelessWidget {
  final AppDatabase db;

  const ManageContentScreen({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        actions: [
          // ── Import JSON (always visible) ──────────────────────
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import JSON',
            onPressed: () => _importJson(context),
          ),
          // ── Export JSON (always visible) ──────────────────────
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export JSON',
            onPressed: () => _exportJson(context),
          ),
          // ── Export seed.db (debug only) ───────────────────────
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.save_alt),
              tooltip: 'Export seed.db',
              onPressed: () => _exportSeedDb(context),
            ),
        ],
      ),
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
              final category = categories[i];
              // In debug mode, permanent items are also editable
              final canEdit = !category.isPermanent || kDebugMode;
              return ListTile(
                leading: category.imagePath != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    category.imagePath!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image),
                  ),
                )
                    : const CircleAvatar(child: Icon(Icons.folder)),
                title: Text(category.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: category.isPermanent
                    ? Text(
                  kDebugMode ? 'Built-in (editable in debug)' : 'Built-in',
                  style: TextStyle(
                    color: kDebugMode ? Colors.orange : Colors.grey,
                    fontSize: 12,
                  ),
                )
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canEdit) ...[
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit',
                        onPressed: () =>
                            _showCategoryDialog(context, existing: category),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        tooltip: 'Delete',
                        onPressed: () => _confirmDelete(context, category),
                      ),
                    ],
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ManageQuizzesScreen(db: db, category: category),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ── Seed DB export ─────────────────────────────────────────────

  Future<void> _exportSeedDb(BuildContext context) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final source = File(path.join(dir.path, 'med_brew.db'));

      final destPath = path.join(Directory.current.path, 'assets', 'seed.db');
      final dest = File(destPath);
      await source.copy(destPath);

      // Open the copy and mark everything as permanent
      final seedDb = AppDatabase.fromFile(dest);
      await seedDb.markAllPermanent();
      await seedDb.close();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('seed.db saved to $destPath')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  // ── JSON export ────────────────────────────────────────────────

  Future<void> _exportJson(BuildContext context) async {
    try {
      final data = await db.exportToJsonMap();
      final jsonString =
      const JsonEncoder.withIndent('  ').convert(data);

      final dir = await getApplicationDocumentsDirectory();
      final file = File(path.join(dir.path, 'med_brew_export.json'));
      await file.writeAsString(jsonString);

      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Exported to ${file.path}')),
          );
        }
      } else {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'Med Brew export',
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  // ── JSON import ────────────────────────────────────────────────

  Future<void> _importJson(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      await db.importFromJson(data);
      await QuestionService().refresh();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Import successful')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }

  // ── Category dialog ────────────────────────────────────────────
  void _showCategoryDialog(BuildContext context, {Category? existing}) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    String? imagePath = existing?.imagePath;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add Category' : 'Edit Category'),
          content: SingleChildScrollView(   // needed because picker adds height
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
                    label: 'Category image (optional)',
                    initialPath: imagePath,
                    onChanged: (path) => setDialogState(() => imagePath = path),
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
                  await db.insertCategory(CategoriesCompanion.insert(
                    title: titleController.text.trim(),
                    imagePath: Value(imagePath),
                  ));
                } else {
                  await db.updateCategory(CategoriesCompanion(
                    id: Value(existing.id),
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