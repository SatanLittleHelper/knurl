import 'package:flutter/material.dart';

enum KnurlTagStatus { active, rest, warning, done, pr }

class KnurlStatusTag extends StatelessWidget {
  const KnurlStatusTag({super.key, required this.status})
      : _label = null,
        _color = null;

  const KnurlStatusTag.custom({
    super.key,
    required String label,
    required Color color,
  })  : status = null,
        _label = label,
        _color = color;

  final KnurlTagStatus? status;
  final String? _label;
  final Color? _color;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = _resolve();
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('● ', style: TextStyle(color: fg, fontSize: 8)),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, String) _resolve() {
    final s = status;
    if (s == null) return (_color!, _color!, _label!);
    return switch (s) {
      KnurlTagStatus.active  => (const Color(0xFF4CAF50), const Color(0xFF66BB6A), 'Active'),
      KnurlTagStatus.rest    => (const Color(0xFFFF6B35), const Color(0xFFFF6B35), 'Rest'),
      KnurlTagStatus.warning => (const Color(0xFFFFC107), const Color(0xFFFFC107), 'Warning'),
      KnurlTagStatus.done    => (const Color(0xFF646464), const Color(0xFF777777), 'Done'),
      KnurlTagStatus.pr      => (const Color(0xFFAB47BC), const Color(0xFFCE93D8), 'PR'),
    };
  }
}
