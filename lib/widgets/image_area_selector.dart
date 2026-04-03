import 'package:flutter/material.dart';
import 'package:med_brew/widgets/app_image.dart';

class ImageAreaSelector extends StatefulWidget {
  final String imagePath;
  final Rect? initialRect;
  final ValueChanged<Rect> onRectSelected;

  const ImageAreaSelector({
    super.key,
    required this.imagePath,
    this.initialRect,
    required this.onRectSelected,
  });

  @override
  State<ImageAreaSelector> createState() => _ImageAreaSelectorState();
}

class _ImageAreaSelectorState extends State<ImageAreaSelector> {
  Offset? _start;
  Offset? _end;

  @override
  void initState() {
    super.initState();
  }

  Rect? get _selectedRect {
    if (_start == null || _end == null) return null;
    return Rect.fromPoints(_start!, _end!);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tap top-left corner, then bottom-right to select area',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(builder: (context, constraints) {
          return GestureDetector(
            onTapDown: (details) {
              final pos = details.localPosition;
              setState(() {
                if (_start == null || _end != null) {
                  // Start fresh
                  _start = pos;
                  _end = null;
                } else {
                  _end = pos;
                  final rect = Rect.fromPoints(_start!, _end!);
                  // Normalize to 0.0–1.0
                  final normalized = Rect.fromLTRB(
                    rect.left / constraints.maxWidth,
                    rect.top / constraints.maxHeight,
                    rect.right / constraints.maxWidth,
                    rect.bottom / constraints.maxHeight,
                  );
                  widget.onRectSelected(normalized);
                }
              });
            },
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppImage(
                    path: widget.imagePath,
                    fit: BoxFit.contain,
                    width: constraints.maxWidth,
                  ),
                  if (_start != null && _end == null)
                    Positioned(
                      left: _start!.dx - 10,
                      top: _start!.dy - 10,
                      child: const Icon(Icons.add, color: Colors.orange, size: 20),
                    ),
                  if (_selectedRect != null)
                    Positioned.fromRect(
                      rect: _selectedRect!,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green, width: 2),
                          color: Colors.green.withOpacity(0.2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
        if (_start != null)
          TextButton.icon(
            onPressed: () => setState(() {
              _start = null;
              _end = null;
            }),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reset selection'),
          ),
      ],
    );
  }
}