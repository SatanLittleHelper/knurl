import 'package:flutter/material.dart';

class KnurlTheme extends ThemeExtension<KnurlTheme> {
  const KnurlTheme({
    required this.accent,
    required this.surface,
    required this.background,
    required this.border,
    required this.error,
    required this.radius,
  });

  final Color accent;
  final Color surface;
  final Color background;
  final Color border;
  final Color error;
  final BorderRadius radius;

  static const defaults = KnurlTheme(
    accent: Color(0xFFFF6B35),
    surface: Color(0xFF1E1E1E),
    background: Color(0xFF0F0F0F),
    border: Color(0xFF2A2A2A),
    error: Color(0xFFEF5350),
    radius: BorderRadius.all(Radius.circular(6)),
  );

  static KnurlTheme of(BuildContext context) =>
      Theme.of(context).extension<KnurlTheme>() ?? defaults;

  @override
  KnurlTheme copyWith({
    Color? accent,
    Color? surface,
    Color? background,
    Color? border,
    Color? error,
    BorderRadius? radius,
  }) =>
      KnurlTheme(
        accent: accent ?? this.accent,
        surface: surface ?? this.surface,
        background: background ?? this.background,
        border: border ?? this.border,
        error: error ?? this.error,
        radius: radius ?? this.radius,
      );

  @override
  KnurlTheme lerp(covariant KnurlTheme? other, double t) {
    if (other == null) return this;
    return KnurlTheme(
      accent: Color.lerp(accent, other.accent, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      background: Color.lerp(background, other.background, t)!,
      border: Color.lerp(border, other.border, t)!,
      error: Color.lerp(error, other.error, t)!,
      radius: BorderRadius.lerp(radius, other.radius, t)!,
    );
  }
}
