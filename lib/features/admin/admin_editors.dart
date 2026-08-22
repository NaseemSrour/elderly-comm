import 'package:flutter/material.dart';

import '../../core/design/design.dart';
import '../../core/models/models.dart';
import '../elder/widgets.dart';
import 'admin_common.dart';
import 'intent_picker.dart';
import 'photo_field.dart';

String _newId(String prefix) =>
    '${prefix}_${DateTime.now().microsecondsSinceEpoch}';

/// Save [op], refresh Elder Mode, then close the form.
Future<void> _saveAndClose(
    BuildContext context, Future<void> Function() op) async {
  await op();
  if (!context.mounted) return;
  await AppScope.of(context).reload();
  if (context.mounted) Navigator.of(context).pop();
}

Widget _colorDropdown(String value, ValueChanged<String?> onChanged) {
  return DropdownButtonFormField<String>(
    initialValue: value,
    isExpanded: true,
    decoration: const InputDecoration(
        labelText: 'Colour', border: OutlineInputBorder()),
    items: [
      for (final key in AppColors.paletteKeys)
        DropdownMenuItem(
          value: key,
          child: Row(children: [
            Container(width: 20, height: 20, color: AppColors.byKey(key)),
            const SizedBox(width: 10),
            Text(key),
          ]),
        ),
    ],
    onChanged: onChanged,
  );
}

// ============================================================ SITUATIONS
class SituationsListScreen extends StatelessWidget {
  const SituationsListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final lang = scope.caregiverLang;
    return AdminListScaffold<Situation>(
      title: 'Rooms / Situations',
      items: scope.config.orderedSituations,
      emojiOf: (s) => s.emoji,
      titleOf: (s) => s.label.forLang(lang),
      subtitleOf: (s) => 'order ${s.order} • ${s.colorKey}',
      onAdd: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SituationForm(existing: null))),
      onEdit: (s) => Navigator.push(context,
          MaterialPageRoute(builder: (_) => SituationForm(existing: s))),
      onDelete: (s) async {
        if (await confirmDelete(context, s.label.forLang(lang)) &&
            context.mounted) {
          await scope.store.deleteSituation(s.id);
          await scope.reload();
        }
      },
    );
  }
}

class SituationForm extends StatefulWidget {
  final Situation? existing;
  const SituationForm({super.key, required this.existing});
  @override
  State<SituationForm> createState() => _SituationFormState();
}

class _SituationFormState extends State<SituationForm> {
  late final LocalizedControllers _label;
  late final TextEditingController _emoji;
  late final TextEditingController _order;
  late String _colorKey;
  late String? _imagePath;

  @override
  void initState() {
    super.initState();
    final langs = AppScope.read(context).config.languages;
    final e = widget.existing;
    _label = LocalizedControllers(langs, e?.label ?? {});
    _emoji = TextEditingController(text: e?.emoji ?? '');
    _order = TextEditingController(text: (e?.order ?? 0).toString());
    _colorKey = e?.colorKey ?? 'object';
    _imagePath = e?.imagePath;
  }

  @override
  void dispose() {
    _label.dispose();
    _emoji.dispose();
    _order.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AdminFormScaffold(
      title: widget.existing == null ? 'New room' : 'Edit room',
      onSave: () {
        final s = Situation(
          id: widget.existing?.id ?? _newId('sit'),
          label: _label.collect(),
          emoji: _emoji.text.trim(),
          imagePath: _imagePath,
          colorKey: _colorKey,
          order: int.tryParse(_order.text) ?? 0,
        );
        _saveAndClose(context, () => scope.store.upsertSituation(s));
      },
      children: [
        EmojiField(controller: _emoji),
        PhotoField(
          initialPath: _imagePath,
          idHint: widget.existing?.id ?? 'sit',
          onChanged: (p) => _imagePath = p,
        ),
        LocalizedField(
            label: 'Name', languages: scope.config.languages, controllers: _label.map),
        const SizedBox(height: 12),
        _colorDropdown(_colorKey, (v) => setState(() => _colorKey = v!)),
        const SizedBox(height: 12),
        TextField(
          controller: _order,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              labelText: 'Order', border: OutlineInputBorder()),
        ),
      ],
    );
  }
}

