import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../data/config_backup.dart';
import '../data/config_repository.dart';
import '../models/models.dart';
import 'photo_storage.dart';

/// Thrown when an imported file isn't a valid/compatible Home Talk backup.
/// The [message] is safe to show directly to the family.
class BackupException implements Exception {
  final String message;
  BackupException(this.message);
  @override
  String toString() => message;
}

/// Builds and restores a single self-contained backup file carrying the entire
/// household configuration AND its photos, so the family can move everything
/// they set up to another tablet.
///
/// The file is UTF-8 JSON: a small envelope wrapping the config (see
/// [ConfigCodec]) plus a `photos` map of base64-encoded image bytes. Because
/// photos live on disk by absolute path — meaningless on another device — export
/// inlines the bytes and rewrites each [imagePath] to an `embedded:<token>`
/// reference; import writes the bytes back out via [PhotoStorage] and resolves
/// the tokens to fresh local paths.
///
/// This class deals only in bytes; choosing where to save / which file to open
/// is the UI's job (file picker). That keeps it fully unit-testable.
class BackupService {
  const BackupService();

  static const String _embedPrefix = 'embedded:';

  /// Serializes [config] and its photos into the bytes of a backup file.
  Future<Uint8List> exportBytes(HouseholdConfig config) async {
    final configJson = ConfigCodec.configToJson(config);
    final photos = <String, Map<String, String>>{};
    final tokenByPath = <String, String>{};

    Future<void> embed(Object? items) async {
      for (final item in ((items as List?) ?? const [])
          .cast<Map<String, dynamic>>()) {
        final path = item['imagePath'] as String?;
        if (path == null || path.isEmpty) continue;
        var token = tokenByPath[path];
        if (token == null) {
          final file = File(path);
          if (!await file.exists()) {
            item['imagePath'] = null; // photo went missing — drop the reference
            continue;
          }
          token = 'p${photos.length}';
          photos[token] = {
            'ext': p.extension(path),
            'data': base64Encode(await file.readAsBytes()),
          };
          tokenByPath[path] = token;
        }
        item['imagePath'] = '$_embedPrefix$token';
      }
    }

    // Only situations and objects carry photos.
    await embed(configJson['situations']);
    await embed(configJson['objects']);

    final envelope = <String, dynamic>{
      'format': ConfigCodec.formatTag,
      'version': ConfigCodec.formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'config': configJson,
      'photos': photos,
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
  }

  /// Parses backup [bytes], writes any embedded photos to local storage, and
  /// atomically replaces the whole configuration in [store]. Returns the
  /// restored config. Throws [BackupException] on an invalid/incompatible file.
  Future<HouseholdConfig> importBytes(
    Uint8List bytes,
    ConfigStore store,
  ) async {
    final Map<String, dynamic> envelope;
    try {
      envelope = (jsonDecode(utf8.decode(bytes)) as Map).cast<String, dynamic>();
    } catch (_) {
      throw BackupException("This file isn't a valid Home Talk backup.");
    }

    if (envelope['format'] != ConfigCodec.formatTag) {
      throw BackupException("This file isn't a Home Talk backup.");
    }
    final version = envelope['version'] as int? ?? 0;
    if (version > ConfigCodec.formatVersion) {
      throw BackupException(
          'This backup was made by a newer version of Home Talk. '
          'Please update the app on this tablet first.');
    }

    final configJson =
        (envelope['config'] as Map?)?.cast<String, dynamic>() ?? {};
    final photos =
        (envelope['photos'] as Map?)?.cast<String, dynamic>() ?? const {};

    // Write each embedded photo to disk and remember its new local path.
    final resolved = <String, String>{};
    for (final entry in photos.entries) {
      final meta = (entry.value as Map).cast<String, dynamic>();
      resolved[entry.key] = await PhotoStorage.saveBytes(
        base64Decode(meta['data'] as String),
        'import_${entry.key}',
        ext: meta['ext'] as String? ?? '.jpg',
      );
    }

    void resolvePaths(Object? items) {
      for (final item in ((items as List?) ?? const [])
          .cast<Map<String, dynamic>>()) {
        final path = item['imagePath'] as String?;
        if (path != null && path.startsWith(_embedPrefix)) {
          // Null if the token is missing — a dropped photo, not a crash.
          item['imagePath'] = resolved[path.substring(_embedPrefix.length)];
        }
      }
    }

    resolvePaths(configJson['situations']);
    resolvePaths(configJson['objects']);

    final config = ConfigCodec.configFromJson(configJson);
    await store.replaceAll(config);
    return config;
  }

  /// A friendly, filesystem-safe default filename for an export.
  String suggestedFileName(HouseholdConfig config) {
    final slug = config.householdName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final now = DateTime.now();
    final date = '${now.year}-${_two(now.month)}-${_two(now.day)}';
    final name = slug.isEmpty ? 'home-talk' : 'home-talk-$slug';
    return '$name-$date.json';
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
