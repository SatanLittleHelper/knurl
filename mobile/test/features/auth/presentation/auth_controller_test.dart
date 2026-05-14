import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knurl/features/auth/data/auth_repository.dart';
import 'package:knurl/features/auth/presentation/auth_controller.dart';
import 'package:knurl/shared/network/api_exception.dart';
import 'package:knurl/shared/network/token_storage.dart';

class FakeTokenStorage implements TokenStorage {
  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String token) async {}

  @override
  Future<void> delete() async {}
}

class FakeDio implements Dio {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository() : super(FakeDio(), FakeTokenStorage());

  Completer<void>? pendingRequest;
  Object? signInError;
  Object? signUpError;
  int signInCalls = 0;
  int signUpCalls = 0;

  @override
  Future<void> signIn(String email, String password) async {
    signInCalls += 1;
    if (signInError != null) {
      throw signInError!;
    }

    final completer = pendingRequest;
    if (completer != null) {
      await completer.future;
    }
  }

  @override
  Future<void> signUp(String email, String password) async {
    signUpCalls += 1;
    if (signUpError != null) {
      throw signUpError!;
    }

    final completer = pendingRequest;
    if (completer != null) {
      await completer.future;
    }
  }
}

void main() {
  group('AuthController', () {
    test('signIn success -> signedIn', () async {
      final repository = FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      await controller.signIn('user@example.com', 'secret');

      final state = container.read(authControllerProvider);
      expect(repository.signInCalls, 1);
      expect(state.status, AuthStatus.signedIn);
      expect(state.errorMessage, isNull);
    });

    test('signUp success -> signedIn', () async {
      final repository = FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      await controller.signUp('new@example.com', 'secret');

      final state = container.read(authControllerProvider);
      expect(repository.signUpCalls, 1);
      expect(state.status, AuthStatus.signedIn);
      expect(state.errorMessage, isNull);
    });

    test('repository error -> error state with mapped message', () async {
      final repository = FakeAuthRepository()
        ..signInError = const ApiException(
          code: ApiErrorCode.unauthorized,
          message: 'Требуется авторизация',
          statusCode: 401,
        );
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      await controller.signIn('user@example.com', 'wrong-password');

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.error);
      expect(state.errorMessage, 'Неверный email или пароль');
    });

    test('setMode sets mode and clears error', () async {
      final repository = FakeAuthRepository()
        ..signInError = const ApiException(
          code: ApiErrorCode.unauthorized,
          message: 'Требуется авторизация',
          statusCode: 401,
        );
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      await controller.signIn('user@example.com', 'wrong-password');
      controller.setMode(AuthMode.signUp);

      final state = container.read(authControllerProvider);
      expect(state.mode, AuthMode.signUp);
      expect(state.status, AuthStatus.signedOut);
      expect(state.errorMessage, isNull);
    });

    test('restoreSession with token sets signedIn', () async {
      final repository = FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final tokenStorage = _FakeTokenStorageWithToken('jwt-token');
      final controller = container.read(authControllerProvider.notifier);
      await controller.restoreSession(tokenStorage);

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.signedIn);
      expect(state.errorMessage, isNull);
    });

    test('restoreSession without token sets signedOut', () async {
      final repository = FakeAuthRepository();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final tokenStorage = FakeTokenStorage();
      final controller = container.read(authControllerProvider.notifier);
      await controller.restoreSession(tokenStorage);

      final state = container.read(authControllerProvider);
      expect(state.status, AuthStatus.signedOut);
      expect(state.errorMessage, isNull);
    });

    test('signIn sets loading while request is in progress', () async {
      final repository = FakeAuthRepository()
        ..pendingRequest = Completer<void>();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);
      final future = controller.signIn('user@example.com', 'secret');

      expect(container.read(authControllerProvider).status, AuthStatus.loading);

      repository.pendingRequest!.complete();
      await future;

      expect(container.read(authControllerProvider).status, AuthStatus.signedIn);
    });
  });
}

class _FakeTokenStorageWithToken implements TokenStorage {
  _FakeTokenStorageWithToken(this._token);

  final String _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async {}

  @override
  Future<void> delete() async {}
}