// ================================================================ OBJECTS
class ObjectsListScreen extends StatelessWidget {
  const ObjectsListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final lang = scope.caregiverLang;
    final objects = [...scope.config.objects]
      ..sort((a, b) => a.situationId.compareTo(b.situationId));
    return AdminListScaffold<CommunicationObject>(
      title: 'Objects',
      items: objects,
      emojiOf: (o) => o.emoji,
      titleOf: (o) => o.name.forLang(lang),
      subtitleOf: (o) => '${o.situationId} • ${o.actionIds.join(", ")}',
      onAdd: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ObjectForm(existing: null))),
      onEdit: (o) => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ObjectForm(existing: o))),
      onDelete: (o) async {
        if (await confirmDelete(context, o.name.forLang(lang)) &&
            context.mounted) {
          await scope.store.deleteObject(o.id);
          await scope.reload();
        }
      },
    );
  }
}

class ObjectForm extends StatefulWidget {
  final CommunicationObject? existing;
  const ObjectForm({super.key, required this.existing});
  @override
  State<ObjectForm> createState() => _ObjectFormState();
}

class _ObjectFormState extends State<ObjectForm> {
  late final LocalizedControllers _name;
  late final TextEditingController _emoji;
  late final TextEditingController _order;
  late String _situationId;
  late Set<String> _actionIds;
  late Set<String> _destinationIds;
  late bool _supportsQuantity;
  late String? _imagePath;

  @override
  void initState() {
    super.initState();
    final config = AppScope.read(context).config;
    final e = widget.existing;
    _name = LocalizedControllers(config.languages, e?.name ?? {});
    _emoji = TextEditingController(text: e?.emoji ?? '');
    _order = TextEditingController(text: (e?.order ?? 0).toString());
    _imagePath = e?.imagePath;
    _situationId = e?.situationId ??
        (config.situations.isNotEmpty ? config.situations.first.id : '');
    _actionIds = {...?e?.actionIds};
    _destinationIds = {...?e?.destinationIds};
    _supportsQuantity = e?.supportsQuantity ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _emoji.dispose();
    _order.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final config = scope.config;
    return AdminFormScaffold(
      title: widget.existing == null ? 'New object' : 'Edit object',
      onSave: () {
        final o = CommunicationObject(
          id: widget.existing?.id ?? _newId('obj'),
          name: _name.collect(),
          emoji: _emoji.text.trim(),
          imagePath: _imagePath,
          situationId: _situationId,
          actionIds: _actionIds.toList(),
          destinationIds: _destinationIds.toList(),
          supportsQuantity: _supportsQuantity,
          order: int.tryParse(_order.text) ?? 0,
        );
        _saveAndClose(context, () => scope.store.upsertObject(o));
      },
      children: [
        EmojiField(controller: _emoji),
        PhotoField(
          initialPath: _imagePath,
          idHint: widget.existing?.id ?? 'obj',
          onChanged: (p) => _imagePath = p,
        ),
        LocalizedField(
            label: 'Name', languages: config.languages, controllers: _name.map),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _situationId.isEmpty ? null : _situationId,
          isExpanded: true,
          decoration: const InputDecoration(
              labelText: 'Room / situation', border: OutlineInputBorder()),
          items: [
            for (final s in config.orderedSituations)
              DropdownMenuItem(
                  value: s.id,
                  child: Text('${s.emoji}  ${s.label.forLang(config.caregiverLang)}')),
          ],
          onChanged: (v) => setState(() => _situationId = v ?? ''),
        ),
        const SizedBox(height: 16),
        const Text('Which actions make sense?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        for (final a in config.actions)
          CheckboxListTile(
            dense: true,
            value: _actionIds.contains(a.id),
            title: Text('${a.emoji}  ${a.label.forLang(config.caregiverLang)}'),
            onChanged: (v) => setState(() {
              if (v == true) {
                _actionIds.add(a.id);
              } else {
                _actionIds.remove(a.id);
              }
            }),
          ),
        const SizedBox(height: 8),
        SwitchListTile(
          value: _supportsQuantity,
          title: const Text('Ask "how many?"'),
          onChanged: (v) => setState(() => _supportsQuantity = v),
        ),
        const Divider(),
        ExpansionTile(
          title: const Text('Limit destinations (optional)'),
          subtitle: Text(_destinationIds.isEmpty
              ? 'All destinations offered'
              : '${_destinationIds.length} selected'),
          children: [
            for (final l in config.locations)
              CheckboxListTile(
                dense: true,
                value: _destinationIds.contains(l.id),
                title: Text('${l.emoji}  ${l.label.forLang(config.caregiverLang)}'),
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _destinationIds.add(l.id);
                  } else {
                    _destinationIds.remove(l.id);
                  }
                }),
              ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _order,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              labelText: 'Order', border: OutlineInputBorder()),
        ),
      ],
    );
  }
}

