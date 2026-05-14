import 'package:flutter/material.dart';
import '../theme/knurl_theme.dart';

enum KnurlAvatarSize { sm, md, lg }

class KnurlAvatar extends StatelessWidget {
  const KnurlAvatar({
    super.key,
    required this.initials,
    this.imageUrl,
    this.size = KnurlAvatarSize.md,
  });

  final String initials;
  final String? imageUrl;
  final KnurlAvatarSize size;

  @override
  Widget build(BuildContext context) {
    final theme = KnurlTheme.of(context);
    final (dimension, fontSize) = switch (size) {
      KnurlAvatarSize.sm => (28.0, 11.0),
      KnurlAvatarSize.md => (40.0, 15.0),
      KnurlAvatarSize.lg => (56.0, 20.0),
    };
    final url = imageUrl;
    return ClipRRect(
      borderRadius: theme.radius,
      child: SizedBox(
        width: dimension,
        height: dimension,
        child: url != null
            ? Image.network(url, fit: BoxFit.cover)
            : ColoredBox(
                color: theme.accent,
                child: Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
