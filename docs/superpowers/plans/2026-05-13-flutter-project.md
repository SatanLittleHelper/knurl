# Flutter Project Init — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Создать Flutter-проект в `mobile/` с feature-first структурой, Riverpod, go_router и shared core (тема, Dio, router-заглушки).

**Architecture:** Shared core в `lib/shared/` предоставляет инфраструктуру (routing, theme, network); фичи живут в `lib/features/<name>/` и наполняются в отдельных итерациях. main.dart оборачивает всё в ProviderScope и передаёт router в MaterialApp.router.

**Tech Stack:** Flutter, flutter_riverpod 2.x, go_router 14.x, Dio 5.x, drift 2.x (зависимость добавлена, настройка в фиче 2), flutter_secure_storage 9.x.

---

### Task 1: Создать Flutter-проект, настроить pubspec.yaml и файл окружения

**Files:**
- Create: `mobile/` (flutter create)
- Modify: `mobile/pubspec.yaml`
- Create: `mobile/.env.local.json` (не в git)
- Create: `mobile/.env.example.json`
- Modify: `mobile/.gitignore`

- [ ] **Шаг 1: Создать проект**

```bash
cd /Users/aleksandr/WebstormProjects/knurl
flutter create --org com.knurl --platforms ios,android mobile
```

Ожидаемый вывод: `All done! ...`

- [ ] **Шаг 2: Заменить зависимости в pubspec.yaml**

Открыть `mobile/pubspec.yaml` и заменить секцию `dependencies` и `dev_dependencies` на:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.6.1
  riverpod_annotation: ^2.6.1
  go_router: ^14.0.0
  dio: ^5.7.0
  drift: ^2.21.0
  sqlite3_flutter_libs: ^0.5.0
  flutter_secure_storage: ^9.2.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.0
  riverpod_generator: ^2.6.1
  drift_dev: ^2.21.0
```

- [ ] **Шаг 3: Создать файл переменных окружения**

Flutter поддерживает `--dart-define-from-file=<path>` — удобнее, чем передавать каждую переменную отдельно.

Создать `mobile/.env.example.json` (шаблон, коммитится в git):

```json
{
  "API_URL": "http://localhost:8080"
}
```

Создать `mobile/.env.local.json` (реальные значения, не в git):

```json
{
  "API_URL": "http://localhost:8080"
}
```

Добавить в `mobile/.gitignore` строку:

```
.env.local.json
```

- [ ] **Шаг 4: Установить зависимости**

```bash
cd /Users/aleksandr/WebstormProjects/knurl/mobile
flutter pub get
```

Ожидаемый вывод: `Got dependencies!`

- [ ] **Шаг 5: Закоммитить**

```bash
git add mobile/
git commit -m "feat: инициализация Flutter-проекта с зависимостями и env-файлами"
```

---

### Task 2: Создать структуру папок

**Files:**
- Create: `mobile/lib/shared/router/.gitkeep`
- Create: `mobile/lib/shared/theme/.gitkeep`
- Create: `mobile/lib/shared/network/.gitkeep`
- Create: `mobile/lib/shared/widgets/.gitkeep`
- Create: `mobile/lib/features/auth/.gitkeep`
- Create: `mobile/lib/features/home/.gitkeep`
- Create: `mobile/lib/features/planner/.gitkeep`
- Create: `mobile/lib/features/workout/.gitkeep`
- Create: `mobile/lib/features/history/.gitkeep`
- Create: `mobile/lib/features/exercise_library/.gitkeep`
- Delete: `mobile/lib/main.dart` (будет пересоздан в Task 3)

- [ ] **Шаг 1: Создать папки shared и features**

```bash
mkdir -p mobile/lib/shared/router \
          mobile/lib/shared/theme \
          mobile/lib/shared/network \
          mobile/lib/shared/widgets \
          mobile/lib/features/auth \
          mobile/lib/features/home \
          mobile/lib/features/planner \
          mobile/lib/features/workout \
          mobile/lib/features/history \
          mobile/lib/features/exercise_library
```

- [ ] **Шаг 2: Добавить .gitkeep в пустые feature-папки**

```bash
touch mobile/lib/features/auth/.gitkeep \
      mobile/lib/features/home/.gitkeep \
      mobile/lib/features/planner/.gitkeep \
      mobile/lib/features/workout/.gitkeep \
      mobile/lib/features/history/.gitkeep \
      mobile/lib/features/exercise_library/.gitkeep
