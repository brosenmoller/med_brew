import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class LusArchiveException implements Exception {
  final String message;
  const LusArchiveException(this.message);
  @override
  String toString() => 'LusArchiveException: $message';
}

/// Handles packing/unpacking the .lus ZIP archive format.
///
/// A .lus file is a ZIP containing:
///   content.json   — the standard export JSON with image paths as basenames
///   images/        — all referenced user image files
///
/// Asset paths (starting with "assets/") are bundled in the app and are
/// left unchanged in content.json; their files are not included in the ZIP.
class LusArchiveService {
  static Future<Uint8List> packToLus(Map<String, dynamic> contentJson) async {
    final normalized = _normalizeImagePaths(contentJson);
    final basenames = _collectImageBasenames(contentJson);

    final imgDir = await _getImagesDir();
    final archive = Archive();

    final contentBytes = const Utf8Encoder().convert(
      const JsonEncoder.withIndent('  ').convert(normalized),
    );
    archive.addFile(
      ArchiveFile('content.json', contentBytes.length, contentBytes),
    );

    for (final name in basenames) {
      final file = File(p.join(imgDir, name));
      if (!await file.exists()) continue;
      final bytes = await file.readAsBytes();
      archive.addFile(ArchiveFile('images/$name', bytes.length, bytes));
    }

    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) throw const LusArchiveException('Failed to encode archive');
    return Uint8List.fromList(encoded);
  }

  static Future<Map<String, dynamic>> unpackFromLus(Uint8List lusBytes) async {
    late final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(lusBytes);
    } catch (_) {
      throw const LusArchiveException('Not a valid .lus archive');
    }

    final contentEntry = archive.findFile('content.json');
    if (contentEntry == null) {
      throw const LusArchiveException('Archive is missing content.json');
    }

    final contentJson = jsonDecode(
      const Utf8Decoder().convert(contentEntry.content as List<int>),
    ) as Map<String, dynamic>;

    final imgDir = await _getImagesDir();

    for (final entry in archive) {
      if (!entry.name.startsWith('images/')) continue;
      final safeName = p.basename(entry.name);
      if (safeName.isEmpty) continue;
      final localFile = File(p.join(imgDir, safeName));
      if (await localFile.exists()) continue;
      await localFile.writeAsBytes(entry.content as List<int>);
    }

    return _localizeImagePaths(contentJson, imgDir);
  }

  // ── Path helpers ─────────────────────────────────────────────────────────

  static bool _isUserPath(String? path) =>
      path != null && !path.startsWith('assets/');

  static String? _normalizePath(String? path) =>
      _isUserPath(path) ? p.basename(path!) : path;

  static String? _localizePath(String? path, String imgDir) {
    if (!_isUserPath(path)) return path;
    final name = p.basename(path!);
    return name.isEmpty ? null : p.join(imgDir, name);
  }

  // ── Collect image basenames from original (un-normalized) JSON ───────────

  static Set<String> _collectImageBasenames(Map<String, dynamic> json) {
    final names = <String>{};

    void add(String? path) {
      if (_isUserPath(path)) names.add(p.basename(path!));
    }

    for (final f in (json['folders'] as List? ?? [])) {
      add((f as Map)['imagePath'] as String?);
    }
    for (final q in (json['quizzes'] as List? ?? [])) {
      add((q as Map)['imagePath'] as String?);
    }
    for (final q in (json['questions'] as List? ?? [])) {
      final qm = q as Map;
      add(qm['imagePath'] as String?);
      for (final v in (qm['imagePathVariants'] as List? ?? [])) {
        add(v as String?);
      }
      final fc = qm['flashcardConfig'] as Map?;
      if (fc != null) {
        add(fc['frontImagePath'] as String?);
        add(fc['backImagePath'] as String?);
      }
    }

    return names;
  }

  // ── Normalize: full paths → basenames ────────────────────────────────────

  static Map<String, dynamic> _normalizeImagePaths(Map<String, dynamic> json) {
    return {
      ...json,
      'folders': (json['folders'] as List? ?? []).map((f) {
        final m = Map<String, dynamic>.from(f as Map);
        m['imagePath'] = _normalizePath(m['imagePath'] as String?);
        return m;
      }).toList(),
      'quizzes': (json['quizzes'] as List? ?? []).map((q) {
        final m = Map<String, dynamic>.from(q as Map);
        m['imagePath'] = _normalizePath(m['imagePath'] as String?);
        return m;
      }).toList(),
      'questions': (json['questions'] as List? ?? []).map((q) {
        final m = Map<String, dynamic>.from(q as Map);
        m['imagePath'] = _normalizePath(m['imagePath'] as String?);
        m['imagePathVariants'] = (m['imagePathVariants'] as List?)
            ?.map((v) => _normalizePath(v as String?))
            .toList();
        final fc = m['flashcardConfig'] as Map?;
        if (fc != null) {
          final fc2 = Map<String, dynamic>.from(fc);
          fc2['frontImagePath'] =
              _normalizePath(fc2['frontImagePath'] as String?);
          fc2['backImagePath'] =
              _normalizePath(fc2['backImagePath'] as String?);
          m['flashcardConfig'] = fc2;
        }
        return m;
      }).toList(),
    };
  }

  // ── Localize: basenames → full paths ─────────────────────────────────────

  static Map<String, dynamic> _localizeImagePaths(
    Map<String, dynamic> json,
    String imgDir,
  ) {
    return {
      ...json,
      'folders': (json['folders'] as List? ?? []).map((f) {
        final m = Map<String, dynamic>.from(f as Map);
        m['imagePath'] = _localizePath(m['imagePath'] as String?, imgDir);
        return m;
      }).toList(),
      'quizzes': (json['quizzes'] as List? ?? []).map((q) {
        final m = Map<String, dynamic>.from(q as Map);
        m['imagePath'] = _localizePath(m['imagePath'] as String?, imgDir);
        return m;
      }).toList(),
      'questions': (json['questions'] as List? ?? []).map((q) {
        final m = Map<String, dynamic>.from(q as Map);
        m['imagePath'] = _localizePath(m['imagePath'] as String?, imgDir);
        m['imagePathVariants'] = (m['imagePathVariants'] as List?)
            ?.map((v) => _localizePath(v as String?, imgDir))
            .toList();
        final fc = m['flashcardConfig'] as Map?;
        if (fc != null) {
          final fc2 = Map<String, dynamic>.from(fc);
          fc2['frontImagePath'] =
              _localizePath(fc2['frontImagePath'] as String?, imgDir);
          fc2['backImagePath'] =
              _localizePath(fc2['backImagePath'] as String?, imgDir);
          m['flashcardConfig'] = fc2;
        }
        return m;
      }).toList(),
    };
  }

  // ── Images directory (mirrors SyncService._getImagesDir) ─────────────────

  static Future<String> _getImagesDir() async {
    if (kDebugMode) {
      return '${Directory.current.path}/assets/images';
    }
    final docDir = await getApplicationDocumentsDirectory();
    final imgDir = Directory('${docDir.path}/images');
    if (!await imgDir.exists()) await imgDir.create(recursive: true);
    return imgDir.path;
  }
}