// ================================================================ ACTIONS
class ActionsListScreen extends StatelessWidget {
  const ActionsListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final lang = scope.caregiverLang;
    return AdminListScaffold<ActionDef>(
      title: 'Actions',
      items: scope.config.actions,
      emojiOf: (a) => a.emoji,
      titleOf: (a) => a.label.forLang(lang),
      subtitleOf: (a) => a.templates[lang] ?? '',
      onAdd: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const ActionForm(existing: null))),
      onEdit: (a) => Navigator.push(context,
          MaterialPageRoute(builder: (_) => ActionForm(existing: a))),
      onDelete: (a) async {
        if (await confirmDelete(context, a.label.forLang(lang)) &&
            context.mounted) {
          await scope.store.deleteAction(a.id);
          await scope.reload();
        }
      },
    );
  }
}

class ActionForm extends StatefulWidget {
  final ActionDef? existing;
  const ActionForm({super.key, required this.existing});
  @override
  State<ActionForm> createState() => _ActionFormState();
}

class _ActionFormState extends State<ActionForm> {
  late final LocalizedControllers _label;
  late final LocalizedControllers _templates;
  late final TextEditingController _emoji;
  late String _colorKey;
  late bool _requiresObject;
  late bool _requiresDestination;

  @override
  void initState() {
    super.initState();
    final langs = AppScope.read(context).config.languages;
    final e = widget.existing;
    _label = LocalizedControllers(langs, e?.label ?? {});
    _templates = LocalizedControllers(langs, e?.templates ?? {});
    _emoji = TextEditingController(text: e?.emoji ?? '');
    _colorKey = e?.colorKey ?? 'bring';
    _requiresObject = e?.requiresObject ?? true;
    _requiresDestination = e?.requiresDestination ?? false;
  }

