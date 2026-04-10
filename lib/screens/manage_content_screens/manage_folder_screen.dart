import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:med_brew/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(folder?.title ?? l10n.manageContentTitle),
        bottom: folder != null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(20),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(l10n.folderContents,
                      style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ),
              )
            : null,
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'add_folder_${folder?.id}',
            icon: const Icon(Icons.create_new_folder_outlined),
            label: Text(l10n.addFolder),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    EditFolderScreen(db: db, parentFolderId: folder?.id),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'add_quiz_${folder?.id}',
            icon: const Icon(Icons.quiz_outlined),
            label: Text(l10n.addQuiz),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditQuizScreen(db: db, folderId: folder?.id),
              ),
            ),
          ),
        ],
      ),
      body: FolderContentsBody(db: db, folder: folder),
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
    final l10n = AppLocalizations.of(context);
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
              return Center(child: Text(l10n.emptyFolderManage));
            }

            return ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                if (subfolders.isNotEmpty) ...[
                  _SectionHeader(label: l10n.foldersSection),
                  ...subfolders.map((f) => _FolderTile(db: db, f: f)),
                  const Divider(height: 1),
                ],
                if (quizzes.isNotEmpty) ...[
                  _SectionHeader(label: l10n.quizzesSection),
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
    final l10n = AppLocalizations.of(context);
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
              kDebugMode ? l10n.builtInDebug : l10n.builtIn,
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
              tooltip: l10n.edit,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditFolderScreen(db: db, existing: f),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: l10n.delete,
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
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteFolderTitle),
        content: Text(l10n.deleteFolderContent(f.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await db.deleteFolder(f.id);
              await QuestionService().refresh();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(l10n.delete),
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
    final l10n = AppLocalizations.of(context);
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
              kDebugMode ? l10n.builtInDebug : l10n.builtIn,
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
              tooltip: l10n.edit,
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
              tooltip: l10n.delete,
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
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteQuizTitle),
        content: Text(l10n.deleteQuizContent(q.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await db.deleteQuiz(q.id);
              await QuestionService().refresh();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}
