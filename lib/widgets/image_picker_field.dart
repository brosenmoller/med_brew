import 'dart:io';
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
  State<ImagePickerField> createState() => ImagePickerFieldState();
}

class ImagePickerFieldState extends State<ImagePickerField> {
  String? _currentPath;
  String? _pendingSourcePath;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.initialPath;
  }

  /// True while a file has been picked from the explorer but not yet copied
  /// to app storage. The parent can read this to decide whether to carry the
  /// image across an answer-type switch.
  bool get hasPendingSource => _pendingSourcePath != null;

  /// Called from the parent's save method. If a file was picked from the
  /// explorer but not yet copied, copies it to app storage now and returns
  /// the saved path. Otherwise returns the current path unchanged.
  Future<String?> applyAutoName(String suggestedName) async {
    if (_pendingSourcePath != null) {
      final saved = await _saveImage(_pendingSourcePath!);
      if (mounted) {
        setState(() {
          _currentPath = saved;
          _pendingSourcePath = null;
        });
      }
      return saved;
    }
    return _currentPath;
  }

  Future<String> _saveImage(String sourcePath) async {
    final fileName = p.basename(sourcePath);
    if (kDebugMode) {
      final dest = Directory(p.join(Directory.current.path, 'assets', 'images'));
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
    final sourcePath = result!.files.single.path!;
    await Future.delayed(const Duration(milliseconds: 250));
    if (mounted) {
      setState(() {
        _currentPath = sourcePath;
        _pendingSourcePath = sourcePath;
      });
      widget.onChanged(sourcePath);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (_currentPath != null) ...[
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: AppImage(path: _currentPath, fit: BoxFit.cover, width: 100),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentPath = null;
                      _pendingSourcePath = null;
                    });
                    widget.onChanged(null);
                  },
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
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
          ],
        ),
      ],
    );
  }
}
