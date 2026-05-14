import 'package:flutter/material.dart';
import '../theme/knurl_theme.dart';

enum KnurlButtonVariant { primary, secondary, ghost, destructive }

enum KnurlButtonSize { md, sm }

class KnurlButton extends StatelessWidget {
  const KnurlButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = KnurlButtonVariant.primary,
    this.size = KnurlButtonSize.md,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final KnurlButtonVariant variant;
  final KnurlButtonSize size;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = KnurlTheme.of(context);
    final disabled = onPressed == null && !isLoading;
    final (bg, fg, border) = _colors(theme, disabled, variant);
    final (vPad, hPad, fontSize) = _dims(size);

    return GestureDetector(
      onTap: (disabled || isLoading) ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: theme.radius,
          border: border != null
              ? Border.all(color: border, width: 1.5)
              : null,
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                ),
              )
            : Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: fg,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }

  static (Color, Color, Color?) _colors(KnurlTheme theme, bool disabled, KnurlButtonVariant variant) {
    if (disabled) {
      return (const Color(0xFF1E1E1E), const Color(0xFF444444), null);
    }
    return switch (variant) {
      KnurlButtonVariant.primary     => (theme.accent, Colors.white, null),
      KnurlButtonVariant.secondary   => (theme.surface, theme.accent, theme.border),
      KnurlButtonVariant.ghost       => (Colors.transparent, const Color(0xFFBBBBBB), null),
      KnurlButtonVariant.destructive => (const Color(0xFFC62828), Colors.white, null),
    };
  }

  static (double, double, double) _dims(KnurlButtonSize size) => switch (size) {
    KnurlButtonSize.md => (11.0, 24.0, 14.0),
    KnurlButtonSize.sm => (7.0, 16.0, 12.0),
  };
}
