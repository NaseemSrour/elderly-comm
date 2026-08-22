import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elderly_comm/app.dart';
import 'package:elderly_comm/core/data/sample_data.dart';
import 'package:elderly_comm/core/models/models.dart';
import 'package:elderly_comm/core/services/intent_renderer.dart';
import 'package:elderly_comm/features/admin/admin_editors.dart';
import 'package:elderly_comm/features/elder/widgets.dart';

import 'support/memory_store.dart';

void main() {
  test('IntentRenderer builds the marquee request deterministically', () {
    final config = buildSampleConfig();
    final renderer = IntentRenderer(config);

    // Kitchen → Bowl → Bring → Me
    final r = renderer.render(const SemanticIntent(
      objectId: 'bowl',
      actionId: 'BRING',
      destinationId: 'TO_ME',
    ));

    expect(r.caregiverText, 'Bring me a bowl.');
    expect(r.elderText, 'جيبلي جاط.');
    expect(r.emoji, '🥣');
  });

  test('Empty destination tokens collapse cleanly', () {
    final config = buildSampleConfig();
    final renderer = IntentRenderer(config);

    final r = renderer.render(const SemanticIntent(
      objectId: 'bedroom_window',
      actionId: 'OPEN',
    ));
    expect(r.caregiverText, 'Open the window.');
  });

  testWidgets('Home shows common requests and rooms', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ElderApp(store: MemoryStore(), initialConfig: buildSampleConfig()),
    );
    await tester.pumpAndSettle();

    // A common request (Arabic: "bring me water") and a room (Kitchen).
    expect(find.text('جيبلي مي'), findsOneWidget);
    expect(find.text('المطبخ'), findsWidgets);
    expect(find.text('🆘'), findsOneWidget);
  });

  testWidgets('Admin object form opens without inherited-widget error',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(AppScope(
      config: buildSampleConfig(),
      store: MemoryStore(),
      reload: () async {},
      lastIntent: ValueNotifier<SemanticIntent?>(null),
      child: const MaterialApp(home: ObjectForm(existing: null)),
    ));
    await tester.pumpAndSettle();

    // The form built (initState read AppScope without a dependency error).
    expect(tester.takeException(), isNull);
    expect(find.text('New object'), findsOneWidget);
  });
}
