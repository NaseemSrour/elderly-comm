import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../core/models/models.dart';
import 'flow_screens.dart';
import 'widgets.dart';

/// A routine shown as a sequence of simple requests. The elder taps each step
/// in turn; each opens the full display screen to show the caregiver.
class RoutineScreen extends StatelessWidget {
  final Routine routine;
  const RoutineScreen({super.key, required this.routine});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return ElderScaffold(
      question: '${routine.emoji}  ${routine.label.forLang(scope.elderLang)}',
      questionRtl: scope.elderRtl,
      body: CardGrid(
        minCardWidth: 260,
        children: [
          for (final step in routine.steps)
            Builder(builder: (context) {
              final r = scope.renderer.render(step);
              return BigCard(
                emoji: r.emoji,
                label: r.elderText,
                color: AppColors.routine,
                rtl: r.elderRtl,
                onTap: () => openRequest(context, step),
              );
            }),
        ],
      ),
    );
  }
}