  @override
  void dispose() {
    _label.dispose();
    _templates.dispose();
    _emoji.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AdminFormScaffold(
      title: widget.existing == null ? 'New action' : 'Edit action',
      onSave: () {
        final a = ActionDef(
          id: widget.existing?.id ?? _newId('act'),
          label: _label.collect(),
          emoji: _emoji.text.trim(),
          colorKey: _colorKey,
          requiresObject: _requiresObject,
          requiresDestination: _requiresDestination,
          templates: _templates.collect(),
        );
        _saveAndClose(context, () => scope.store.upsertAction(a));
      },
      children: [
        EmojiField(controller: _emoji),
        LocalizedField(
            label: 'Button label',
            languages: scope.config.languages,
            controllers: _label.map),
        const SizedBox(height: 4),
        const Text('Sentence templates — use {object} {destination} {quantity}',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        LocalizedField(
            label: 'Templates',
            languages: scope.config.languages,
            controllers: _templates.map),
        const SizedBox(height: 12),
        _colorDropdown(_colorKey, (v) => setState(() => _colorKey = v!)),
        SwitchListTile(
          value: _requiresObject,
          title: const Text('Needs an object'),
          onChanged: (v) => setState(() => _requiresObject = v),
        ),
        SwitchListTile(
          value: _requiresDestination,
          title: const Text('Asks "where?"'),
          onChanged: (v) => setState(() => _requiresDestination = v),
        ),
      ],
    );
  }
}

// ============================================================== LOCATIONS
class LocationsListScreen extends StatelessWidget {
  const LocationsListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final lang = scope.caregiverLang;
    return AdminListScaffold<LocationDef>(
      title: 'Destinations',
      items: scope.config.locations,
      emojiOf: (l) => l.emoji,
      titleOf: (l) => l.label.forLang(lang),
      subtitleOf: (l) => l.phrase.forLang(lang),
      onAdd: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const LocationForm(existing: null))),
      onEdit: (l) => Navigator.push(context,
          MaterialPageRoute(builder: (_) => LocationForm(existing: l))),
      onDelete: (l) async {
        if (await confirmDelete(context, l.label.forLang(lang)) &&
            context.mounted) {
          await scope.store.deleteLocation(l.id);
          await scope.reload();
        }
      },
    );
  }
}

class LocationForm extends StatefulWidget {
  final LocationDef? existing;
  const LocationForm({super.key, required this.existing});
  @override
  State<LocationForm> createState() => _LocationFormState();
}

class _LocationFormState extends State<LocationForm> {
  late final LocalizedControllers _label;
  late final LocalizedControllers _phrase;
  late final TextEditingController _emoji;
  late final TextEditingController _order;
  late bool _isSelf;

  @override
  void initState() {
    super.initState();
    final langs = AppScope.read(context).config.languages;
    final e = widget.existing;
    _label = LocalizedControllers(langs, e?.label ?? {});
    _phrase = LocalizedControllers(langs, e?.phrase ?? {});
    _emoji = TextEditingController(text: e?.emoji ?? '');
    _order = TextEditingController(text: (e?.order ?? 0).toString());
    _isSelf = e?.isSelf ?? false;
  }

  @override
  void dispose() {
    _label.dispose();
    _phrase.dispose();
    _emoji.dispose();
    _order.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AdminFormScaffold(
      title: widget.existing == null ? 'New destination' : 'Edit destination',
      onSave: () {
        final l = LocationDef(
          id: widget.existing?.id ?? _newId('loc'),
          label: _label.collect(),
          phrase: _phrase.collect(),
          emoji: _emoji.text.trim(),
          isSelf: _isSelf,
          order: int.tryParse(_order.text) ?? 0,
        );
        _saveAndClose(context, () => scope.store.upsertLocation(l));
      },
      children: [
        EmojiField(controller: _emoji),
        LocalizedField(
            label: 'Card label (short)',
            languages: scope.config.languages,
            controllers: _label.map),
        const Text('In-sentence form, e.g. "to me", "in the refrigerator"',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        LocalizedField(
            label: 'Phrase',
            languages: scope.config.languages,
            controllers: _phrase.map),
        SwitchListTile(
          value: _isSelf,
          title: const Text('This means the elderly person ("to me")'),
          onChanged: (v) => setState(() => _isSelf = v),
        ),
        TextField(
          controller: _order,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              labelText: 'Order', border: OutlineInputBorder()),
        ),
      ],
    );
  }
}

