import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knurl/features/auth/data/auth_repository.dart';
import 'package:knurl/shared/network/token_storage.dart';

class FakeTokenStorage implements TokenStorage {
  String? writtenToken;

  @override
  Future<String?> read() async => null;

  @override
  Future<void> write(String token) async {
    writtenToken = token;
  }

  @override
  Future<void> delete() async {}
}

class FakeDio implements Dio {
  String? path;
  Object? data;
  Map<String, dynamic>? responseData;

  @override
  Future<Response<T>> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    this.path = path;
    this.data = data;

    return Response<T>(
      requestOptions: RequestOptions(path: path),
      data: responseData as T?,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AuthRepository', () {
    test('signIn posts credentials to login and stores token', () async {
      final dio = FakeDio()..responseData = {'token': 'login-token'};
      final tokenStorage = FakeTokenStorage();
      final repository = AuthRepository(dio, tokenStorage);

      await repository.signIn('user@example.com', 'secret');

      expect(dio.path, '/auth/login');
      expect(dio.data, {'email': 'user@example.com', 'password': 'secret'});
      expect(tokenStorage.writtenToken, 'login-token');
    });

    test('signUp posts credentials to register and stores token', () async {
      final dio = FakeDio()..responseData = {'token': 'register-token'};
      final tokenStorage = FakeTokenStorage();
      final repository = AuthRepository(dio, tokenStorage);

      await repository.signUp('new@example.com', 'secret');

      expect(dio.path, '/auth/register');
      expect(dio.data, {'email': 'new@example.com', 'password': 'secret'});
      expect(tokenStorage.writtenToken, 'register-token');
    });

    test('throws StateError when token is missing', () async {
      final dio = FakeDio()..responseData = {};
      final tokenStorage = FakeTokenStorage();
      final repository = AuthRepository(dio, tokenStorage);

      final future = repository.signIn('user@example.com', 'secret');

      await expectLater(future, throwsA(isA<StateError>()));
      expect(tokenStorage.writtenToken, isNull);
    });
  });
}
