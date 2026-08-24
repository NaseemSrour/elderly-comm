import '../models/models.dart';

/// Serializes a whole [HouseholdConfig] to/from a plain JSON map and back.
///
/// This is the pure, IO-free half of backup: it knows nothing about files or
/// photos. Photo bytes are embedded separately by `BackupService`, which
/// replaces each stored [imagePath] with an `embedded:<token>` reference before
/// calling [configToJson] and resolves those tokens back to real paths before
/// calling [configFromJson]. Keeping this layer pure makes round-trips trivially
/// testable and keeps the export file human-inspectable (clean nested JSON, not
/// double-encoded row strings).
class ConfigCodec {
  ConfigCodec._();

  /// Bumped only if the JSON shape changes incompatibly. Import refuses a newer
  /// version than it understands.
  static const int formatVersion = 1;
  static const String formatTag = 'home_talk_backup';

  // --------------------------------------------------------------- config ->
  static Map<String, dynamic> configToJson(HouseholdConfig c) => {
        'householdName': c.householdName,
        'elderLang': c.elderLang,
        'caregiverLang': c.caregiverLang,
        'fontScale': c.fontScale,
        'languages': c.languages.map(_languageToJson).toList(),
        'situations': c.situations.map(_situationToJson).toList(),
        'objects': c.objects.map(_objectToJson).toList(),
        'actions': c.actions.map(_actionToJson).toList(),
        'locations': c.locations.map(_locationToJson).toList(),
        'commonRequests': c.commonRequests.map(_commonRequestToJson).toList(),
        'routines': c.routines.map(_routineToJson).toList(),
        'helpRequests': c.helpRequests.map(_helpRequestToJson).toList(),
      };

  // --------------------------------------------------------------- -> config
  static HouseholdConfig configFromJson(Map<String, dynamic> j) =>
      HouseholdConfig(
        householdName: j['householdName'] as String? ?? 'Home',
        elderLang: j['elderLang'] as String? ?? 'en',
        caregiverLang: j['caregiverLang'] as String? ?? 'en',
        fontScale: (j['fontScale'] as num?)?.toDouble() ?? 1.0,
        languages: _list(j['languages'], _languageFromJson),
        situations: _list(j['situations'], _situationFromJson),
        objects: _list(j['objects'], _objectFromJson),
        actions: _list(j['actions'], _actionFromJson),
        locations: _list(j['locations'], _locationFromJson),
        commonRequests: _list(j['commonRequests'], _commonRequestFromJson),
        routines: _list(j['routines'], _routineFromJson),
        helpRequests: _list(j['helpRequests'], _helpRequestFromJson),
      );

  // ------------------------------------------------------------- helpers ----
  static List<T> _list<T>(Object? raw, T Function(Map<String, dynamic>) f) =>
      ((raw as List?) ?? const [])
          .map((e) => f(_asMap(e)))
          .toList(growable: false);

  static Map<String, dynamic> _asMap(Object? v) =>
      (v as Map).map((k, val) => MapEntry(k as String, val));

  static LocalizedText _localized(Object? v) =>
      _asMap(v).map((k, val) => MapEntry(k, val as String));

  static List<String> _stringList(Object? v) =>
      ((v as List?) ?? const []).cast<String>();

  // ---- Language ----
  static Map<String, dynamic> _languageToJson(Language l) =>
      {'code': l.code, 'label': l.label, 'rtl': l.rtl};

  static Language _languageFromJson(Map<String, dynamic> j) => Language(
        code: j['code'] as String,
        label: j['label'] as String,
        rtl: j['rtl'] as bool? ?? false,
      );

  // ---- Situation ----
  static Map<String, dynamic> _situationToJson(Situation s) => {
        'id': s.id,
        'label': s.label,
        'emoji': s.emoji,
        'imagePath': s.imagePath,
        'colorKey': s.colorKey,
        'order': s.order,
      };

  static Situation _situationFromJson(Map<String, dynamic> j) => Situation(
        id: j['id'] as String,
        label: _localized(j['label']),
        emoji: j['emoji'] as String,
        imagePath: j['imagePath'] as String?,
        colorKey: j['colorKey'] as String? ?? 'object',
        order: j['order'] as int? ?? 0,
      );

