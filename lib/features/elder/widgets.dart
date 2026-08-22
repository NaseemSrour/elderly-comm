import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:io';

import '../../core/data/config_repository.dart';
import '../../core/design/design.dart';
import '../../core/localization/ui_strings.dart';
import '../../core/models/models.dart';
import '../../core/services/intent_renderer.dart';

/// Provides the household config + renderer to the whole widget tree, plus the
/// writable [store] (for Admin Mode), a [reload] hook to refresh Elder Mode
/// after edits, and a memory of the last request so "Repeat" works.
class AppScope extends InheritedWidget {
  final HouseholdConfig config;
  final IntentRenderer renderer;
  final ConfigStore store;

  /// Re-reads the config from storage and rebuilds the app.
  final Future<void> Function() reload;

  /// Persisted across reloads by the stateful owner (see ElderApp).
  final ValueNotifier<SemanticIntent?> lastIntent;

  AppScope({
    super.key,
    required this.config,
    required this.store,
    required this.reload,
    required this.lastIntent,
    required super.child,
  }) : renderer = IntentRenderer(config);

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in widget tree');
    return scope!;
  }

  /// Reads the scope WITHOUT registering a dependency. Safe to call from
  /// [State.initState] (unlike [of], which must run in build/didChangeDependencies).
  static AppScope read(BuildContext context) {
    final element =
        context.getElementForInheritedWidgetOfExactType<AppScope>();
    assert(element != null, 'AppScope not found in widget tree');
    return element!.widget as AppScope;
  }

  String get elderLang => config.elderLang;
  String get caregiverLang => config.caregiverLang;
  bool get elderRtl => config.languageFor(config.elderLang).rtl;

  @override
  bool updateShouldNotify(AppScope oldWidget) => oldWidget.config != config;
}

/// A large, forgiving, tappable card. The picture (photo or emoji) fills its
/// own zone as large as the card allows; the label sits in a separate zone
/// below so the two never overlap. Colour is always paired with the picture and
/// text — never the only signal.
class BigCard extends StatefulWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool rtl;

  /// Optional real photograph. When present (and the file exists) it replaces
  /// the emoji — "that's my bowl" beats "an icon that means bowl".
  final String? imagePath;

  const BigCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
    this.rtl = false,
    this.imagePath,
  });

  @override
  State<BigCard> createState() => _BigCardState();
}

class _BigCardState extends State<BigCard> {
  bool _down = false;

  void _set(bool v) => setState(() => _down = v);

  /// The picture, sized to fill whatever space the label leaves.
  Widget _visual() {
    final path = widget.imagePath;
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          File(path),
          width: double.infinity,
          height: double.infinity,
          fit: BoxFit.cover,
          // If the file goes missing, fall back to the emoji rather than error.
          errorBuilder: (_, _, _) => _emoji(),
        ),
      );
    }
    return _emoji();
  }

  // A big base size that FittedBox scales DOWN to fill the available zone, so
  // emojis grow as large as the card permits.
  Widget _emoji() => FittedBox(
        fit: BoxFit.contain,
        child: Text(widget.emoji, style: const TextStyle(fontSize: 240)),
      );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _set(true),
      onTapCancel: () => _set(false),
      onTapUp: (_) => _set(false),
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSizes.minTarget),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
            border: Border.all(color: widget.color, width: 4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _down ? 0.04 : 0.10),
                blurRadius: _down ? 4 : 12,
                offset: Offset(0, _down ? 1 : 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Picture zone — takes all remaining space.
              Expanded(child: Center(child: _visual())),
              const SizedBox(height: 10),
              // Text zone — its own space, so it never overlaps the picture.
              Text(
                widget.label,
                textAlign: TextAlign.center,
                textDirection:
                    widget.rtl ? TextDirection.rtl : TextDirection.ltr,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: AppSizes.cardLabel,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Consistent frame for every elder screen:
///  - optional question header at the top,
///  - body inset by an inert [AppSizes.edgeGuard] so edge grips don't mis-tap,
///  - Back always bottom-left, Home always bottom-right (spatial consistency).
class ElderScaffold extends StatelessWidget {
  final String? question;
  final bool questionRtl;
  final Widget body;
  final bool showBack;
  final bool showHome;

  const ElderScaffold({
    super.key,
    this.question,
    this.questionRtl = false,
    required this.body,
    this.showBack = true,
    this.showHome = true,
  });

  @override
  Widget build(BuildContext context) {
    final ui = UiStrings.of(AppScope.of(context).elderLang);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.edgeGuard),
          child: Column(
            children: [
              if (question != null) ...[
                Text(
                  question!,
                  textAlign: TextAlign.center,
                  textDirection:
                      questionRtl ? TextDirection.rtl : TextDirection.ltr,
                  style: const TextStyle(
                    fontSize: AppSizes.title,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSizes.gap),
              ],
              Expanded(child: body),
              const SizedBox(height: AppSizes.gap),
              Row(
                children: [
                  if (showBack)
                    Expanded(
                      child: NavButton(
                        emoji: '⬅️',
                        label: ui.back,
                        color: AppColors.inkSoft,
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                    ),
                  if (showBack && showHome) const SizedBox(width: AppSizes.gap),
                  if (showHome)
                    Expanded(
                      child: NavButton(
                        emoji: '🏠',
                        label: ui.home,
                        color: AppColors.bring,
                        onTap: () =>
                            Navigator.of(context).popUntil((r) => r.isFirst),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A wide, unmistakable navigation button.
class NavButton extends StatelessWidget {
  final String emoji;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const NavButton({
    super.key,
    required this.emoji,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        height: 104,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 46)),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                fontSize: AppSizes.navLabel,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A responsive, non-scroll-dependent grid of [BigCard]s. Chooses a column
/// count from the available width so cards stay large on any tablet size.
class CardGrid extends StatelessWidget {
  final List<Widget> children;
  final double minCardWidth;

  const CardGrid({
    super.key,
    required this.children,
    this.minCardWidth = 300,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        // Fewer, bigger cards (max 4 across) so pictures and text stay large.
        final cols = (c.maxWidth / minCardWidth).floor().clamp(2, 4);
        return GridView.count(
          crossAxisCount: cols,
          mainAxisSpacing: AppSizes.gap,
          crossAxisSpacing: AppSizes.gap,
          childAspectRatio: 0.95,
          physics: const BouncingScrollPhysics(),
          children: children,
        );
      },
    );
  }
}
