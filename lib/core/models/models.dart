/// Domain models for the Elderly Visual Communication app.
///
/// Everything here is language-independent where it matters: the user's intent
/// is captured as a [SemanticIntent] and only turned into words at the final
/// presentation stage (see core/services/intent_renderer.dart).
///
/// Content (situations, objects, actions...) is DATA. It is never hardcoded
/// into widgets. In Phase 1 it comes from an in-memory sample config; in
/// Phase 2 the exact same models will be loaded from SQLite.
library;

/// A localized string: language code -> text.
typedef LocalizedText = Map<String, String>;

extension LocalizedTextX on LocalizedText {
  /// Returns the text for [lang], falling back to any available value so the
  /// UI never shows an empty label.
  String forLang(String lang) {
    final v = this[lang];
    if (v != null && v.isNotEmpty) return v;
    if (isNotEmpty) return values.first;
    return '';
  }
}

/// A language the household uses. [rtl] drives text direction so Arabic/Hebrew
/// render correctly without changing anything else.
class Language {
  final String code;
  final String label;
  final bool rtl;
  const Language({required this.code, required this.label, this.rtl = false});
}

/// A context/room the elderly person navigates into. NOT an abstract category.
class Situation {
  final String id;
  final LocalizedText label;
  final String emoji;
  final String? imagePath;
  final String colorKey; // key into the design palette
  final int order;

  const Situation({
    required this.id,
    required this.label,
    required this.emoji,
    this.imagePath,
    this.colorKey = 'object',
    this.order = 0,
  });
}

/// A physical household object OR a semantic destination target. For objects,
/// [name] holds each language's word; the caregiver-language name may carry an
/// article ("a bowl", "the window") so rendered phrases read naturally, while
/// the elder-language name stays plain ("جاط") for the recognition card.
class CommunicationObject {
  final String id;
  final LocalizedText name;
  final String emoji;
  final String? imagePath;
  final String situationId;

  /// Which actions make sense for this object (context-aware — no nonsense).
  final List<String> actionIds;

  /// Optional restriction of which destinations apply. Empty => use action's.
  final List<String> destinationIds;

  final bool supportsQuantity;
  final int order;

  const CommunicationObject({
    required this.id,
    required this.name,
    required this.emoji,
    this.imagePath,
    required this.situationId,
    required this.actionIds,
    this.destinationIds = const [],
    this.supportsQuantity = false,
    this.order = 0,
  });
}

/// A verb the user can apply to an object. Grammar lives here as per-language
/// [templates] with `{object}`, `{destination}`, `{quantity}` tokens — this is
/// deterministic string assembly, not translation of free-form sentences.
class ActionDef {
  final String id;
  final LocalizedText label;
  final String emoji;
  final String colorKey;

  final bool requiresObject;
  final bool requiresDestination;

  /// language code -> template. Missing tokens collapse cleanly.
  final Map<String, String> templates;

  const ActionDef({
    required this.id,
    required this.label,
    required this.emoji,
    this.colorKey = 'bring',
    this.requiresObject = true,
    this.requiresDestination = false,
    required this.templates,
  });
}

/// A destination: a physical place or a semantic target like "to me".
/// [phrase] is the in-sentence form ("me", "in the refrigerator"); [label] is
/// the short card form ("Me"). [isSelf] marks the elderly person themself.
class LocationDef {
  final String id;
  final LocalizedText label;
  final LocalizedText phrase;
  final String emoji;
  final bool isSelf;
  final int order;

  const LocationDef({
    required this.id,
    required this.label,
    required this.phrase,
    required this.emoji,
    this.isSelf = false,
    this.order = 0,
  });
}

/// The heart of the system: a language-independent, serializable request.
class SemanticIntent {
  final String? objectId;
  final String actionId;
  final String? destinationId;
  final int quantity;
  final Map<String, dynamic>? parameters;

  const SemanticIntent({
    this.objectId,
    required this.actionId,
    this.destinationId,
    this.quantity = 1,
    this.parameters,
  });

  SemanticIntent copyWith({
    String? objectId,
    String? actionId,
    String? destinationId,
    int? quantity,
  }) {
    return SemanticIntent(
      objectId: objectId ?? this.objectId,
      actionId: actionId ?? this.actionId,
      destinationId: destinationId ?? this.destinationId,
      quantity: quantity ?? this.quantity,
      parameters: parameters,
    );
  }