```

- [ ] **Шаг 3: Удалить сгенерированный main.dart и demo-файлы**

```bash
rm mobile/lib/main.dart
rm -rf mobile/test/widget_test.dart
```

- [ ] **Шаг 4: Закоммитить**

```bash
git add mobile/lib/
git commit -m "feat: структура папок feature-first"
```

---

### Task 3: Тема приложения

**Files:**
- Create: `mobile/lib/shared/theme/app_theme.dart`

- [ ] **Шаг 1: Создать app_theme.dart**

```dart
// mobile/lib/shared/theme/app_theme.dart
import 'package:flutter/material.dart';

final appTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6750A4)),
  useMaterial3: true,
);
```

- [ ] **Шаг 2: Закоммитить**

```bash
git add mobile/lib/shared/theme/app_theme.dart
git commit -m "feat: тема приложения"
```

---

### Task 4: go_router с маршрутами-заглушками

**Files:**
- Create: `mobile/lib/shared/router/app_router.dart`

- [ ] **Шаг 1: Создать app_router.dart**

```dart
// mobile/lib/shared/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/auth',
      builder: (context, state) =>
          const Scaffold(appBar: AppBar(title: Text('Auth'))),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) =>
          const Scaffold(appBar: AppBar(title: Text('Home'))),
    ),
    GoRoute(
      path: '/planner',
      builder: (context, state) =>
          const Scaffold(appBar: AppBar(title: Text('Planner'))),
    ),
    GoRoute(
      path: '/workout',
      builder: (context, state) =>
          const Scaffold(appBar: AppBar(title: Text('Active Workout'))),
    ),
    GoRoute(
      path: '/history',
      builder: (context, state) =>
          const Scaffold(appBar: AppBar(title: Text('History'))),
    ),
    GoRoute(
      path: '/exercises',
      builder: (context, state) =>
          const Scaffold(appBar: AppBar(title: Text('Exercise Library'))),
    ),
  ],
);
```

- [ ] **Шаг 2: Закоммитить**

```bash
git add mobile/lib/shared/router/app_router.dart
git commit -m "feat: go_router с маршрутами-заглушками"
```

---

### Task 5: API-клиент (Dio)

**Files:**
- Create: `mobile/lib/shared/network/api_client.dart`

- [ ] **Шаг 1: Создать api_client.dart**

```dart
// mobile/lib/shared/network/api_client.dart
import 'package:dio/dio.dart';

const _apiUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:8080',
);

final dio = Dio(
  BaseOptions(
    baseUrl: _apiUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ),
);
```

JWT-interceptor добавляется в фиче Auth (фича 4).

- [ ] **Шаг 2: Закоммитить**

```bash
git add mobile/lib/shared/network/api_client.dart
git commit -m "feat: Dio api_client с конфигурацией из dart-define"
```

---

### Task 6: main.dart и финальная проверка

**Files:**
- Create: `mobile/lib/main.dart`

- [ ] **Шаг 1: Создать main.dart**

```dart
// mobile/lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'shared/router/app_router.dart';
import 'shared/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: KnurlApp()));
}

class KnurlApp extends ConsumerWidget {
  const KnurlApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Knurl',
      theme: appTheme,
      routerConfig: router,
    );
  }
}
```

- [ ] **Шаг 2: Запустить статический анализ**

```bash
cd /Users/aleksandr/WebstormProjects/knurl/mobile
flutter analyze
```

Ожидаемый вывод: `No issues found!`

- [ ] **Шаг 3: Проверить сборку**

```bash
flutter build apk --debug --dart-define-from-file=.env.local.json
```

Ожидаемый вывод: `Built build/app/outputs/flutter-apk/app-debug.apk`

Если нет Android SDK — проверить через iOS:
```bash
flutter build ios --debug --no-codesign --dart-define-from-file=.env.local.json
```

При локальном запуске через `flutter run` также использовать:
```bash
flutter run --dart-define-from-file=.env.local.json
```

- [ ] **Шаг 4: Закоммитить**

```bash
git add mobile/lib/main.dart
git commit -m "feat: main.dart с ProviderScope и MaterialApp.router"
```

---

### Task 7: Обновить статус фичи в docs/flutter-features.md

**Files:**
- Modify: `docs/flutter-features.md`

- [ ] **Шаг 1: Обновить таблицу статусов**

В `docs/flutter-features.md` в строке `| 1 | Проект Flutter | — | — | — |` заменить на:

```
| 1 | Проект Flutter | ✓ | ✓ | ✓ |
```

- [ ] **Шаг 2: Отметить чекбокс**

В списке фич заменить:
```
1. [ ] **Проект Flutter** — ...
```
на:
```
1. [x] **Проект Flutter** — ...
```

- [ ] **Шаг 3: Закоммитить**

```bash
git add docs/flutter-features.md
git commit -m "docs: отметить фичу 1 (проект Flutter) как выполненную"
```
