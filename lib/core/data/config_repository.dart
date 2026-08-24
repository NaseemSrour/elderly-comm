import '../models/models.dart';
import 'sample_data.dart';

/// Abstraction over where the household configuration comes from.
///
/// Phase 1 uses [SampleConfigRepository] (in-memory). Phase 2 will add a
/// `SqliteConfigRepository` implementing this same interface — the UI never
/// changes, because it only ever talks to this abstraction.
abstract class ConfigRepository {
  Future<HouseholdConfig> load();
}

/// A repository the family can also write to (Admin Mode, Phase 3). Kept
/// separate from [ConfigRepository] so Elder Mode only ever sees read access.
abstract class ConfigStore implements ConfigRepository {
  Future<void> saveHousehold({
    required String name,
    required String elderLang,
    required String caregiverLang,
    required double fontScale,
  });

  Future<void> upsertSituation(Situation s);
  Future<void> deleteSituation(String id);

  Future<void> upsertObject(CommunicationObject o);
  Future<void> deleteObject(String id);

  Future<void> upsertAction(ActionDef a);
  Future<void> deleteAction(String id);

  Future<void> upsertLocation(LocationDef l);
  Future<void> deleteLocation(String id);

  Future<void> upsertCommonRequest(CommonRequest c);
  Future<void> deleteCommonRequest(String id);

  Future<void> upsertRoutine(Routine r);
  Future<void> deleteRoutine(String id);

  Future<void> upsertHelpRequest(HelpRequest h);
  Future<void> deleteHelpRequest(String id);

  /// Replaces the ENTIRE stored configuration with [config] in one atomic step.
  /// Used by import/restore — every existing situation, object, action, etc. is
  /// discarded and replaced. Household settings are overwritten too.
  Future<void> replaceAll(HouseholdConfig config);
}

class SampleConfigRepository implements ConfigRepository {
  const SampleConfigRepository();

  @override
  Future<HouseholdConfig> load() async => buildSampleConfig();
}
