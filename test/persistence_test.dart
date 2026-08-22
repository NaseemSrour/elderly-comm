import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:elderly_comm/core/data/sqlite_config_repository.dart';
import 'package:elderly_comm/core/models/models.dart';
import 'package:elderly_comm/core/services/intent_renderer.dart';

void main() {
  setUpAll(() {
    // Run SQLite via FFI in the test VM.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('DB seeds from sample data and loads a full config', () async {
    final repo = SqliteConfigRepository(path: inMemoryDatabasePath);
    addTearDown(repo.close);

    final config = await repo.load();

    expect(config.situations.length, 5);
    expect(config.objects.length, 21);
    expect(config.actions.length, 8);
    expect(config.object('bowl')!.name['ar'], 'جاط');

    // The marquee request still renders identically when sourced from SQLite.
    final r = IntentRenderer(config).render(const SemanticIntent(
      objectId: 'bowl',
      actionId: 'BRING',
      destinationId: 'TO_ME',
    ));
    expect(r.caregiverText, 'Bring me a bowl.');
  });

  test('Objects come back ordered by ord', () async {
    final repo = SqliteConfigRepository(path: inMemoryDatabasePath);
    addTearDown(repo.close);
    final config = await repo.load();
    final kitchen = config.objectsIn('kitchen');
    expect(kitchen.first.id, 'bowl');
  });

  test('upsert + delete persist and survive reopening the same file',
      () async {
    final dir = await databaseFactory.getDatabasesPath();
    final path = '$dir/test_${DateTime.now().microsecondsSinceEpoch}.db';

    final repo = SqliteConfigRepository(path: path);
    await repo.load(); // seeds

    await repo.upsertObject(const CommunicationObject(
      id: 'teapot',
      name: {'en': 'a teapot', 'ar': 'إبريق'},
      emoji: '🫖',
      situationId: 'kitchen',
      actionIds: ['BRING'],
      order: 99,
    ));
    await repo.close();

    // Reopen the SAME file: data must still be there.
    final repo2 = SqliteConfigRepository(path: path);
    addTearDown(repo2.close);
    var config = await repo2.load();
    expect(config.object('teapot')!.name['ar'], 'إبريق');

    await repo2.deleteObject('teapot');
    config = await repo2.load();
    expect(config.object('teapot'), isNull);
  });

  test('Admin writes: household + common request persist', () async {
    final repo = SqliteConfigRepository(path: inMemoryDatabasePath);
    addTearDown(repo.close);
    await repo.load(); // seed

    await repo.saveHousehold(
        name: 'Nour House',
        elderLang: 'ar',
        caregiverLang: 'hi',
        fontScale: 1.4);
    await repo.upsertCommonRequest(const CommonRequest(
      id: 'cr_tea',
      label: {'en': 'Bring me tea', 'ar': 'جيبلي شاي'},
      emoji: '🍵',
      order: 9,
      intent: SemanticIntent(
          objectId: 'cup', actionId: 'BRING', destinationId: 'TO_ME'),
    ));

    final config = await repo.load();
    expect(config.householdName, 'Nour House');
    expect(config.caregiverLang, 'hi');
    expect(config.fontScale, 1.4);
    expect(config.commonRequests.any((c) => c.id == 'cr_tea'), isTrue);
  });
}
