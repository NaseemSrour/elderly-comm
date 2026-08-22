import 'package:flutter/material.dart';

import 'core/data/config_repository.dart';
import 'core/design/design.dart';
import 'core/models/models.dart';
import 'features/elder/home_screen.dart';
import 'features/elder/widgets.dart';

/// Root widget. Owns the live [HouseholdConfig] and the writable [ConfigStore],
/// and rebuilds Elder Mode whenever Admin Mode edits the data ([reload]).
///
/// [AppScope] sits above [MaterialApp] so every pushed route (elder or admin)
/// can read the config, the renderer, and the store.
class ElderApp extends StatefulWidget {
  final ConfigStore store;
  final HouseholdConfig initialConfig;

  const ElderApp({
    super.key,
    required this.store,
    required this.initialConfig,
  });

  @override
  State<ElderApp> createState() => _ElderAppState();
}

class _ElderAppState extends State<ElderApp> {
  late HouseholdConfig _config = widget.initialConfig;
  final ValueNotifier<SemanticIntent?> _lastIntent = ValueNotifier(null);

  Future<void> _reload() async {
    final fresh = await widget.store.load();
    if (mounted) setState(() => _config = fresh);
  }

  @override
  void dispose() {
    _lastIntent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      config: _config,
      store: widget.store,
      reload: _reload,
      lastIntent: _lastIntent,
      child: MaterialApp(
        title: 'Home Talk',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        // Apply the family-chosen font size on top of any system scaling.
        builder: (context, child) {
          final mq = MediaQuery.of(context);
          return MediaQuery(
            data: mq.copyWith(
              textScaler: TextScaler.linear(
                mq.textScaler.scale(1.0) * _config.fontScale,
              ),
            ),
            child: child!,
          );
        },
        home: const HomeScreen(),
      ),
    );
  }
}
