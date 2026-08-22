import 'package:flutter/material.dart';

import '../../core/models/models.dart';
import '../../core/services/intent_renderer.dart';

/// Lets the family assemble a [SemanticIntent] (object → action → destination)
/// with a live preview of how it will read. Reused by Common Requests and
/// Routine steps.
class IntentPicker extends StatefulWidget {
  final HouseholdConfig config;
  final SemanticIntent? initial;
  final ValueChanged<SemanticIntent?> onChanged;

  const IntentPicker({
    super.key,
    required this.config,
    required this.initial,
    required this.onChanged,
  });

  @override
  State<IntentPicker> createState() => _IntentPickerState();
}

class _IntentPickerState extends State<IntentPicker> {
  String? _objectId;
  String? _actionId;
  String? _destinationId;

  @override
  void initState() {
    super.initState();
    _objectId = widget.initial?.objectId;
    _actionId = widget.initial?.actionId;
    _destinationId = widget.initial?.destinationId;
  }

  HouseholdConfig get config => widget.config;

  void _emit() {
    if (_objectId == null || _actionId == null) {
      widget.onChanged(null);
      return;
    }
    widget.onChanged(SemanticIntent(
      objectId: _objectId,
      actionId: _actionId!,
      destinationId: _destinationId,
    ));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final lang = config.caregiverLang;
    final object = _objectId == null ? null : config.object(_objectId!);
    final actions = object == null ? <ActionDef>[] : config.actionsFor(object);
    final action = _actionId == null ? null : config.action(_actionId!);
    final needsDest = action?.requiresDestination ?? false;
    final destinations = (object != null && action != null)
        ? config.destinationsFor(object, action)
        : <LocationDef>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _objectId,
          isExpanded: true,
          decoration: const InputDecoration(
              labelText: 'Object', border: OutlineInputBorder()),
          items: [
            for (final o in config.objects)
              DropdownMenuItem(
                value: o.id,
                child: Text('${o.emoji}  ${o.name.forLang(lang)}'),
              ),
          ],
          onChanged: (v) {
            setState(() {
              _objectId = v;
              // Reset downstream selections that may no longer be valid.
              final obj = v == null ? null : config.object(v);
              if (obj != null && !obj.actionIds.contains(_actionId)) {
                _actionId = null;
                _destinationId = null;
              }
            });
            _emit();
          },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _actionId,
          isExpanded: true,
          decoration: const InputDecoration(
              labelText: 'Action', border: OutlineInputBorder()),
          items: [
            for (final a in actions)
              DropdownMenuItem(
                value: a.id,
                child: Text('${a.emoji}  ${a.label.forLang(lang)}'),
              ),
          ],
          onChanged: object == null
              ? null
              : (v) {
                  setState(() {
                    _actionId = v;
                    _destinationId = null;
                  });
                  _emit();
                },
        ),
        if (needsDest) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _destinationId,
            isExpanded: true,
            decoration: const InputDecoration(
                labelText: 'Where / to whom', border: OutlineInputBorder()),
            items: [
              for (final d in destinations)
                DropdownMenuItem(
                  value: d.id,
                  child: Text('${d.emoji}  ${d.label.forLang(lang)}'),
                ),
            ],
            onChanged: (v) {
              setState(() => _destinationId = v);
              _emit();
            },
          ),
        ],
        const SizedBox(height: 12),
        _Preview(config: config, objectId: _objectId, actionId: _actionId, destinationId: _destinationId),
      ],
    );
  }
}

class _Preview extends StatelessWidget {
  final HouseholdConfig config;
  final String? objectId;
  final String? actionId;
  final String? destinationId;

  const _Preview({
    required this.config,
    required this.objectId,
    required this.actionId,
    required this.destinationId,
  });

  @override
  Widget build(BuildContext context) {
    if (objectId == null || actionId == null) {
      return const Text('Pick an object and an action…',
          style: TextStyle(color: Colors.grey));
    }
    final r = IntentRenderer(config).render(SemanticIntent(
      objectId: objectId,
      actionId: actionId!,
      destinationId: destinationId,
    ));
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(r.emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.caregiverText,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(r.elderText,
                    textDirection:
                        r.elderRtl ? TextDirection.rtl : TextDirection.ltr),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
