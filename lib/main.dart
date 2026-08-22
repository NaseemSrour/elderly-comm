import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/data/sqlite_config_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Landscape tablet, kiosk-like immersive mode (hides the Android status /
  // navigation bars so the elder doesn't stumble into system UI). Immersive
  // "sticky" lets a developer still swipe them back temporarily for debugging.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Phase 2: local SQLite persistence (seeded from sample data on first run).
  // Phase 3: the same store is writable, so Admin Mode can edit the household.
  final store = SqliteConfigRepository();
  final config = await store.load();

  runApp(ElderApp(store: store, initialConfig: config));
}
