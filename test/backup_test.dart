import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:elderly_comm/core/data/config_backup.dart';
import 'package:elderly_comm/core/models/models.dart';
import 'package:elderly_comm/core/services/backup_service.dart';
import 'package:elderly_comm/core/services/photo_storage.dart';

import 'support/memory_store.dart';

void main() {

  test('ConfigCodec round-trips a full config through JSON', () async {
    final store = MemoryStore();
    final original = await store.load();

    final json = ConfigCodec.configToJson(original);
    // Survives an actual JSON encode/decode (catches non-serializable values).
    final restored = ConfigCodec.configFromJson(
        (jsonDecode(jsonEncode(json)) as Map).cast<String, dynamic>());

    expect(restored.householdName, original.householdName);
    expect(restored.elderLang, original.elderLang);
    expect(restored.situations.length, original.situations.length);
    expect(restored.objects.length, original.objects.length);
    expect(restored.actions.length, original.actions.length);
    expect(restored.object('bowl')!.name['ar'],
        original.object('bowl')!.name['ar']);
    // Nested intents inside routines/common requests survive.
    expect(restored.routines.first.steps.length,
        original.routines.first.steps.length);
  });

  test('BackupService exports and re-imports into a fresh store', () async {
    final source = MemoryStore();
    final config = await source.load();

    const service = BackupService();
    final bytes = await service.exportBytes(config);

    final target = MemoryStore();
    final restored = await service.importBytes(bytes, target);

    expect(restored.householdName, config.householdName);
    expect(restored.objects.length, config.objects.length);
    // replaceAll actually took effect on the target store.
    expect((await target.load()).objects.length, config.objects.length);
  });

  test('Embedded photo bytes survive export and land back on disk', () async {
    final dir = await Directory.systemTemp.createTemp('home_talk_backup_test');
    addTearDown(() => dir.delete(recursive: true));

    // Store imported photos under the temp dir (no plugin bindings in tests).
    PhotoStorage.baseDirOverride = dir;
    addTearDown(() => PhotoStorage.baseDirOverride = null);

    // A real image file referenced by a situation.
    final photo = File('${dir.path}/kitchen.png');
    final pixels = Uint8List.fromList(List.generate(64, (i) => i));
    await photo.writeAsBytes(pixels);

    final config = HouseholdConfig(
      householdName: 'Test',
      elderLang: 'en',
      caregiverLang: 'ar',
      languages: const [Language(code: 'en', label: 'English')],
      situations: [
        Situation(
            id: 'kitchen',
            label: const {'en': 'Kitchen'},
            emoji: '🍳',
            imagePath: photo.path,
            colorKey: 'object'),
      ],
      objects: const [],
      actions: const [],
      locations: const [],
      commonRequests: const [],
      routines: const [],
      helpRequests: const [],
    );

    const service = BackupService();
    final bytes = await service.exportBytes(config);

    // The original path is not leaked into the file; bytes are embedded.
    final envelope = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    expect((envelope['photos'] as Map).length, 1);
    final situationJson = (envelope['config']['situations'] as List).first;
    expect(situationJson['imagePath'], startsWith('embedded:'));

    final target = MemoryStore();
    final restored = await service.importBytes(bytes, target);
    final newPath = restored.situation('kitchen')!.imagePath!;

    expect(newPath, isNot(photo.path)); // rewritten to a fresh local path
    expect(await File(newPath).readAsBytes(), pixels); // same image bytes
    addTearDown(() => File(newPath).delete());
  });

  test('Import rejects a file that is not a Home Talk backup', () async {
    const service = BackupService();
    final junk = Uint8List.fromList(utf8.encode('{"hello":"world"}'));
    expect(
      () => service.importBytes(junk, MemoryStore()),
      throwsA(isA<BackupException>()),
    );
  });
}
