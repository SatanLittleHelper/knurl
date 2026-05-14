// mobile/test/shared/router/app_router_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knurl/features/auth/presentation/auth_controller.dart';
import 'package:knurl/shared/network/token_storage.dart';
import 'package:knurl/shared/router/app_router.dart';

class _FakeSignedOutController extends StateNotifier<AuthState>
    implements AuthController {
  _FakeSignedOutController()
      : super(const AuthState(
          mode: AuthMode.signIn,
          status: AuthStatus.signedOut,
        ));

  @override
  void setMode(AuthMode mode) {}

  @override
  Future<void> signIn(String email, String password) async {}

  @override
  Future<void> signUp(String email, String password) async {}

  @override
  Future<void> restoreSession(TokenStorage tokenStorage) async {}
}

void main() {
  testWidgets('неавторизованный пользователь редиректится на /auth',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(
          (ref) => _FakeSignedOutController(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.toString(), '/auth');
  });
}