  Map<String, dynamic> toJson() => {
        'objectId': objectId,
        'actionId': actionId,
        'destinationId': destinationId,
        'quantity': quantity,
        if (parameters != null) 'parameters': parameters,
      };

  factory SemanticIntent.fromJson(Map<String, dynamic> j) => SemanticIntent(
        objectId: j['objectId'] as String?,
        actionId: j['actionId'] as String,
        destinationId: j['destinationId'] as String?,
        quantity: (j['quantity'] as num?)?.toInt() ?? 1,
        parameters: j['parameters'] as Map<String, dynamic>?,
      );
}

/// A one-tap shortcut on the home screen that bypasses the multi-step flow.
class CommonRequest {
  final String id;
  final LocalizedText label;
  final String emoji;
  final SemanticIntent intent;
  final int order;

  const CommonRequest({
    required this.id,
    required this.label,
    required this.emoji,
    required this.intent,
    this.order = 0,
  });
}

/// An ordered collection of intents shown one at a time (Morning, Night...).
class Routine {
  final String id;
  final LocalizedText label;
  final String emoji;
  final String colorKey;
  final List<SemanticIntent> steps;
  final int order;

  const Routine({
    required this.id,
    required this.label,
    required this.emoji,
    this.colorKey = 'routine',
    required this.steps,
    this.order = 0,
  });
}

/// A specific, pre-phrased request for assistance. Help is pre-worded (not an
/// object+action) so it renders directly and unambiguously.
class HelpRequest {
  final String id;
  final LocalizedText phrase; // caregiver + elder wording, shown directly
  final String emoji;
  final int order;

  const HelpRequest({
    required this.id,
    required this.phrase,
    required this.emoji,
    this.order = 0,
  });
}

/// The full personalized household configuration. This is the single source of
/// truth the whole UI reads from.
class HouseholdConfig {
  final String householdName;
  final String elderLang;
  final String caregiverLang;
  final List<Language> languages;

  /// Global text-size multiplier for Elder Mode (family-configurable, §26
  /// Appearance). 1.0 = the already-large default; larger = bigger everywhere.
  final double fontScale;

  final List<Situation> situations;
  final List<CommunicationObject> objects;
  final List<ActionDef> actions;
  final List<LocationDef> locations;
  final List<CommonRequest> commonRequests;
  final List<Routine> routines;
  final List<HelpRequest> helpRequests;

  const HouseholdConfig({
    required this.householdName,
    required this.elderLang,
    required this.caregiverLang,
    required this.languages,
    this.fontScale = 1.0,
    required this.situations,
    required this.objects,
    required this.actions,
    required this.locations,
    required this.commonRequests,
    required this.routines,
    required this.helpRequests,
  });

  Language languageFor(String code) => languages.firstWhere(
        (l) => l.code == code,
        orElse: () => Language(code: code, label: code),
      );

  // ---- Lookups (data-driven; no per-screen special cases) ----

  Situation? situation(String id) =>
      _firstOrNull(situations.where((s) => s.id == id));

  CommunicationObject? object(String id) =>
      _firstOrNull(objects.where((o) => o.id == id));

  ActionDef? action(String id) =>
      _firstOrNull(actions.where((a) => a.id == id));

  LocationDef? location(String id) =>
      _firstOrNull(locations.where((l) => l.id == id));

  List<CommunicationObject> objectsIn(String situationId) {
    final list =
        objects.where((o) => o.situationId == situationId).toList();
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  List<ActionDef> actionsFor(CommunicationObject obj) {
    return obj.actionIds
        .map(action)
        .whereType<ActionDef>()
        .toList();
  }

  List<LocationDef> destinationsFor(CommunicationObject obj, ActionDef act) {
    final ids = obj.destinationIds.isNotEmpty
        ? obj.destinationIds
        : locations.map((l) => l.id).toList();
    final list = ids.map(location).whereType<LocationDef>().toList();
    list.sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  List<Situation> get orderedSituations {
    final list = [...situations]..sort((a, b) => a.order.compareTo(b.order));
    return list;
  }

  List<CommonRequest> get orderedCommonRequests {
    final list = [...commonRequests]..sort((a, b) => a.order.compareTo(b.order));
    return list;
  }
}

T? _firstOrNull<T>(Iterable<T> it) => it.isEmpty ? null : it.first;
