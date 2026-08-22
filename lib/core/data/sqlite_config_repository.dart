import 'package:sqflite/sqflite.dart';

import '../models/models.dart';
import 'config_repository.dart';
import 'db/app_database.dart';
import 'db/config_mappers.dart';
import 'sample_data.dart';

/// Loads and persists the [HouseholdConfig] in SQLite. Implements the same
/// [ConfigRepository] interface the UI already uses (Phase 1), so swapping this
/// in required no UI changes. On first run it seeds from [buildSampleConfig].
///
/// Beyond [load] it exposes upsert/delete methods that Admin Mode (Phase 3)
/// will drive.
class SqliteConfigRepository implements ConfigStore {
  SqliteConfigRepository({this.path});

  /// Optional explicit path (tests use `inMemoryDatabasePath`).
  final String? path;

  Database? _db;

  Future<Database> get _database async {
    final existing = _db;
    if (existing != null) return existing;
    final db = await AppDatabase.open(path: path);
    await _seedIfEmpty(db);
    _db = db;
    return db;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  // ---------------------------------------------------------------- seeding
  Future<void> _seedIfEmpty(Database db) async {
    final meta = await db.query('app_meta',
        where: 'key = ?', whereArgs: ['seeded'], limit: 1);
    if (meta.isNotEmpty) return;

    final config = buildSampleConfig();
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final l in config.languages) {
        batch.insert('languages', ConfigMappers.languageToRow(l));
      }
      for (final s in config.situations) {
        batch.insert('situations', ConfigMappers.situationToRow(s));
      }
      for (final a in config.actions) {
        batch.insert('actions', ConfigMappers.actionToRow(a));
      }
      for (final loc in config.locations) {
        batch.insert('locations', ConfigMappers.locationToRow(loc));
      }
      for (final o in config.objects) {
        batch.insert('objects', ConfigMappers.objectToRow(o));
      }
      for (final c in config.commonRequests) {
        batch.insert('common_requests', ConfigMappers.commonRequestToRow(c));
      }
      for (final rt in config.routines) {
        batch.insert('routines', ConfigMappers.routineToRow(rt));
      }
      for (final h in config.helpRequests) {
        batch.insert('help_requests', ConfigMappers.helpRequestToRow(h));
      }
      batch.insert('app_meta', {'key': 'household_name', 'value': config.householdName});
      batch.insert('app_meta', {'key': 'elder_lang', 'value': config.elderLang});
      batch.insert('app_meta', {'key': 'caregiver_lang', 'value': config.caregiverLang});
      batch.insert('app_meta', {'key': 'seeded', 'value': '1'});
      await batch.commit(noResult: true);
    });
  }

  // ------------------------------------------------------------------- load
  @override
  Future<HouseholdConfig> load() async {
    final db = await _database;

    final meta = <String, String>{
      for (final row in await db.query('app_meta'))
        row['key'] as String: (row['value'] as String? ?? ''),
    };

    final languages =
        (await db.query('languages')).map(ConfigMappers.languageFromRow).toList();
    final situations = (await db.query('situations', orderBy: 'ord'))
        .map(ConfigMappers.situationFromRow)
        .toList();
    final actions =
        (await db.query('actions')).map(ConfigMappers.actionFromRow).toList();
    final locations = (await db.query('locations', orderBy: 'ord'))
        .map(ConfigMappers.locationFromRow)
        .toList();
    final objects = (await db.query('objects', orderBy: 'ord'))
        .map(ConfigMappers.objectFromRow)
        .toList();
    final commonRequests = (await db.query('common_requests', orderBy: 'ord'))
        .map(ConfigMappers.commonRequestFromRow)
        .toList();
    final routines = (await db.query('routines', orderBy: 'ord'))
        .map(ConfigMappers.routineFromRow)
        .toList();
    final helpRequests = (await db.query('help_requests', orderBy: 'ord'))
        .map(ConfigMappers.helpRequestFromRow)
        .toList();

    return HouseholdConfig(
      householdName: meta['household_name'] ?? 'Home',
      elderLang: meta['elder_lang'] ?? 'en',
      caregiverLang: meta['caregiver_lang'] ?? 'en',
      fontScale: double.tryParse(meta['font_scale'] ?? '') ?? 1.0,
      languages: languages,
      situations: situations,
      objects: objects,
      actions: actions,
      locations: locations,
      commonRequests: commonRequests,
      routines: routines,
      helpRequests: helpRequests,
    );
  }

  // ------------------------------------------------------------- write API
  @override
  Future<void> saveHousehold({
    required String name,
    required String elderLang,
    required String caregiverLang,
    required double fontScale,
  }) async {
    final db = await _database;
    final batch = db.batch();
    batch.insert('app_meta', {'key': 'household_name', 'value': name},
        conflictAlgorithm: ConflictAlgorithm.replace);
    batch.insert('app_meta', {'key': 'elder_lang', 'value': elderLang},
        conflictAlgorithm: ConflictAlgorithm.replace);
    batch.insert('app_meta', {'key': 'caregiver_lang', 'value': caregiverLang},
        conflictAlgorithm: ConflictAlgorithm.replace);
    batch.insert('app_meta', {'key': 'font_scale', 'value': fontScale.toString()},
        conflictAlgorithm: ConflictAlgorithm.replace);
    await batch.commit(noResult: true);
  }

  Future<void> _upsert(String table, Map<String, Object?> row) async {
    final db = await _database;
    await db.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> _delete(String table, String id) async {
    final db = await _database;
    await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<void> upsertSituation(Situation s) =>
      _upsert('situations', ConfigMappers.situationToRow(s));
  @override
  Future<void> deleteSituation(String id) => _delete('situations', id);

  @override
  Future<void> upsertObject(CommunicationObject o) =>
      _upsert('objects', ConfigMappers.objectToRow(o));
  @override
  Future<void> deleteObject(String id) => _delete('objects', id);

  @override
  Future<void> upsertAction(ActionDef a) =>
      _upsert('actions', ConfigMappers.actionToRow(a));
  @override
  Future<void> deleteAction(String id) => _delete('actions', id);

  @override
  Future<void> upsertLocation(LocationDef l) =>
      _upsert('locations', ConfigMappers.locationToRow(l));
  @override
  Future<void> deleteLocation(String id) => _delete('locations', id);

  @override
  Future<void> upsertCommonRequest(CommonRequest c) =>
      _upsert('common_requests', ConfigMappers.commonRequestToRow(c));
  @override
  Future<void> deleteCommonRequest(String id) => _delete('common_requests', id);

  @override
  Future<void> upsertRoutine(Routine r) =>
      _upsert('routines', ConfigMappers.routineToRow(r));
  @override
  Future<void> deleteRoutine(String id) => _delete('routines', id);

  @override
  Future<void> upsertHelpRequest(HelpRequest h) =>
      _upsert('help_requests', ConfigMappers.helpRequestToRow(h));
  @override
  Future<void> deleteHelpRequest(String id) => _delete('help_requests', id);
}
