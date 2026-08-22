import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Stores household photos as local files and references them by absolute path
/// from the database. Images are NOT stored as blobs in SQLite (§29).
///
/// All photos live under `<appSupport>/photos/`. Paths are valid on the device
/// that created them, which is exactly the single-tablet model this app targets.
class PhotoStorage {
  PhotoStorage._();

  static Future<Directory> _photosDir() async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(p.join(base.path, 'photos'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Copies the picked image at [sourcePath] into local storage under a name
  /// derived from [id]. Returns the stored absolute path.
  static Future<String> save(String sourcePath, String id) async {
    final dir = await _photosDir();
    final ext = p.extension(sourcePath).isNotEmpty
        ? p.extension(sourcePath)
        : '.jpg';
    // Unique suffix so replacing a photo doesn't collide with a cached image.
    final name = '${id}_${DateTime.now().millisecondsSinceEpoch}$ext';
    final dest = p.join(dir.path, name);
    await File(sourcePath).copy(dest);
    return dest;
  }

  /// Best-effort deletion of a stored photo (ignored if missing).
  static Future<void> delete(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final f = File(path);
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }
}
