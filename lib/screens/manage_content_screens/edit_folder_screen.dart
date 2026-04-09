import 'package:flutter/material.dart';
import 'package:med_brew/data/database/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:med_brew/services/question_service.dart';
import 'package:med_brew/widgets/image_picker_field.dart';

class EditFolderScreen extends StatefulWidget {
  final AppDatabase db;
  final Folder? existing;
  /// The parent folder to create inside; null means root level.
  final int? parentFolderId;

  const EditFolderScreen({
    super.key,
    required this.db,
    this.existing,
    this.parentFolderId,
  });

  @override
  State<EditFolderScreen> createState() => _EditFolderScreenState();
}

class _EditFolderScreenState extends State<EditFolderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickerKey = GlobalKey<ImagePickerFieldState>();
  late final TextEditingController _titleController;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.existing?.title ?? '');
    _imagePath = widget.existing?.imagePath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Folder' : 'Add Folder'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Folder name',
                border: OutlineInputBorder(),
              ),
              autofocus: !isEditing,
              validator: (v) => v!.trim().isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 20),
            ImagePickerField(
              key: _pickerKey,
              label: 'Folder image (optional)',
              initialPath: _imagePath,
              onChanged: (path) => setState(() => _imagePath = path),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: Text(isEditing ? 'Save Changes' : 'Add Folder'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final title = _titleController.text.trim();
    final imagePath =
        await _pickerKey.currentState?.applyAutoName('folder_$title') ??
            _imagePath;
    final existing = widget.existing;
    if (existing == null) {
      await widget.db.insertFolder(FoldersCompanion.insert(
        title: title,
        imagePath: Value(imagePath),
        parentFolderId: Value(widget.parentFolderId),
      ));
    } else {
      await widget.db.updateFolder(FoldersCompanion(
        id: Value(existing.id),
        parentFolderId: Value(existing.parentFolderId),
        title: Value(title),
        imagePath: Value(imagePath),
        isPermanent: Value(existing.isPermanent),
      ));
    }
    await QuestionService().refresh();
    if (mounted) Navigator.pop(context);
  }
}
