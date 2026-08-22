import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../core/localization/ui_strings.dart';
import '../../core/models/models.dart';
import '../admin/admin_gate.dart';
import 'flow_screens.dart';
import 'help_screen.dart';
import 'routine_screen.dart';
import 'widgets.dart';

/// The root. NOT an app dashboard: a wall of large, familiar choices.
/// Top rail = one-tap common requests. Grid below = rooms, routines, help.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final ui = UiStrings.of(scope.elderLang);
    final config = scope.config;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.edgeGuard),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with a hidden long-press to reach Admin Mode.
              GestureDetector(
                onLongPress: () => AdminGate.open(context),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    textDirection:
                        scope.elderRtl ? TextDirection.rtl : TextDirection.ltr,
                    children: [
                      const Text('⭐', style: TextStyle(fontSize: 42)),
                      const SizedBox(width: 10),
                      Text(
                        ui.commonRequests,
                        textDirection: scope.elderRtl
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        style: const TextStyle(
                          fontSize: AppSizes.navLabel,
                          fontWeight: FontWeight.w800,
                          color: AppColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // One-tap common requests.
              SizedBox(
                height: 260,
                child: Row(
                  children: [
                    for (int i = 0;
                        i < config.orderedCommonRequests.length;
                        i++) ...[
                      if (i > 0) const SizedBox(width: AppSizes.gap),
                      Expanded(
                        child: BigCard(
                          emoji: config.orderedCommonRequests[i].emoji,
                          label: config.orderedCommonRequests[i].label
                              .forLang(scope.elderLang),
                          color: AppColors.bring,
                          rtl: scope.elderRtl,
                          onTap: () => openRequest(
                              context, config.orderedCommonRequests[i].intent),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.gap),

              // Rooms + routines + help.
              Expanded(
                child: CardGrid(
                  children: [
                    for (final s in config.orderedSituations)
                      BigCard(
                        emoji: s.emoji,
                        imagePath: s.imagePath,
                        label: s.label.forLang(scope.elderLang),
                        color: AppColors.byKey(s.colorKey),
                        rtl: scope.elderRtl,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ObjectScreen(situation: s),
                          ),
                        ),
                      ),
                    for (final r in config.routines)
                      BigCard(
                        emoji: r.emoji,
                        label: r.label.forLang(scope.elderLang),
                        color: AppColors.routine,
                        rtl: scope.elderRtl,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => RoutineScreen(routine: r),
                          ),
                        ),
                      ),
                    BigCard(
                      emoji: '🆘',
                      label: ui.help,
                      color: AppColors.help,
                      rtl: scope.elderRtl,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const HelpScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