// ======================================================= COMMON REQUESTS
class CommonRequestsListScreen extends StatelessWidget {
  const CommonRequestsListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final lang = scope.caregiverLang;
    return AdminListScaffold<CommonRequest>(
      title: 'Common Requests',
      items: scope.config.orderedCommonRequests,
      emojiOf: (c) => c.emoji,
      titleOf: (c) => c.label.forLang(lang),
      subtitleOf: (c) =>
          '${c.intent.actionId} ${c.intent.objectId} → ${c.intent.destinationId ?? ""}',
      onAdd: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const CommonRequestForm(existing: null))),
      onEdit: (c) => Navigator.push(context,
          MaterialPageRoute(builder: (_) => CommonRequestForm(existing: c))),
      onDelete: (c) async {
        if (await confirmDelete(context, c.label.forLang(lang)) &&
            context.mounted) {
          await scope.store.deleteCommonRequest(c.id);
          await scope.reload();
        }
      },
    );
  }
}

class CommonRequestForm extends StatefulWidget {
  final CommonRequest? existing;
  const CommonRequestForm({super.key, required this.existing});
  @override
  State<CommonRequestForm> createState() => _CommonRequestFormState();
}

class _CommonRequestFormState extends State<CommonRequestForm> {
  late final LocalizedControllers _label;
  late final TextEditingController _emoji;
  late final TextEditingController _order;
  SemanticIntent? _intent;

  @override
  void initState() {
    super.initState();
    final langs = AppScope.read(context).config.languages;
    final e = widget.existing;
    _label = LocalizedControllers(langs, e?.label ?? {});
    _emoji = TextEditingController(text: e?.emoji ?? '');
    _order = TextEditingController(text: (e?.order ?? 0).toString());
    _intent = e?.intent;
  }

  @override
  void dispose() {
    _label.dispose();
    _emoji.dispose();
    _order.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AdminFormScaffold(
      title: widget.existing == null ? 'New common request' : 'Edit common request',
      onSave: () {
        final intent = _intent;
        if (intent == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Pick an object and an action first.')));
          return;
        }
        final c = CommonRequest(
          id: widget.existing?.id ?? _newId('cr'),
          label: _label.collect(),
          emoji: _emoji.text.trim(),
          intent: intent,
          order: int.tryParse(_order.text) ?? 0,
        );
        _saveAndClose(context, () => scope.store.upsertCommonRequest(c));
      },
      children: [
        EmojiField(controller: _emoji),
        LocalizedField(
            label: 'Button label',
            languages: scope.config.languages,
            controllers: _label.map),
        const Divider(height: 24),
        const Text('The request', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        IntentPicker(
          config: scope.config,
          initial: _intent,
          onChanged: (i) => _intent = i,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _order,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              labelText: 'Order', border: OutlineInputBorder()),
        ),
      ],
    );
  }
}

// =============================================================== ROUTINES
class RoutinesListScreen extends StatelessWidget {
  const RoutinesListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final lang = scope.caregiverLang;
    return AdminListScaffold<Routine>(
      title: 'Routines',
      items: scope.config.routines,
      emojiOf: (r) => r.emoji,
      titleOf: (r) => r.label.forLang(lang),
      subtitleOf: (r) => '${r.steps.length} steps',
      onAdd: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const RoutineForm(existing: null))),
      onEdit: (r) => Navigator.push(context,
          MaterialPageRoute(builder: (_) => RoutineForm(existing: r))),
      onDelete: (r) async {
        if (await confirmDelete(context, r.label.forLang(lang)) &&
            context.mounted) {
          await scope.store.deleteRoutine(r.id);
          await scope.reload();
        }
      },
    );
  }
}

class RoutineForm extends StatefulWidget {
  final Routine? existing;
  const RoutineForm({super.key, required this.existing});
  @override
  State<RoutineForm> createState() => _RoutineFormState();
}

class _RoutineFormState extends State<RoutineForm> {
  late final LocalizedControllers _label;
  late final TextEditingController _emoji;
  late final TextEditingController _order;
  late List<SemanticIntent> _steps;

