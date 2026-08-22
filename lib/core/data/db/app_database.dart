import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Opens the local SQLite database and owns the schema.
///
/// On Android/iOS the default sqflite factory is used; on Windows/Linux/macOS
/// (development) the FFI factory is installed so the identical code runs on the
/// desktop. Tests pass [path] = `inMemoryDatabasePath`.
class AppDatabase {
  AppDatabase._();

  static const int schemaVersion = 1;
  static bool _ffiReady = false;

  static void _ensureFactory() {
    if (_ffiReady) return;
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
    _ffiReady = true;
  }

  static Future<String> defaultPath() async {
    final dir = await getApplicationSupportDirectory();
    return p.join(dir.path, 'home_talk.db');
  }

  static Future<Database> open({String? path}) async {
    _ensureFactory();
    final dbPath = path ?? await defaultPath();
    return databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, version) => _createSchema(db),
      ),
    );
  }

  static Future<void> _createSchema(Database db) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE app_meta (
        key   TEXT PRIMARY KEY,
        value TEXT
      )''');

    batch.execute('''
      CREATE TABLE languages (
        code  TEXT PRIMARY KEY,
        label TEXT NOT NULL,
        rtl   INTEGER NOT NULL DEFAULT 0
      )''');

    batch.execute('''
      CREATE TABLE situations (
        id         TEXT PRIMARY KEY,
        label_json TEXT NOT NULL,
        emoji      TEXT NOT NULL,
        image_path TEXT,
        color_key  TEXT NOT NULL,
        ord        INTEGER NOT NULL DEFAULT 0
      )''');

    batch.execute('''
      CREATE TABLE actions (
        id                   TEXT PRIMARY KEY,
        label_json           TEXT NOT NULL,
        emoji                TEXT NOT NULL,
        color_key            TEXT NOT NULL,
        requires_object      INTEGER NOT NULL DEFAULT 1,
        requires_destination INTEGER NOT NULL DEFAULT 0,
        templates_json       TEXT NOT NULL
      )''');

    batch.execute('''
      CREATE TABLE locations (
        id          TEXT PRIMARY KEY,
        label_json  TEXT NOT NULL,
        phrase_json TEXT NOT NULL,
        emoji       TEXT NOT NULL,
        is_self     INTEGER NOT NULL DEFAULT 0,
        ord         INTEGER NOT NULL DEFAULT 0
      )''');

    batch.execute('''
      CREATE TABLE objects (
        id                   TEXT PRIMARY KEY,
        name_json            TEXT NOT NULL,
        emoji                TEXT NOT NULL,
        image_path           TEXT,
        situation_id         TEXT NOT NULL,
        action_ids_json      TEXT NOT NULL,
        destination_ids_json TEXT NOT NULL,
        supports_quantity    INTEGER NOT NULL DEFAULT 0,
        ord                  INTEGER NOT NULL DEFAULT 0
      )''');

    batch.execute('''
      CREATE TABLE common_requests (
        id          TEXT PRIMARY KEY,
        label_json  TEXT NOT NULL,
        emoji       TEXT NOT NULL,
        intent_json TEXT NOT NULL,
        ord         INTEGER NOT NULL DEFAULT 0
      )''');

    batch.execute('''
      CREATE TABLE routines (
        id         TEXT PRIMARY KEY,
        label_json TEXT NOT NULL,
        emoji      TEXT NOT NULL,
        color_key  TEXT NOT NULL,
        steps_json TEXT NOT NULL,
        ord        INTEGER NOT NULL DEFAULT 0
      )''');

    batch.execute('''
      CREATE TABLE help_requests (
        id          TEXT PRIMARY KEY,
        phrase_json TEXT NOT NULL,
        emoji       TEXT NOT NULL,
        ord         INTEGER NOT NULL DEFAULT 0
      )''');

    await batch.commit(noResult: true);
  }
}
