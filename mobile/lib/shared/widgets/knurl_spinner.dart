import 'package:flutter/material.dart';
import '../theme/knurl_theme.dart';

enum KnurlSpinnerSize { sm, lg }

class KnurlSpinner extends StatelessWidget {
  const KnurlSpinner({
    super.key,
    this.size = KnurlSpinnerSize.lg,
  });

  final KnurlSpinnerSize size;

  @override
  Widget build(BuildContext context) {
    final theme = KnurlTheme.of(context);
    final (diameter, strokeWidth) = switch (size) {
      KnurlSpinnerSize.sm => (16.0, 2.0),
      KnurlSpinnerSize.lg => (32.0, 3.0),
    };
    return SizedBox(
      width: diameter,
      height: diameter,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        backgroundColor: theme.border,
        color: theme.accent,
      ),
    );
  }
}
