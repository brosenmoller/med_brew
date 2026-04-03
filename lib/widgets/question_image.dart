import 'dart:io';
import 'package:flutter/material.dart';

class QuestionImage extends StatelessWidget {
  final String path;
  final double maxHeight;

  const QuestionImage({
    super.key,
    required this.path,
    this.maxHeight = 260,
  });

  @override
  Widget build(BuildContext context) {
    final image = path.startsWith('assets/')
        ? Image.asset(path, fit: BoxFit.contain)
        : Image.file(File(path), fit: BoxFit.contain);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight, maxWidth: 700),
      child: Center(child: image),
    );
  }
}