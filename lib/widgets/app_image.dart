import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

Future<double> resolveImageAspectRatio(String path) {
  final completer = Completer<double>();
  final ImageProvider provider = path.startsWith('assets/')
      ? AssetImage(path) as ImageProvider
      : FileImage(File(path));
  final stream = provider.resolve(ImageConfiguration.empty);
  late ImageStreamListener listener;
  listener = ImageStreamListener((info, _) {
    completer.complete(info.image.width / info.image.height);
    stream.removeListener(listener);
  }, onError: (_, __) {
    if (!completer.isCompleted) completer.complete(16 / 9);
    stream.removeListener(listener);
  });
  stream.addListener(listener);
  return completer.future;
}

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