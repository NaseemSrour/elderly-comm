import '../models/models.dart';

/// The rendered, human-facing form of a [SemanticIntent] — the ONLY place where
/// language enters the picture. Deterministic. No AI, no network.
class RenderedRequest {
  final String emoji; // big object/situation glyph
  final String? imagePath; // real photo of the object, when configured
  final String? actionEmoji;
  final String? destinationEmoji;
  final String caregiverText;
  final String elderText;
  final bool caregiverRtl;
  final bool elderRtl;

  const RenderedRequest({
    required this.emoji,
    this.imagePath,
    this.actionEmoji,
    this.destinationEmoji,
    required this.caregiverText,
    required this.elderText,
    required this.caregiverRtl,
    required this.elderRtl,
  });

  /// A "show this photo/phrase" request with no structured intent behind it
  /// (used by Help and the camera fallback).
  factory RenderedRequest.plain({
    required String emoji,
    required String caregiverText,
    required String elderText,
    required bool caregiverRtl,
    required bool elderRtl,
  }) =>
      RenderedRequest(
        emoji: emoji,
        caregiverText: caregiverText,
        elderText: elderText,
        caregiverRtl: caregiverRtl,
        elderRtl: elderRtl,
      );
}

class IntentRenderer {
  final HouseholdConfig config;
  const IntentRenderer(this.config);

  RenderedRequest render(SemanticIntent intent) {
    final action = config.action(intent.actionId);
    final object =
        intent.objectId == null ? null : config.object(intent.objectId!);
    final destination = intent.destinationId == null
        ? null
        : config.location(intent.destinationId!);

    final caregiverText =
        _phrase(config.caregiverLang, action, object, destination, intent.quantity);
    final elderText =
        _phrase(config.elderLang, action, object, destination, intent.quantity);

    return RenderedRequest(
      emoji: object?.emoji ?? action?.emoji ?? '❓',
      imagePath: object?.imagePath,
      actionEmoji: action?.emoji,
      destinationEmoji: destination?.emoji,
      caregiverText: caregiverText,
      elderText: elderText,
      caregiverRtl: config.languageFor(config.caregiverLang).rtl,
      elderRtl: config.languageFor(config.elderLang).rtl,
    );
  }

  String _phrase(
    String lang,
    ActionDef? action,
    CommunicationObject? object,
    LocationDef? destination,
    int quantity,
  ) {
    if (action == null) return '';
    final template = action.templates[lang] ?? action.templates.values.first;

    var objectText = object?.name.forLang(lang) ?? '';
    if (quantity > 1 && object != null) {
      objectText = '$quantity ${object.name.forLang(lang)}';
    }

    final destText = destination?.phrase.forLang(lang) ?? '';

    var out = template
        .replaceAll('{object}', objectText)
        .replaceAll('{destination}', destText)
        .replaceAll('{quantity}', quantity.toString());

    return _tidy(out);
  }

  /// Collapse the gaps left by empty tokens and fix spacing before punctuation.
  String _tidy(String s) {
    var out = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    out = out.replaceAll(RegExp(r'\s+([.,!؟?])'), r'$1');
    return out;
  }
}
