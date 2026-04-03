import 'dart:io';
import 'package:flutter/material.dart';

class AppImage extends StatelessWidget {
  final String? path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const AppImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (path == null) return const SizedBox.shrink();

    final fallback = errorBuilder ??
            (_, __, ___) => const Icon(Icons.broken_image);

    if (path!.startsWith('assets/')) {
      return Image.asset(
        path!,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: fallback,
      );
    }

    return Image.file(
      File(path!),
      fit: fit,
      width: width,
      height: height,
      errorBuilder: fallback,
    );
  }
}