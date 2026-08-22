import 'package:flutter/material.dart';

/// The design system: warm, calm, high-contrast, large. Every value here exists
/// to reduce cognitive load and support poor vision / low dexterity.
///
/// Rules encoded here:
///  - Big touch targets (see [AppSizes.minTarget]).
///  - Color NEVER carries meaning alone — cards always pair color with emoji +
///    text + spatial position.
///  - Generous edge guards so fingers gripping the tablet don't mis-tap.
class AppColors {
  AppColors._();

  static const background = Color(0xFFFDF6EC); // warm cream
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1F1B16); // near-black, high contrast
  static const inkSoft = Color(0xFF5C544A);
  static const border = Color(0xFFE3D9C8);

  // Semantic action palette (paired with icons/text, never used alone).
  static const bring = Color(0xFF2E7D32); // green  = bring / positive
  static const take = Color(0xFF1565C0); // blue   = take
  static const put = Color(0xFFF9A825); // amber  = put somewhere
  static const open = Color(0xFF00838F); // teal   = open
  static const close = Color(0xFFC62828); // red    = close / stop
  static const wash = Color(0xFF6A1B9A); // purple = wash
  static const routine = Color(0xFF8E24AA); // purple = routines
  static const help = Color(0xFFD84315); // deep orange = help
  static const object = Color(0xFF37474F); // slate  = neutral objects
  static const self = Color(0xFF00695C); // "to me"

  static const Map<String, Color> _byKey = {
    'bring': bring,
    'take': take,
    'put': put,
    'open': open,
    'close': close,
    'wash': wash,
    'routine': routine,
    'help': help,
    'object': object,
    'self': self,
  };

  static Color byKey(String key) => _byKey[key] ?? object;

  /// Selectable palette keys (for Admin Mode colour pickers).
  static List<String> get paletteKeys => _byKey.keys.toList();
}

class AppSizes {
  AppSizes._();

  /// Minimum size for anything tappable. Deliberately huge.
  static const double minTarget = 140;

  static const double cardRadius = 24;
  static const double gap = 20;

  /// Inert margin around the interactive area so edge grips don't register.
  static const double edgeGuard = 28;

  // Type scale — very large by default (tuned with a low-vision elder in mind).
  static const double title = 56;
  static const double cardLabel = 40;
  static const double navLabel = 32;

  // Final request screen — readable across a room.
  static const double finalEmoji = 210;
  static const double finalPrimary = 92;
  static const double finalSecondary = 66;
}

/// The four selectable font sizes (Admin → Household → Text size). Each maps to
/// a multiplier applied on top of the already-large defaults.
enum FontSizeChoice {
  normal('Normal', 1.0),
  large('Large', 1.2),
  huge('Huge', 1.4),
  giant('Giant', 1.6);

  const FontSizeChoice(this.label, this.scale);
  final String label;
  final double scale;

  /// Nearest choice for a stored [scale] (so the picker shows the right option).
  static FontSizeChoice fromScale(double scale) {
    var best = FontSizeChoice.normal;
    var bestDelta = double.infinity;
    for (final c in FontSizeChoice.values) {
      final d = (c.scale - scale).abs();
      if (d < bestDelta) {
        bestDelta = d;
        best = c;
      }
    }
    return best;
  }
}

class AppTheme {
  static ThemeData build() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.bring,
        surface: AppColors.surface,
        brightness: Brightness.light,
      ),
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      splashFactory: InkRipple.splashFactory,
    );
  }
}
