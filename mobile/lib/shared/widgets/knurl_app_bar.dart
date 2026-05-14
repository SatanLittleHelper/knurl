import 'package:flutter/material.dart';

class KnurlAppBar extends StatelessWidget implements PreferredSizeWidget {
  const KnurlAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Knurl'),
    );
  }
}
