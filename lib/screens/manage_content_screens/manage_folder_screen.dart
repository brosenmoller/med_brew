import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:med_brew/data/database/app_database.dart';
import 'package:med_brew/screens/manage_content_screens/edit_folder_screen.dart';
import 'package:med_brew/screens/manage_content_screens/edit_quiz_screen.dart';
import 'package:med_brew/screens/manage_content_screens/manage_questions_screen.dart';
import 'package:med_brew/services/question_service.dart';
import 'package:med_brew/widgets/app_image.dart';

/// Shows the contents (subfolders + quizzes) of a folder, or the root if
/// [folder] is null. Navigating into a subfolder pushes another instance.
class ManageFolderScreen extends StatelessWidget {
  final AppDatabase db;
  /// null = root level
  final Folder? folder;

  const ManageFolderScreen({super.key, required this.db, this.folder});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(folder?.title ?? 'Manage Content'),
        bottom: folder != null
            ? const PreferredSize(
                preferredSize: Size.fromHeight(20),
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text('Folder contents',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                ),
              )
            : null,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMenu(context),
        tooltip: 'Add',
        child: const Icon(Icons.add),
      ),
      body: FolderContentsBody(db: db, folder: folder),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: const Text('Add Folder'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditFolderScreen(
                      db: db,
                      parentFolderId: folder?.id,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.quiz_outlined),
              title: const Text('Add Quiz'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditQuizScreen(
                      db: db,
                      folderId: folder?.id,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Exported so ManageContentScreen can embed the root-level view directly.
class FolderContentsBody extends StatelessWidget {
  final AppDatabase db;
  final Folder? folder;

  const FolderContentsBody({super.key, required this.db, this.folder});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Folder>>(
      stream: db.watchSubfolders(folder?.id),
      builder: (context, subSnap) {
        return StreamBuilder<List<Quiz>>(
          stream: db.watchQuizzesInFolder(folder?.id),
          builder: (context, quizSnap) {
            if (!subSnap.hasData || !quizSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final subfolders = subSnap.data!;
            final quizzes = quizSnap.data!;

            if (subfolders.isEmpty && quizzes.isEmpty) {
              return const Center(
                child: Text('Empty. Tap + to add a folder or quiz.'),
              );
            }

            return ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                if (subfolders.isNotEmpty) ...[
                  const _SectionHeader(label: 'Folders'),
                  ...subfolders.map((f) => _FolderTile(db: db, f: f)),
                  const Divider(height: 1),
                ],
                if (quizzes.isNotEmpty) ...[
                  const _SectionHeader(label: 'Quizzes'),
                  ...quizzes.map((q) => _QuizTile(db: db, q: q)),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: Colors.grey, letterSpacing: 1),
      ),
    );
  }
}

class _FolderTile extends StatelessWidget {
  final AppDatabase db;
  final Folder f;
  const _FolderTile({required this.db, required this.f});

  @override
  Widget build(BuildContext context) {
    final canEdit = !f.isPermanent || kDebugMode;
    return ListTile(
      leading: f.imagePath != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: AppImage(
                path: f.imagePath,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            )
          : const CircleAvatar(child: Icon(Icons.folder_outlined)),
      title: Text(f.title,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: f.isPermanent
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
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditFolderScreen(db: db, existing: f),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete',
              onPressed: () => _confirmDeleteFolder(context),
            ),
          ],
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ManageFolderScreen(db: db, folder: f),
        ),
      ),
    );
  }

  void _confirmDeleteFolder(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Folder?'),
        content: Text(
            'This will delete "${f.title}" and everything inside it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await db.deleteFolder(f.id);
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

class _QuizTile extends StatelessWidget {
  final AppDatabase db;
  final Quiz q;
  const _QuizTile({required this.db, required this.q});

  @override
  Widget build(BuildContext context) {
    final canEdit = !q.isPermanent || kDebugMode;
    return ListTile(
      leading: q.imagePath != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: AppImage(
                path: q.imagePath,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            )
          : const CircleAvatar(child: Icon(Icons.quiz_outlined)),
      title: Text(q.title,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: q.isPermanent
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
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditQuizScreen(
                    db: db,
                    folderId: q.folderId,
                    existing: q,
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete',
              onPressed: () => _confirmDeleteQuiz(context),
            ),
          ],
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ManageQuestionsScreen(db: db, quiz: q),
        ),
      ),
    );
  }

  void _confirmDeleteQuiz(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Quiz?'),
        content:
            Text('This will delete "${q.title}" and all its questions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await db.deleteQuiz(q.id);
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
