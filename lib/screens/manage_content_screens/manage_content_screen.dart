import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:med_brew/data/database/app_database.dart';
import 'package:med_brew/screens/manage_content_screens/edit_folder_screen.dart';
import 'package:med_brew/screens/manage_content_screens/edit_quiz_screen.dart';
import 'package:med_brew/screens/manage_content_screens/manage_folder_screen.dart';
import 'package:med_brew/services/question_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Root management screen. Handles import/export/seed and renders the
/// root folder contents via [ManageFolderScreen].
class ManageContentScreen extends StatelessWidget {
  final AppDatabase db;

  const ManageContentScreen({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Content'),
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            tooltip: 'Import JSON',
            onPressed: () => _importJson(context),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export JSON',
            onPressed: () => _exportJson(context),
          ),
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.save_alt),
              tooltip: 'Export seed.db',
              onPressed: () => _exportSeedDb(context),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'root_add_folder',
            icon: const Icon(Icons.create_new_folder_outlined),
            label: const Text('Add Folder'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditFolderScreen(db: db)),
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'root_add_quiz',
            icon: const Icon(Icons.quiz_outlined),
            label: const Text('Add Quiz'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditQuizScreen(db: db)),
            ),
          ),
        ],
      ),
      // Reuse the folder contents view — null folder = root level
      body: FolderContentsBody(db: db, folder: null),
    );
  }

  // ── Seed DB export ──────────────────────────────────────────────

  Future<void> _exportSeedDb(BuildContext context) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final source = File(p.join(dir.path, 'med_brew.db'));
      final destPath =
          p.join(Directory.current.path, 'assets', 'seed.db');
      final dest = File(destPath);
      await source.copy(destPath);

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

  // ── JSON export ─────────────────────────────────────────────────

  Future<void> _exportJson(BuildContext context) async {
    try {
      final data = await db.exportToJsonMap();
      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'med_brew_export.json'));
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

  // ── JSON import ─────────────────────────────────────────────────

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
}
