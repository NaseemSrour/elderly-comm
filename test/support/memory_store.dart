import 'package:elderly_comm/core/data/config_repository.dart';
import 'package:elderly_comm/core/data/sample_data.dart';
import 'package:elderly_comm/core/models/models.dart';

/// A trivial in-memory [ConfigStore] for widget tests — no SQLite/FFI needed.
class MemoryStore implements ConfigStore {
  final HouseholdConfig _config = buildSampleConfig();

  @override
  Future<HouseholdConfig> load() async => _config;

  @override
  Future<void> saveHousehold({
    required String name,
    required String elderLang,
    required String caregiverLang,
    required double fontScale,
  }) async {}

  @override
  Future<void> upsertSituation(Situation s) async {}
  @override
  Future<void> deleteSituation(String id) async {}
  @override
  Future<void> upsertObject(CommunicationObject o) async {}
  @override
  Future<void> deleteObject(String id) async {}
  @override
  Future<void> upsertAction(ActionDef a) async {}
  @override
  Future<void> deleteAction(String id) async {}
  @override
  Future<void> upsertLocation(LocationDef l) async {}
  @override
  Future<void> deleteLocation(String id) async {}
  @override
  Future<void> upsertCommonRequest(CommonRequest c) async {}
  @override
  Future<void> deleteCommonRequest(String id) async {}
  @override
  Future<void> upsertRoutine(Routine r) async {}
  @override
  Future<void> deleteRoutine(String id) async {}
  @override
  Future<void> upsertHelpRequest(HelpRequest h) async {}
  @override
  Future<void> deleteHelpRequest(String id) async {}
}
