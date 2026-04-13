import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Returns the directory where app-internal data (SQLite DB, Hive boxes)
/// should be stored.
///
/// On Windows: %AppData%\Roaming\<app> (via [getApplicationSupportDirectory]).
/// On other platforms: the application documents directory.
///
/// In debug builds a `debug` subdirectory is appended so debug state never
/// pollutes live data.
Future<Directory> getAppStorageDir() async {
  final base = Platform.isWindows
      ? await getApplicationSupportDirectory()
      : await getApplicationDocumentsDirectory();

  final dir = kDebugMode ? Directory(p.join(base.path, 'debug')) : base;

  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  return dir;
}
