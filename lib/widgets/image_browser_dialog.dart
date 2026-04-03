import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class ImageBrowserDialog extends StatefulWidget {
  const ImageBrowserDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (_) => const ImageBrowserDialog(),
    );
  }

  @override
  State<ImageBrowserDialog> createState() => _ImageBrowserDialogState();
}

class _ImageBrowserDialogState extends State<ImageBrowserDialog> {
  List<_ImageEntry> _images = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    final entries = <_ImageEntry>[];

    // ── Bundled asset images ──────────────────────────────────────
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    for (final key in manifest.listAssets()) {
      if (key.startsWith('assets/images/') && _isImageExtension(key)) {
        entries.add(_ImageEntry(
          displayName: p.basename(key),
          path: key,
          source: 'Bundled',
          isAsset: true,
        ));
      }
    }

    // ── User-added images ─────────────────────────────────────────
    if (!kDebugMode) {
      final dir = await getApplicationDocumentsDirectory();
      final imgDir = Directory(p.join(dir.path, 'images'));
      if (imgDir.existsSync()) {
        for (final file in imgDir.listSync().whereType<File>()) {
          if (_isImageExtension(file.path)) {
            entries.add(_ImageEntry(
              displayName: p.basename(file.path),
              path: file.path,
              source: 'My images',
              isAsset: false,
            ));
          }
        }
      }
    }

    entries.sort((a, b) => a.displayName.compareTo(b.displayName));
    setState(() {
      _images = entries;
      _loading = false;
    });
  }

  bool _isImageExtension(String path) {
    final ext = p.extension(path).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.webp', '.gif'].contains(ext);
  }

  List<_ImageEntry> get _filtered {
    if (_search.isEmpty) return _images;
    return _images
        .where((e) =>
        e.displayName.toLowerCase().contains(_search.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding:
      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 600),
        child: Column(
          children: [
            // ── Header ───────────────────────────────────────────
            Padding(
              padding:
              const EdgeInsets.fromLTRB(20, 20, 12, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text('Choose existing image',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // ── Search ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search images...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _search = v),
              ),
            ),

            const Divider(height: 1),

            // ── Content ──────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                  ? Center(
                child: Text(
                  _images.isEmpty
                      ? 'No images found'
                      : 'No results for "$_search"',
                  style: const TextStyle(color: Colors.grey),
                ),
              )
                  : _buildGroupedList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedList() {
    // Group by source label
    final groups = <String, List<_ImageEntry>>{};
    for (final img in _filtered) {
      groups.putIfAbsent(img.source, () => []).add(img);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 12),
      children: [
        for (final entry in groups.entries) ...[
          Padding(
            padding:
            const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              entry.key,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.5),
            ),
          ),
          ...entry.value.map((img) => _ImageTile(
            entry: img,
            onTap: () => Navigator.pop(context, img.path),
          )),
        ],
      ],
    );
  }
}

class _ImageTile extends StatelessWidget {
  final _ImageEntry entry;
  final VoidCallback onTap;

  const _ImageTile({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 56,
          height: 56,
          child: entry.isAsset
              ? Image.asset(entry.path,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image))
              : Image.file(File(entry.path),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image)),
        ),
      ),
      title: Text(entry.displayName,
          style: const TextStyle(fontSize: 14)),
      subtitle: Text(entry.path,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
          overflow: TextOverflow.ellipsis),
      onTap: onTap,
    );
  }
}

class _ImageEntry {
  final String displayName;
  final String path;
  final String source;
  final bool isAsset;

  const _ImageEntry({
    required this.displayName,
    required this.path,
    required this.source,
    required this.isAsset,
  });
}