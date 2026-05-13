# Фича 1 — Проект Flutter: Design Spec

## Контекст

Инициализация Flutter-проекта в `mobile/`. Бэкенд уже готов. Цель — создать надёжный фундамент (shared core), на который будут опираться все последующие фичи.

## Стек

- **State management:** flutter_riverpod + riverpod_annotation (codegen)
- **Навигация:** go_router
- **Сеть:** Dio
- **Локальная БД:** drift + sqlite3_flutter_libs
- **Хранение JWT:** flutter_secure_storage
- **Codegen:** build_runner + riverpod_generator + drift_dev

## Структура папок

```
mobile/
└── lib/
    ├── main.dart
    ├── shared/
    │   ├── router/
    │   │   └── app_router.dart
    │   ├── theme/
    │   │   └── app_theme.dart
    │   ├── network/
    │   │   └── api_client.dart
    │   └── widgets/
    └── features/
        ├── auth/
        ├── home/
        ├── planner/
        ├── workout/
        ├── history/
        └── exercise_library/
```

## Зависимости (pubspec.yaml)

```yaml
dependencies:
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
  go_router: ^14.0.0
  dio: ^5.7.0
  drift: ^2.21.0
  sqlite3_flutter_libs: ^0.5.0
  flutter_secure_storage: ^9.2.2

dev_dependencies:
  build_runner: ^2.4.0
  riverpod_generator: ^2.6.1
  drift_dev: ^2.21.0
```

## Shared Core

### main.dart
Точка входа. Оборачивает приложение в `ProviderScope`. Передаёт `router` из `app_router.dart` в `MaterialApp.router`.

### shared/router/app_router.dart
Единый файл с go_router. Содержит маршруты-заглушки для всех экранов:

| Маршрут | Экран |
|---------|-------|
| `/auth` | Auth |
| `/` | Home |
| `/planner` | Planner |
| `/workout` | Active Workout |
| `/history` | History |
| `/exercises` | Exercise Library |

Каждый маршрут ведёт на пустой `Scaffold` с заголовком. При разработке фичи маршрут заменяется на реальный экран.

### shared/theme/app_theme.dart
`ThemeData` с цветовой схемой и типографикой. Один файл без разбивки.

### shared/network/api_client.dart
`Dio` с `baseUrl` из `--dart-define=API_URL=...`. JWT-interceptor добавляется в фиче Auth. Сейчас только инициализация экземпляра Dio.

### features/
Пустые папки для каждой фичи. Наполняются при брейнштормах и реализации соответствующих фич.

## Что не входит в эту фичу

- Настройка drift-схемы (фича 2)
- JWT-interceptor и логика авторизации (фича 3 и 4)
- Любая бизнес-логика экранов
- Запуск build_runner (нужен с фичи 2)
