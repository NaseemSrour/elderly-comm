import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../core/localization/ui_strings.dart';
import '../../core/models/models.dart';
import 'request_display_screen.dart';
import 'widgets.dart';

/// Renders [intent] and opens the final display screen.
void openRequest(BuildContext context, SemanticIntent intent) {
  final scope = AppScope.of(context);
  final rendered = scope.renderer.render(intent);
  Navigator.of(context).push(MaterialPageRoute(
    builder: (_) => RequestDisplayScreen(request: rendered, intent: intent),
  ));
}

/// Step 2: the objects that live in the chosen situation/room.
class ObjectScreen extends StatelessWidget {
  final Situation situation;
  const ObjectScreen({super.key, required this.situation});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final objects = scope.config.objectsIn(situation.id);
    return ElderScaffold(
      question:
          '${situation.emoji}  ${situation.label.forLang(scope.elderLang)}',
      questionRtl: scope.elderRtl,
      body: FitGrid(
        children: [
          for (final o in objects)
            BigCard(
              emoji: o.emoji,
              imagePath: o.imagePath,
              label: o.name.forLang(scope.elderLang),
              color: AppColors.object,
              rtl: scope.elderRtl,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ActionScreen(object: o),
              )),
            ),
        ],
      ),
    );
  }
}

/// Step 3: only the actions that make sense for this object.
class ActionScreen extends StatelessWidget {
  final CommunicationObject object;
  const ActionScreen({super.key, required this.object});

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final ui = UiStrings.of(scope.elderLang);
    final actions = scope.config.actionsFor(object);
    return ElderScaffold(
      question:
          '${object.emoji}  ${ui.whatDoYouWant}',
      questionRtl: scope.elderRtl,
      body: FitGrid(
        children: [
          for (final a in actions)
            BigCard(
              emoji: a.emoji,
              label: a.label.forLang(scope.elderLang),
              color: AppColors.byKey(a.colorKey),
              rtl: scope.elderRtl,
              onTap: () {
                final intent = SemanticIntent(
                  objectId: object.id,
                  actionId: a.id,
                );
                if (a.requiresDestination) {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        DestinationScreen(object: object, action: a),
                  ));
                } else {
                  openRequest(context, intent);
                }
              },
            ),
        ],
      ),
    );
  }
}

/// Step 4 (only when the action needs it): where / to whom.
class DestinationScreen extends StatelessWidget {
  final CommunicationObject object;
  final ActionDef action;
  const DestinationScreen({
    super.key,
    required this.object,
    required this.action,
  });

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final ui = UiStrings.of(scope.elderLang);
    final destinations = scope.config.destinationsFor(object, action);
    return ElderScaffold(
      question: ui.where,
      questionRtl: scope.elderRtl,
      body: FitGrid(
        children: [
          for (final d in destinations)
            BigCard(
              emoji: d.emoji,
              label: d.label.forLang(scope.elderLang),
              color: d.isSelf ? AppColors.self : AppColors.object,
              rtl: scope.elderRtl,
              onTap: () => openRequest(
                context,
                SemanticIntent(
                  objectId: object.id,
                  actionId: action.id,
                  destinationId: d.id,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
