import 'dart:convert';

import '../../models/models.dart';

/// Converts domain models <-> SQLite rows.
///
/// Localized fields (`LocalizedText`, action templates, intents, id-lists) are
/// stored as JSON in TEXT columns. This keeps translations fully as editable
/// data with a trivial, robust mapping — no fragile normalized join layer for a
/// single-household local database.
class ConfigMappers {
  ConfigMappers._();

  static Map<String, dynamic> _decodeMap(Object? v) {
    if (v == null) return {};
    final decoded = jsonDecode(v as String);
    return (decoded as Map).map((k, val) => MapEntry(k as String, val));
  }

  static LocalizedText _decodeLocalized(Object? v) =>
      _decodeMap(v).map((k, val) => MapEntry(k, val as String));

  static List<String> _decodeStringList(Object? v) {
    if (v == null) return const [];
    return (jsonDecode(v as String) as List).cast<String>();
  }

  // ---- Language ----
  static Map<String, Object?> languageToRow(Language l) => {
        'code': l.code,
        'label': l.label,
        'rtl': l.rtl ? 1 : 0,
      };

  static Language languageFromRow(Map<String, Object?> r) => Language(
        code: r['code'] as String,
        label: r['label'] as String,
        rtl: (r['rtl'] as int) == 1,
      );

  // ---- Situation ----
  static Map<String, Object?> situationToRow(Situation s) => {
        'id': s.id,
        'label_json': jsonEncode(s.label),
        'emoji': s.emoji,
        'image_path': s.imagePath,
        'color_key': s.colorKey,
        'ord': s.order,
      };

  static Situation situationFromRow(Map<String, Object?> r) => Situation(
        id: r['id'] as String,
        label: _decodeLocalized(r['label_json']),
        emoji: r['emoji'] as String,
        imagePath: r['image_path'] as String?,
        colorKey: r['color_key'] as String,
        order: r['ord'] as int,
      );

  // ---- CommunicationObject ----
  static Map<String, Object?> objectToRow(CommunicationObject o) => {
        'id': o.id,
        'name_json': jsonEncode(o.name),
        'emoji': o.emoji,
        'image_path': o.imagePath,
        'situation_id': o.situationId,
        'action_ids_json': jsonEncode(o.actionIds),
        'destination_ids_json': jsonEncode(o.destinationIds),
        'supports_quantity': o.supportsQuantity ? 1 : 0,
        'ord': o.order,
      };

  static CommunicationObject objectFromRow(Map<String, Object?> r) =>
      CommunicationObject(
        id: r['id'] as String,
        name: _decodeLocalized(r['name_json']),
        emoji: r['emoji'] as String,
        imagePath: r['image_path'] as String?,
        situationId: r['situation_id'] as String,
        actionIds: _decodeStringList(r['action_ids_json']),
        destinationIds: _decodeStringList(r['destination_ids_json']),
        supportsQuantity: (r['supports_quantity'] as int) == 1,
        order: r['ord'] as int,
      );

  // ---- ActionDef ----
  static Map<String, Object?> actionToRow(ActionDef a) => {
        'id': a.id,
        'label_json': jsonEncode(a.label),
        'emoji': a.emoji,
        'color_key': a.colorKey,
        'requires_object': a.requiresObject ? 1 : 0,
        'requires_destination': a.requiresDestination ? 1 : 0,
        'templates_json': jsonEncode(a.templates),
      };

  static ActionDef actionFromRow(Map<String, Object?> r) => ActionDef(
        id: r['id'] as String,
        label: _decodeLocalized(r['label_json']),
        emoji: r['emoji'] as String,
        colorKey: r['color_key'] as String,
        requiresObject: (r['requires_object'] as int) == 1,
        requiresDestination: (r['requires_destination'] as int) == 1,
        templates: _decodeLocalized(r['templates_json']),
      );

  // ---- LocationDef ----
  static Map<String, Object?> locationToRow(LocationDef l) => {
        'id': l.id,
        'label_json': jsonEncode(l.label),
        'phrase_json': jsonEncode(l.phrase),
        'emoji': l.emoji,
        'is_self': l.isSelf ? 1 : 0,
        'ord': l.order,
      };

  static LocationDef locationFromRow(Map<String, Object?> r) => LocationDef(
        id: r['id'] as String,
        label: _decodeLocalized(r['label_json']),
        phrase: _decodeLocalized(r['phrase_json']),
        emoji: r['emoji'] as String,
        isSelf: (r['is_self'] as int) == 1,
        order: r['ord'] as int,
      );

  // ---- CommonRequest ----
  static Map<String, Object?> commonRequestToRow(CommonRequest c) => {
        'id': c.id,
        'label_json': jsonEncode(c.label),
        'emoji': c.emoji,
        'intent_json': jsonEncode(c.intent.toJson()),
        'ord': c.order,
      };

  static CommonRequest commonRequestFromRow(Map<String, Object?> r) =>
      CommonRequest(
        id: r['id'] as String,
        label: _decodeLocalized(r['label_json']),
        emoji: r['emoji'] as String,
        intent: SemanticIntent.fromJson(_decodeMap(r['intent_json'])),
        order: r['ord'] as int,
      );

  // ---- Routine ----
  static Map<String, Object?> routineToRow(Routine rt) => {
        'id': rt.id,
        'label_json': jsonEncode(rt.label),
        'emoji': rt.emoji,
        'color_key': rt.colorKey,
        'steps_json': jsonEncode(rt.steps.map((s) => s.toJson()).toList()),
        'ord': rt.order,
      };

  static Routine routineFromRow(Map<String, Object?> r) => Routine(
        id: r['id'] as String,
        label: _decodeLocalized(r['label_json']),
        emoji: r['emoji'] as String,
        colorKey: r['color_key'] as String,
        steps: (jsonDecode(r['steps_json'] as String) as List)
            .map((e) => SemanticIntent.fromJson(
                (e as Map).map((k, v) => MapEntry(k as String, v))))
            .toList(),
        order: r['ord'] as int,
      );

  // ---- HelpRequest ----
  static Map<String, Object?> helpRequestToRow(HelpRequest h) => {
        'id': h.id,
        'phrase_json': jsonEncode(h.phrase),
        'emoji': h.emoji,
        'ord': h.order,
      };

  static HelpRequest helpRequestFromRow(Map<String, Object?> r) => HelpRequest(
        id: r['id'] as String,
        phrase: _decodeLocalized(r['phrase_json']),
        emoji: r['emoji'] as String,
        order: r['ord'] as int,
      );
}
