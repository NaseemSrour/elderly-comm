import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../core/models/models.dart';
import '../../core/services/intent_renderer.dart';
import 'request_display_screen.dart';
import 'widgets.dart';

/// Specific, pre-phrased forms of assistance. Never a bare "Help." — each tile
/// says exactly what is needed.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final helps = [...scope.config.helpRequests]
      ..sort((a, b) => a.order.compareTo(b.order));
    return ElderScaffold(
      question: '🆘',
      body: FitGrid(
        children: [
          for (final h in helps)
            BigCard(
              emoji: h.emoji,
              label: h.phrase.forLang(scope.elderLang),
              color: AppColors.help,
              rtl: scope.elderRtl,
              onTap: () {
                final rendered = RenderedRequest.plain(
                  emoji: h.emoji,
                  caregiverText: h.phrase.forLang(scope.caregiverLang),
                  elderText: h.phrase.forLang(scope.elderLang),
                  caregiverRtl: scope.config
                      .languageFor(scope.caregiverLang)
                      .rtl,
                  elderRtl: scope.elderRtl,
                );
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => RequestDisplayScreen(request: rendered),
                ));
              },
            ),
        ],
      ),
    );
  }
}
