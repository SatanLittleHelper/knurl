# API-клиент — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Построить сетевую инфраструктуру Flutter-приложения: JWT-токен в защищённом хранилище, Dio interceptor для авто-добавления токена к запросам, типизированные сетевые ошибки.

**Architecture:** `TokenStorage` оборачивает `flutter_secure_storage`. `AuthInterceptor` (Dio `Interceptor`) читает токен из `TokenStorage` и добавляет `Authorization: Bearer` к каждому запросу; ошибки `DioException` маппит в `ApiException`. `dioProvider` регистрирует interceptor через Riverpod.

**Tech Stack:** Flutter, Dart, Dio 5, flutter_secure_storage 9, flutter_riverpod 2, flutter_test

---

## Файловая карта

| Действие | Путь |
|----------|------|
| Создать | `mobile/lib/shared/network/api_exception.dart` |
| Создать | `mobile/lib/shared/network/token_storage.dart` |
| Создать | `mobile/lib/shared/network/auth_interceptor.dart` |
| Изменить | `mobile/lib/shared/network/api_client.dart` |
| Создать | `mobile/test/shared/network/auth_interceptor_test.dart` |

---

## Task 1: ApiException

**Files:**
- Create: `mobile/lib/shared/network/api_exception.dart`

- [ ] **Шаг 1: Создать файл**

```dart
// mobile/lib/shared/network/api_exception.dart
enum ApiErrorCode { unauthorized, notFound, serverError, networkError }

class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  final ApiErrorCode code;
  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException(${code.name}, $statusCode): $message';
}
```

---

## Task 2: TokenStorage

**Files:**
- Create: `mobile/lib/shared/network/token_storage.dart`

- [ ] **Шаг 1: Создать файл**

```dart
// mobile/lib/shared/network/token_storage.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _tokenKey = 'jwt_token';

abstract class TokenStorage {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> delete();
}

class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: _tokenKey);

  @override
  Future<void> write(String token) => _storage.write(key: _tokenKey, value: token);

  @override
  Future<void> delete() => _storage.delete(key: _tokenKey);
}

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => const SecureTokenStorage(FlutterSecureStorage()),
);
```

---

## Task 3: AuthInterceptor — тест

**Files:**
- Create: `mobile/test/shared/network/auth_interceptor_test.dart`

- [ ] **Шаг 1: Написать тест**

```dart
// mobile/test/shared/network/auth_interceptor_test.dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knurl/shared/network/api_exception.dart';
import 'package:knurl/shared/network/auth_interceptor.dart';
import 'package:knurl/shared/network/token_storage.dart';

class FakeTokenStorage implements TokenStorage {
  FakeTokenStorage([this._token]);

  final String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async {}

  @override
  Future<void> delete() async {}
}

void main() {
  group('AuthInterceptor', () {
    test('добавляет Authorization заголовок если токен есть', () async {
      final interceptor = AuthInterceptor(FakeTokenStorage('my-token'));
      final options = RequestOptions(path: '/test');
      final handler = RequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers['Authorization'], 'Bearer my-token');
    });

    test('не добавляет заголовок если токена нет', () async {
      final interceptor = AuthInterceptor(FakeTokenStorage(null));
      final options = RequestOptions(path: '/test');
      final handler = RequestInterceptorHandler();

      await interceptor.onRequest(options, handler);

      expect(options.headers.containsKey('Authorization'), isFalse);
    });

    test('DioException 404 → ApiException(notFound)', () {
      final interceptor = AuthInterceptor(FakeTokenStorage(null));
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 404,
        ),
        type: DioExceptionType.badResponse,
      );

      expect(
        () => interceptor.onError(dioError, ErrorInterceptorHandler()),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', ApiErrorCode.notFound),
        ),
      );
    });

    test('DioException 401 → ApiException(unauthorized)', () {
      final interceptor = AuthInterceptor(FakeTokenStorage(null));
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      );

      expect(
        () => interceptor.onError(dioError, ErrorInterceptorHandler()),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', ApiErrorCode.unauthorized),
        ),
      );
    });

    test('DioException 500 → ApiException(serverError)', () {
      final interceptor = AuthInterceptor(FakeTokenStorage(null));
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 500,
        ),
        type: DioExceptionType.badResponse,
      );

      expect(
        () => interceptor.onError(dioError, ErrorInterceptorHandler()),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', ApiErrorCode.serverError),
        ),
      );
    });

    test('connectionTimeout → ApiException(networkError)', () {
      final interceptor = AuthInterceptor(FakeTokenStorage(null));
      final dioError = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );

      expect(
        () => interceptor.onError(dioError, ErrorInterceptorHandler()),
        throwsA(
          isA<ApiException>().having((e) => e.code, 'code', ApiErrorCode.networkError),
        ),
      );
    });
  });
}
```

