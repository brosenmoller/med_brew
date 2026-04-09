import 'dart:io';
import 'package:flutter/material.dart';
import 'package:med_brew/models/folder_data.dart';
import 'package:vector_math/vector_math_64.dart' show Vector3;

class FolderTile extends StatefulWidget {
  final FolderData folder;
  final VoidCallback onTap;

  const FolderTile({super.key, required this.folder, required this.onTap});

  @override
  State<FolderTile> createState() => _FolderTileState();
}

class _FolderTileState extends State<FolderTile> {
  bool _hovering = false;

  ImageProvider? get _imageProvider {
    final path = widget.folder.imagePath;
    if (path == null) return null;
    if (path.startsWith('assets/')) return AssetImage(path);
    return FileImage(File(path));
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = _imageProvider;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: Transform(
        alignment: Alignment.center,
        transform: _hovering
            ? (Matrix4.identity()..scaleByVector3(Vector3.all(1.02)))
            : Matrix4.identity(),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
              image: imageProvider != null
                  ? DecorationImage(
                      image: imageProvider,
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black
                            .withValues(alpha: _hovering ? 0.25 : 0.4),
                        BlendMode.darken,
                      ),
                    )
                  : null,
              boxShadow: [
                BoxShadow(
                  color:
                      Colors.black.withValues(alpha: _hovering ? 0.25 : 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                if (imageProvider == null)
                  const Positioned(
                    right: 10,
                    bottom: 10,
                    child: Icon(Icons.folder_open,
                        size: 36, color: Colors.white30),
                  ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      widget.folder.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
