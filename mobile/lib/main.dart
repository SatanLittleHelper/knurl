// mobile/lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knurl/features/auth/presentation/auth_controller.dart';
import 'package:knurl/shared/network/token_storage.dart';
import 'package:knurl/shared/router/app_router.dart';
import 'package:knurl/shared/theme/app_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: AppBootstrap(child: KnurlApp()),
    ),
  );
}

class KnurlApp extends ConsumerWidget {
  const KnurlApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Knurl',
      theme: appTheme,
      routerConfig: ref.watch(routerProvider),
    );
  }
}

class AppBootstrap extends ConsumerStatefulWidget {
  const AppBootstrap({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<AppBootstrap> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final tokenStorage = ref.read(tokenStorageProvider);
      ref.read(authControllerProvider.notifier).restoreSession(tokenStorage);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