  // ---- CommunicationObject ----
  static Map<String, dynamic> _objectToJson(CommunicationObject o) => {
        'id': o.id,
        'name': o.name,
        'emoji': o.emoji,
        'imagePath': o.imagePath,
        'situationId': o.situationId,
        'actionIds': o.actionIds,
        'destinationIds': o.destinationIds,
        'supportsQuantity': o.supportsQuantity,
        'order': o.order,
      };

  static CommunicationObject _objectFromJson(Map<String, dynamic> j) =>
      CommunicationObject(
        id: j['id'] as String,
        name: _localized(j['name']),
        emoji: j['emoji'] as String,
        imagePath: j['imagePath'] as String?,
        situationId: j['situationId'] as String,
        actionIds: _stringList(j['actionIds']),
        destinationIds: _stringList(j['destinationIds']),
        supportsQuantity: j['supportsQuantity'] as bool? ?? false,
        order: j['order'] as int? ?? 0,
      );

  // ---- ActionDef ----
  static Map<String, dynamic> _actionToJson(ActionDef a) => {
        'id': a.id,
        'label': a.label,
        'emoji': a.emoji,
        'colorKey': a.colorKey,
        'requiresObject': a.requiresObject,
        'requiresDestination': a.requiresDestination,
        'templates': a.templates,
      };

  static ActionDef _actionFromJson(Map<String, dynamic> j) => ActionDef(
        id: j['id'] as String,
        label: _localized(j['label']),
        emoji: j['emoji'] as String,
        colorKey: j['colorKey'] as String? ?? 'bring',
        requiresObject: j['requiresObject'] as bool? ?? true,
        requiresDestination: j['requiresDestination'] as bool? ?? false,
        templates: _localized(j['templates']),
      );

  // ---- LocationDef ----
  static Map<String, dynamic> _locationToJson(LocationDef l) => {
        'id': l.id,
        'label': l.label,
        'phrase': l.phrase,
        'emoji': l.emoji,
        'isSelf': l.isSelf,
        'order': l.order,
      };

  static LocationDef _locationFromJson(Map<String, dynamic> j) => LocationDef(
        id: j['id'] as String,
        label: _localized(j['label']),
        phrase: _localized(j['phrase']),
        emoji: j['emoji'] as String,
        isSelf: j['isSelf'] as bool? ?? false,
        order: j['order'] as int? ?? 0,
      );

  // ---- CommonRequest ----
  static Map<String, dynamic> _commonRequestToJson(CommonRequest c) => {
        'id': c.id,
        'label': c.label,
        'emoji': c.emoji,
        'intent': c.intent.toJson(),
        'order': c.order,
      };

  static CommonRequest _commonRequestFromJson(Map<String, dynamic> j) =>
      CommonRequest(
        id: j['id'] as String,
        label: _localized(j['label']),
        emoji: j['emoji'] as String,
        intent: SemanticIntent.fromJson(_asMap(j['intent'])),
        order: j['order'] as int? ?? 0,
      );

  // ---- Routine ----
  static Map<String, dynamic> _routineToJson(Routine r) => {
        'id': r.id,
        'label': r.label,
        'emoji': r.emoji,
        'colorKey': r.colorKey,
        'steps': r.steps.map((s) => s.toJson()).toList(),
        'order': r.order,
      };

  static Routine _routineFromJson(Map<String, dynamic> j) => Routine(
        id: j['id'] as String,
        label: _localized(j['label']),
        emoji: j['emoji'] as String,
        colorKey: j['colorKey'] as String? ?? 'routine',
        steps: ((j['steps'] as List?) ?? const [])
            .map((e) => SemanticIntent.fromJson(_asMap(e)))
            .toList(),
        order: j['order'] as int? ?? 0,
      );

  // ---- HelpRequest ----
  static Map<String, dynamic> _helpRequestToJson(HelpRequest h) => {
        'id': h.id,
        'phrase': h.phrase,
        'emoji': h.emoji,
        'order': h.order,
      };

  static HelpRequest _helpRequestFromJson(Map<String, dynamic> j) =>
      HelpRequest(
        id: j['id'] as String,
        phrase: _localized(j['phrase']),
        emoji: j['emoji'] as String,
        order: j['order'] as int? ?? 0,
      );
}
