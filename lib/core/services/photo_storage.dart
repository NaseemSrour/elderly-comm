import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Stores household photos as local files and references them by absolute path
/// from the database. Images are NOT stored as blobs in SQLite (§29).
///
/// All photos live under `<appSupport>/photos/`. Paths are valid on the device
/// that created them, which is exactly the single-tablet model this app targets.
class PhotoStorage {
  PhotoStorage._();

  /// Test seam: when set, photos are stored under this directory instead of the
  /// platform app-support directory (which needs plugin bindings unavailable in
  /// unit tests). Production code never sets this.
  @visibleForTesting
  static Directory? baseDirOverride;

  static Future<Directory> _photosDir() async {
    final base = baseDirOverride ?? await getApplicationSupportDirectory();
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

  /// Writes raw image [bytes] (e.g. decoded from an imported backup) into local
  /// storage under a name derived from [id], and returns the stored absolute
  /// path. [ext] is the file extension including the dot (defaults to `.jpg`).
  static Future<String> saveBytes(
    Uint8List bytes,
    String id, {
    String ext = '.jpg',
  }) async {
    final dir = await _photosDir();
    final safeExt = ext.isNotEmpty ? ext : '.jpg';
    final name = '${id}_${DateTime.now().millisecondsSinceEpoch}$safeExt';
    final dest = p.join(dir.path, name);
    await File(dest).writeAsBytes(bytes);
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