  @override
  void initState() {
    super.initState();
    final langs = AppScope.read(context).config.languages;
    final e = widget.existing;
    _label = LocalizedControllers(langs, e?.label ?? {});
    _emoji = TextEditingController(text: e?.emoji ?? '');
    _order = TextEditingController(text: (e?.order ?? 0).toString());
    _steps = [...?e?.steps];
  }

  @override
  void dispose() {
    _label.dispose();
    _emoji.dispose();
    _order.dispose();
    super.dispose();
  }

  Future<void> _addStep() async {
    final config = AppScope.of(context).config;
    SemanticIntent? picked;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add step'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: IntentPicker(
              config: config,
              initial: null,
              onChanged: (i) => picked = i,
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add')),
        ],
      ),
    );
    if (ok == true && picked != null) {
      setState(() => _steps.add(picked!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final renderer = scope.renderer;
    return AdminFormScaffold(
      title: widget.existing == null ? 'New routine' : 'Edit routine',
      onSave: () {
        final r = Routine(
          id: widget.existing?.id ?? _newId('rt'),
          label: _label.collect(),
          emoji: _emoji.text.trim(),
          colorKey: widget.existing?.colorKey ?? 'routine',
          steps: _steps,
          order: int.tryParse(_order.text) ?? 0,
        );
        _saveAndClose(context, () => scope.store.upsertRoutine(r));
      },
      children: [
        EmojiField(controller: _emoji),
        LocalizedField(
            label: 'Name', languages: scope.config.languages, controllers: _label.map),
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Steps', style: TextStyle(fontWeight: FontWeight.bold)),
            TextButton.icon(
                onPressed: _addStep,
                icon: const Icon(Icons.add),
                label: const Text('Add step')),
          ],
        ),
        for (int i = 0; i < _steps.length; i++)
          Card(
            child: ListTile(
              leading: Text('${i + 1}'),
              title: Text(renderer.render(_steps[i]).caregiverText),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_upward),
                    onPressed: i == 0
                        ? null
                        : () => setState(() {
                              final s = _steps.removeAt(i);
                              _steps.insert(i - 1, s);
                            }),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_downward),
                    onPressed: i == _steps.length - 1
                        ? null
                        : () => setState(() {
                              final s = _steps.removeAt(i);
                              _steps.insert(i + 1, s);
                            }),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => setState(() => _steps.removeAt(i)),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        TextField(
          controller: _order,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              labelText: 'Order', border: OutlineInputBorder()),
        ),
      ],
    );
  }
}

// =================================================================== HELP
class HelpListScreen extends StatelessWidget {
  const HelpListScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final lang = scope.caregiverLang;
    final helps = [...scope.config.helpRequests]
      ..sort((a, b) => a.order.compareTo(b.order));
    return AdminListScaffold<HelpRequest>(
      title: 'Help Requests',
      items: helps,
      emojiOf: (h) => h.emoji,
      titleOf: (h) => h.phrase.forLang(lang),
      subtitleOf: (h) => 'order ${h.order}',
      onAdd: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const HelpForm(existing: null))),
      onEdit: (h) => Navigator.push(context,
          MaterialPageRoute(builder: (_) => HelpForm(existing: h))),
      onDelete: (h) async {
        if (await confirmDelete(context, h.phrase.forLang(lang)) &&
            context.mounted) {
          await scope.store.deleteHelpRequest(h.id);
          await scope.reload();
        }
      },
    );
  }
}

class HelpForm extends StatefulWidget {
  final HelpRequest? existing;
  const HelpForm({super.key, required this.existing});
  @override
  State<HelpForm> createState() => _HelpFormState();
}

class _HelpFormState extends State<HelpForm> {
  late final LocalizedControllers _phrase;
  late final TextEditingController _emoji;
  late final TextEditingController _order;