---

## Task 4: AuthInterceptor — реализация

**Files:**
- Create: `mobile/lib/shared/network/auth_interceptor.dart`

- [ ] **Шаг 1: Создать файл**

```dart
// mobile/lib/shared/network/auth_interceptor.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knurl/shared/network/api_exception.dart';
import 'package:knurl/shared/network/token_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage);

  final TokenStorage _tokenStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.read();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    throw _mapError(err);
  }

  ApiException _mapError(DioException err) {
    final statusCode = err.response?.statusCode;

    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return ApiException(
        code: ApiErrorCode.networkError,
        message: 'Нет соединения с сервером',
      );
    }

    return switch (statusCode) {
      401 => ApiException(
          code: ApiErrorCode.unauthorized,
          message: 'Требуется авторизация',
          statusCode: statusCode,
        ),
      404 => ApiException(
          code: ApiErrorCode.notFound,
          message: 'Ресурс не найден',
          statusCode: statusCode,
        ),
      _ when statusCode != null && statusCode >= 500 => ApiException(
          code: ApiErrorCode.serverError,
          message: 'Ошибка сервера',
          statusCode: statusCode,
        ),
      _ => ApiException(
          code: ApiErrorCode.networkError,
          message: err.message ?? 'Неизвестная ошибка сети',
          statusCode: statusCode,
        ),
    };
  }
}

final authInterceptorProvider = Provider<AuthInterceptor>(
  (ref) => AuthInterceptor(ref.read(tokenStorageProvider)),
);
```

- [ ] **Шаг 2: Запустить тесты**

```bash
cd mobile && flutter test test/shared/network/auth_interceptor_test.dart
```

Ожидается: все тесты зелёные.

---

## Task 5: Обновить dioProvider и .env

**Files:**
- Modify: `mobile/lib/shared/network/api_client.dart`
- Modify: `mobile/.env.example.json`

- [ ] **Шаг 1: Обновить api_client.dart**

```dart
// mobile/lib/shared/network/api_client.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knurl/shared/network/auth_interceptor.dart';

const _apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:8080',
);

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: _apiUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );
  dio.interceptors.add(ref.read(authInterceptorProvider));
  return dio;
});
```

- [ ] **Шаг 2: Обновить .env.example.json**

`API_URL` для Android-эмулятора должен быть `http://10.0.2.2:8080` (localhost недоступен изнутри эмулятора). Обновить `.env.example.json`:

```json
{
  "API_URL": "http://10.0.2.2:8080"
}
```

И `.env.json` (локальный, не коммитится):

```json
{
  "API_URL": "http://10.0.2.2:8080"
}
```

- [ ] **Шаг 3: Запустить все тесты**

```bash
cd mobile && flutter test
```

Ожидается: все тесты зелёные.

- [ ] **Шаг 4: Закоммитить всё**

```bash
git add mobile/lib/shared/network/ mobile/test/shared/network/ mobile/.env.example.json
git commit -m "feat: API-клиент — TokenStorage, AuthInterceptor, ApiException"
```
