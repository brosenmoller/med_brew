import 'dart:io';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'app_image.dart';
import 'image_browser_dialog.dart';

class ImagePickerField extends StatefulWidget {
  final String? initialPath;
  final ValueChanged<String?> onChanged;
  final String label;

  const ImagePickerField({
    super.key,
    this.initialPath,
    required this.onChanged,
    this.label = 'Image',
  });

  @override
  State<ImagePickerField> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends State<ImagePickerField> {
  String? _currentPath;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.initialPath;
  }

  Future<String> _saveImage(String sourcePath) async {
    final fileName = p.basename(sourcePath);
    if (kDebugMode) {
      final dest = Directory(
          p.join(Directory.current.path, 'assets', 'images'));
      if (!dest.existsSync()) dest.createSync(recursive: true);
      await File(sourcePath).copy(p.join(dest.path, fileName));
      return 'assets/images/$fileName';
    } else {
      final dir = await getApplicationDocumentsDirectory();
      final dest = Directory(p.join(dir.path, 'images'));
      if (!dest.existsSync()) dest.createSync(recursive: true);
      final destPath = p.join(dest.path, fileName);
      await File(sourcePath).copy(destPath);
      return destPath;
    }
  }

  // In image_picker_field.dart — all three pick methods
  Future<void> _pickFromExisting() async {
    final picked = await ImageBrowserDialog.show(context);
    if (picked == null) return;
    await Future.delayed(const Duration(milliseconds: 250));
    if (mounted) {
      setState(() => _currentPath = picked);
      widget.onChanged(picked);
    }
  }

  Future<void> _pickFromExplorer() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result?.files.single.path == null) return;
    final saved = await _saveImage(result!.files.single.path!);
    await Future.delayed(const Duration(milliseconds: 250));
    if (mounted) {
      setState(() => _currentPath = saved);
      widget.onChanged(saved);
    }
  }

  Future<void> _handleDrop(String sourcePath) async {
    final ext = p.extension(sourcePath).toLowerCase();
    const allowed = ['.jpg', '.jpeg', '.png', '.webp', '.gif'];
    if (!allowed.contains(ext)) return;
    final saved = await _saveImage(sourcePath);
    await Future.delayed(const Duration(milliseconds: 250));
    if (mounted) {
      setState(() => _currentPath = saved);
      widget.onChanged(saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),

        // ── Drop zone ─────────────────────────────────────────────
        DropTarget(
          onDragEntered: (_) => setState(() => _dragging = true),
          onDragExited: (_) => setState(() => _dragging = false),
          onDragDone: (detail) {
            setState(() => _dragging = false);
            if (detail.files.isNotEmpty) {
              _handleDrop(detail.files.first.path);
            }
          },
          child: GestureDetector(
            onTap: _pickFromExplorer,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _dragging
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade400,
                  width: _dragging ? 2 : 1,
                ),
                color: _dragging
                    ? Theme.of(context)
                    .colorScheme
                    .primary
                    .withOpacity(0.07)
                    : Colors.grey.shade50,
              ),
              child: _currentPath != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: AppImage(
                  path: _currentPath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
                  : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      size: 36, color: Colors.grey.shade500),
                  const SizedBox(height: 8),
                  Text('Click or drag an image here',
                      style:
                      TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // ── Action buttons ────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickFromExplorer,
                icon: const Icon(Icons.file_open_outlined, size: 16),
                label: const Text('New image'),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickFromExisting,
                icon: const Icon(Icons.photo_library_outlined, size: 16),
                label: const Text('Existing image'),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8)),
              ),
            ),
            if (_currentPath != null) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.clear, color: Colors.red),
                tooltip: 'Remove image',
                onPressed: () {
                  setState(() => _currentPath = null);
                  widget.onChanged(null);
                },
              ),
            ],
          ],
        ),

        if (_currentPath != null) ...[
          const SizedBox(height: 4),
          Text(
            _currentPath!,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
        ],

        const SizedBox(height: 4),
        Text(
          kDebugMode
              ? 'New images saved to assets/images/'
              : 'New images saved to local app storage',
          style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
        ),
      ],
    );
  }
}