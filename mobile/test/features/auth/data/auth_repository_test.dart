import 'dart:convert';
import 'dart:typed_data';

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

class RecordingAdapter implements HttpClientAdapter {
  RequestOptions? lastOptions;
  Map<String, dynamic>? responseData;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastOptions = options;
    if (requestStream != null) {
      await requestStream.drain();
    }

    return ResponseBody.fromString(
      jsonEncode(responseData ?? <String, dynamic>{}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('AuthRepository', () {
    test('signIn posts credentials to login and stores token', () async {
      final adapter = RecordingAdapter()
        ..responseData = {'token': 'login-token'};
      final dio = Dio(BaseOptions(baseUrl: 'http://example.com'))
        ..httpClientAdapter = adapter;
      final tokenStorage = FakeTokenStorage();
      final repository = AuthRepository(dio, tokenStorage);

      await repository.signIn('user@example.com', 'secret');

      expect(adapter.lastOptions?.path, '/auth/login');
      expect(adapter.lastOptions?.data, {
        'email': 'user@example.com',
        'password': 'secret',
      });
      expect(tokenStorage.writtenToken, 'login-token');
    });

    test('signUp posts credentials to register and stores token', () async {
      final adapter = RecordingAdapter()
        ..responseData = {'token': 'register-token'};
      final dio = Dio(BaseOptions(baseUrl: 'http://example.com'))
        ..httpClientAdapter = adapter;
      final tokenStorage = FakeTokenStorage();
      final repository = AuthRepository(dio, tokenStorage);

      await repository.signUp('new@example.com', 'secret');

      expect(adapter.lastOptions?.path, '/auth/register');
      expect(adapter.lastOptions?.data, {
        'email': 'new@example.com',
        'password': 'secret',
      });
      expect(tokenStorage.writtenToken, 'register-token');
    });

    test('throws StateError when token is missing', () async {
      final adapter = RecordingAdapter()..responseData = {};
      final dio = Dio(BaseOptions(baseUrl: 'http://example.com'))
        ..httpClientAdapter = adapter;
      final tokenStorage = FakeTokenStorage();
      final repository = AuthRepository(dio, tokenStorage);

      final future = repository.signIn('user@example.com', 'secret');

      await expectLater(future, throwsA(isA<StateError>()));
      expect(tokenStorage.writtenToken, isNull);
    });
  });
}
