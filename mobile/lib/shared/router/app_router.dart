// mobile/lib/shared/router/app_router.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:knurl/features/auth/presentation/auth_controller.dart';
import 'package:knurl/features/auth/presentation/auth_screen.dart';
import 'package:knurl/features/home/presentation/home_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomeScreen(),
      ),
    ],
    redirect: (context, state) {
      final isSignedIn = authState.status == AuthStatus.signedIn;
      final isAuthRoute = state.matchedLocation == '/auth';

      if (!isSignedIn && !isAuthRoute) return '/auth';
      if (isSignedIn && isAuthRoute) return '/';
      return null;
    },
  );
});
