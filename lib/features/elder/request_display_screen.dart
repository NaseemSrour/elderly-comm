import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/design/design.dart';
import '../../core/models/models.dart';
import '../../core/services/intent_renderer.dart';
import '../../core/services/tts_service.dart';
import 'widgets.dart';

/// The final, full-screen communication view. Big enough to read across a room.
/// The elderly person turns the tablet toward the caregiver.
///
/// Layout (top → bottom): caregiver language, big glyph, elder language, PLAY.
/// Two languages at once so the caregiver need not read the elder's language.
class RequestDisplayScreen extends StatefulWidget {
  final RenderedRequest request;

  /// If present, this request is remembered for the "Repeat" shortcut.
  final SemanticIntent? intent;

  const RequestDisplayScreen({
    super.key,
    required this.request,
    this.intent,
  });

  @override
  State<RequestDisplayScreen> createState() => _RequestDisplayScreenState();
}

class _RequestDisplayScreenState extends State<RequestDisplayScreen> {
  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();
    if (widget.intent != null) {
      // Remember for Repeat. Done post-frame to avoid notifying during build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppScope.of(context).lastIntent.value = widget.intent;
      });
    }
  }

  Future<void> _play() async {
    // Speaks the caregiver-language sentence aloud. Optional & never required —
    // if no voice is available we tell the user the text is still shown.
    HapticFeedback.selectionClick();
    final lang = AppScope.of(context).caregiverLang;
    final ok = await TtsService.instance.speak(widget.request.caregiverText, lang);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No voice available — please show the screen.',
              style: TextStyle(fontSize: 20)),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  void dispose() {
    TtsService.instance.stop();
    super.dispose();
  }

  Widget _bigVisual(RenderedRequest r) {
    final path = r.imagePath;
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Image.file(
          File(path),
          width: 340,
          height: 340,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Text(r.emoji,
              style: const TextStyle(fontSize: AppSizes.finalEmoji)),
        ),
      );
    }
    return Text(r.emoji, style: const TextStyle(fontSize: AppSizes.finalEmoji));
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    return ElderScaffold(
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, cc) => Center(
                // Scale-to-fit instead of scroll: the request is always fully
                // visible, and the elder never needs to scroll. Width is fixed
                // to the viewport so the sentences still wrap naturally.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: cc.maxWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Caregiver language — primary, on top.
                        Text(
                          r.caregiverText,
                          textAlign: TextAlign.center,
                          textDirection: r.caregiverRtl
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          style: const TextStyle(
                            fontSize: AppSizes.finalPrimary,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Big redundant visual: real photo if set, else glyph.
                        _bigVisual(r),
                        if (r.actionEmoji != null || r.destinationEmoji != null)
                          Text(
                            [
                              if (r.actionEmoji != null) r.actionEmoji!,
                              if (r.destinationEmoji != null) r.destinationEmoji!,
                            ].join('   '),
                            style: const TextStyle(fontSize: 56),
                          ),
                        const SizedBox(height: 24),
                        // Elder language — reassurance for the person asking.
                        Text(
                          r.elderText,
                          textAlign: TextAlign.center,
                          textDirection: r.elderRtl
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          style: const TextStyle(
                            fontSize: AppSizes.finalSecondary,
                            fontWeight: FontWeight.w700,
                            color: AppColors.inkSoft,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.gap),
          GestureDetector(
            onTap: _play,
            child: Container(
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.take,
                borderRadius: BorderRadius.circular(AppSizes.cardRadius),
              ),
              child: const Center(
                child: Text('🔊  Play',
                    style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
