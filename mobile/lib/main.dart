import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared/router/app_router.dart';
import 'shared/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: KnurlApp()));
}

class KnurlApp extends ConsumerWidget {
  const KnurlApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Knurl',
      theme: appTheme,
      routerConfig: router,
    );
  }
}
