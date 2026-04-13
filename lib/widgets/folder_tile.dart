import 'package:flutter/material.dart';
import 'package:med_brew/models/folder_data.dart';
import 'package:med_brew/widgets/app_image.dart';

class FolderTile extends StatefulWidget {
  final FolderData folder;
  final VoidCallback onTap;

  const FolderTile({super.key, required this.folder, required this.onTap});

  @override
  State<FolderTile> createState() => _FolderTileState();
}

class _FolderTileState extends State<FolderTile> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.folder.imagePath != null;
    final baseColor = Theme.of(context).colorScheme.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedScale(
        scale: _hovering ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: GestureDetector(
          onTap: widget.onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(alpha: _hovering ? 0.25 : 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Base colour (shows only when there is no image)
                  ColoredBox(color: baseColor),

                  // Image layer — always painted, no flash
                  if (hasImage)
                    AppImage(
                      path: widget.folder.imagePath,
                      fit: BoxFit.cover,
                    ),

                  // Darkening overlay, animated so it never causes a flash
                  AnimatedOpacity(
                    opacity: _hovering ? 0.25 : 0.4,
                    duration: const Duration(milliseconds: 150),
                    child: const ColoredBox(color: Colors.black),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),
                        Text(
                          widget.folder.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const Spacer(),
                        // Type badge
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: _TypeBadge(
                            icon: Icons.folder_outlined,
                            label: 'Folder',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TypeBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 12),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