  @override
  void initState() {
    super.initState();
    final langs = AppScope.read(context).config.languages;
    final e = widget.existing;
    _phrase = LocalizedControllers(langs, e?.phrase ?? {});
    _emoji = TextEditingController(text: e?.emoji ?? '');
    _order = TextEditingController(text: (e?.order ?? 0).toString());
  }

  @override
  void dispose() {
    _phrase.dispose();
    _emoji.dispose();
    _order.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    return AdminFormScaffold(
      title: widget.existing == null ? 'New help request' : 'Edit help request',
      onSave: () {
        final h = HelpRequest(
          id: widget.existing?.id ?? _newId('help'),
          phrase: _phrase.collect(),
          emoji: _emoji.text.trim(),
          order: int.tryParse(_order.text) ?? 0,
        );
        _saveAndClose(context, () => scope.store.upsertHelpRequest(h));
      },
      children: [
        EmojiField(controller: _emoji),
        const Text('The exact sentence shown, e.g. "Help me walk."',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
        LocalizedField(
            label: 'Phrase',
            languages: scope.config.languages,
            controllers: _phrase.map),
        TextField(
          controller: _order,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              labelText: 'Order', border: OutlineInputBorder()),
        ),
      ],
    );
  }
}

// ====================================================== HOUSEHOLD SETTINGS
class HouseholdSettingsScreen extends StatefulWidget {
  const HouseholdSettingsScreen({super.key});
  @override
  State<HouseholdSettingsScreen> createState() =>
      _HouseholdSettingsScreenState();
}

class _HouseholdSettingsScreenState extends State<HouseholdSettingsScreen> {
  late final TextEditingController _name;
  late String _elder;
  late String _caregiver;
  late FontSizeChoice _fontSize;

  @override
  void initState() {
    super.initState();
    final c = AppScope.read(context).config;
    _name = TextEditingController(text: c.householdName);
    _elder = c.elderLang;
    _caregiver = c.caregiverLang;
    _fontSize = FontSizeChoice.fromScale(c.fontScale);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final langs = scope.config.languages;
    return AdminFormScaffold(
      title: 'Household',
      onSave: () {
        _saveAndClose(
            context,
            () => scope.store.saveHousehold(
                  name: _name.text.trim().isEmpty ? 'Home' : _name.text.trim(),
                  elderLang: _elder,
                  caregiverLang: _caregiver,
                  fontScale: _fontSize.scale,
                ));
      },
      children: [
        TextField(
          controller: _name,
          decoration: const InputDecoration(
              labelText: 'Household name', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _elder,
          isExpanded: true,
          decoration: const InputDecoration(
              labelText: "Elderly person's language",
              border: OutlineInputBorder()),
          items: [
            for (final l in langs)
              DropdownMenuItem(value: l.code, child: Text(l.label)),
          ],
          onChanged: (v) => setState(() => _elder = v!),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: _caregiver,
          isExpanded: true,
          decoration: const InputDecoration(
              labelText: "Caregiver's language", border: OutlineInputBorder()),
          items: [
            for (final l in langs)
              DropdownMenuItem(value: l.code, child: Text(l.label)),
          ],
          onChanged: (v) => setState(() => _caregiver = v!),
        ),
        const SizedBox(height: 24),
        const Text('Text size',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const Text('How big the words appear for the elderly person.',
            style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        // 4 choices; the preview letter grows so the family can see the effect.
        SegmentedButton<FontSizeChoice>(
          segments: [
            for (final c in FontSizeChoice.values)
              ButtonSegment(
                value: c,
                label: Text('A',
                    style: TextStyle(
                        fontSize: 14 * c.scale, fontWeight: FontWeight.bold)),
                tooltip: c.label,
              ),
          ],
          selected: {_fontSize},
          onSelectionChanged: (s) => setState(() => _fontSize = s.first),
          showSelectedIcon: false,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('Selected: ${_fontSize.label}',
              style: const TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}
