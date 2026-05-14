# Фича 3: API-клиент — Design Spec

## Обзор

Инфраструктурный слой сетевого взаимодействия Flutter-приложения с Go-бэкендом. Включает хранение JWT-токена, добавление его к запросам и единообразную обработку ошибок. Конкретные CRUD-методы не входят в скоуп — они добавляются в репозиториях по мере появления экранов.

## Скоуп

**Входит:**
- `TokenStorage` — чтение/запись/удаление JWT из `flutter_secure_storage`
- `AuthInterceptor` — Dio interceptor, добавляет Bearer-токен и маппит ошибки
- `ApiException` + `ApiErrorCode` — типизированные сетевые ошибки
- Расширение `dioProvider` — подключение interceptor

**Не входит:**
- Refresh token (нет эндпоинта на бэкенде, добавим с Auth-экраном)
- CRUD-методы для конкретных ресурсов
- Retry-логика

## Структура файлов

```
mobile/lib/shared/network/
├── api_client.dart          # dioProvider (расширяем существующий)
├── auth_interceptor.dart    # добавляет Bearer-токен, маппит DioException
├── api_exception.dart       # ApiException + ApiErrorCode enum
└── token_storage.dart       # TokenStorage + tokenStorageProvider
```

## Компоненты

### TokenStorage (`token_storage.dart`)

Обёртка над `flutter_secure_storage` с тремя методами:

```dart
class TokenStorage {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> delete();
}

final tokenStorageProvider = Provider<TokenStorage>(...);
```

Ключ хранения: `'jwt_token'`.

### ApiException (`api_exception.dart`)

```dart
enum ApiErrorCode { unauthorized, notFound, serverError, networkError }

class ApiException implements Exception {
  final ApiErrorCode code;
  final String message;
  final int? statusCode;
}
```

Маппинг HTTP-кодов:
- 401 → `unauthorized`
- 404 → `notFound`
- 5xx → `serverError`
- нет соединения / таймаут → `networkError`

### AuthInterceptor (`auth_interceptor.dart`)

Dio `Interceptor`:

- `onRequest`: читает токен через `TokenStorage.read()`. Если токен есть — добавляет `Authorization: Bearer <token>`. Если нет — пропускает (публичные эндпоинты работают без токена).
- `onError`: перехватывает `DioException`, преобразует в `ApiException` по таблице выше и бросает его дальше.

```dart
final authInterceptorProvider = Provider<AuthInterceptor>(...);
```

### dioProvider (`api_client.dart`)

Расширяем существующий `dioProvider`: после создания `Dio` добавляем `AuthInterceptor` через `ref.read(authInterceptorProvider)`.

## Поток данных

**Успешный запрос:**
```
Репозиторий → Dio
  → AuthInterceptor.onRequest → добавляет заголовок
  → Go-сервер → 200 OK
  → данные возвращаются в репозиторий
```

**Ошибка:**
```
Go-сервер → 401
  → AuthInterceptor.onError → ApiException(code: unauthorized)
  → ApiException летит в репозиторий / UI
```

## Тестирование

Юнит-тест на `AuthInterceptor` с моком `TokenStorage`:
- токен есть → заголовок `Authorization` добавлен корректно
- токена нет → заголовок отсутствует
- `DioException(401)` → `ApiException(code: unauthorized)`
- `DioException(500)` → `ApiException(code: serverError)`
- нет соединения → `ApiException(code: networkError)`

## Зависимости

Добавить в `pubspec.yaml`:
- `flutter_secure_storage` — защищённое хранилище токена
