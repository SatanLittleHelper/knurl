import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knurl/features/auth/data/auth_repository.dart';
import 'package:knurl/shared/network/api_exception.dart';
import 'package:knurl/shared/network/token_storage.dart';

enum AuthMode { signIn, signUp }

enum AuthStatus { signedOut, loading, error, signedIn }

class AuthState {
  const AuthState({
    required this.mode,
    required this.status,
    this.errorMessage,
  });

  final AuthMode mode;
  final AuthStatus status;
  final String? errorMessage;

  AuthState copyWith({
    AuthMode? mode,
    AuthStatus? status,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return AuthState(
      mode: mode ?? this.mode,
      status: status ?? this.status,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  AuthController(this._repository)
      : super(const AuthState(mode: AuthMode.signIn, status: AuthStatus.signedOut));

  final AuthRepository _repository;

  void setMode(AuthMode mode) {
    state = state.copyWith(
      mode: mode,
      status: AuthStatus.signedOut,
      clearErrorMessage: true,
    );
  }

  Future<void> restoreSession(TokenStorage tokenStorage) async {
    final token = await tokenStorage.read();
    state = state.copyWith(
      status: token == null ? AuthStatus.signedOut : AuthStatus.signedIn,
      clearErrorMessage: true,
    );
  }

  Future<void> signIn(String email, String password) {
    return _authenticate(
      mode: AuthMode.signIn,
      request: () => _repository.signIn(email, password),
    );
  }

  Future<void> signUp(String email, String password) {
    return _authenticate(
      mode: AuthMode.signUp,
      request: () => _repository.signUp(email, password),
    );
  }

  Future<void> _authenticate({
    required AuthMode mode,
    required Future<void> Function() request,
  }) async {
    state = AuthState(mode: mode, status: AuthStatus.loading);

    try {
      await request();
      state = AuthState(mode: mode, status: AuthStatus.signedIn);
    } catch (error) {
      state = AuthState(
        mode: mode,
        status: AuthStatus.error,
        errorMessage: _mapError(error),
      );
    }
  }

  String _mapError(Object error) {
    final apiException = _extractApiException(error);

    if (apiException != null) {
      if (apiException.code == ApiErrorCode.unauthorized) {
        return 'Неверный email или пароль';
      }

      if (apiException.statusCode == 400 || apiException.statusCode == 409) {
        final message = apiException.message.trim();
        if (message.isNotEmpty) {
          return message;
        }

        return 'Не удалось создать аккаунт';
      }
    }

    return 'Проблема с соединением. Попробуйте ещё раз.';
  }

  ApiException? _extractApiException(Object error) {
    if (error is ApiException) {
      return error;
    }

    if (error is DioException && error.error is ApiException) {
      return error.error as ApiException;
    }

    return null;
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});
