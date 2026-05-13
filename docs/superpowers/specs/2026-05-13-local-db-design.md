# Фича 2: Локальная БД (SQLite/Drift)

## Контекст

Приложение всегда читает и пишет в локальный SQLite. Это обеспечивает офлайн-работу в зале и основу для Sync Engine (фича 10). Drift выбран за типобезопасность и автогенерацию кода.

## Решения

- **Идентификаторы:** UUID генерируется на клиенте при создании записи. Тот же UUID уходит на сервер при синхронизации — один `id` на всю систему.
- **Упражнения:** нормализованная таблица `exercises`, `set_logs` ссылается через FK.
- **Миграции:** `MigrationStrategy` с явными версиями (`if (from < N)`), никакого `destroyEverything` в prod.
- **Доступ к данным:** Repository-классы поверх Drift (скрывают детали Drift, удобно мокать в тестах фич/UI).

## Схема таблиц

| Таблица | Ключевые поля |
|---|---|
| `exercises` | `id` UUID PK, `external_id` String, `name`, `muscle_group`, `cached_at` |
| `workout_plans` | `id` UUID PK, `name`, `updated_at`, `synced` bool |
| `workout_days` | `id` UUID PK, `plan_id` FK, `day_index` (0–6), `updated_at`, `synced` |
| `workout_day_exercises` | `id` UUID PK, `day_id` FK, `exercise_id` FK, `target_sets`, `target_reps`, `target_weight`, `order_index`, `updated_at`, `synced` |
| `workout_sessions` | `id` UUID PK, `plan_id` FK nullable, `started_at`, `finished_at` nullable, `updated_at`, `synced` |
| `set_logs` | `id` UUID PK, `session_id` FK, `exercise_id` FK, `set_number`, `weight`, `reps`, `logged_at`, `updated_at`, `synced` |

`synced` + `updated_at` присутствуют во всех пользовательских таблицах. Таблица `exercises` не синхронизируется — только кэш внешнего API.

## Структура файлов

```
mobile/lib/
├── core/
│   └── database/
│       ├── app_database.dart        # AppDatabase, schemaVersion, MigrationStrategy
│       ├── app_database.g.dart      # сгенерированный код (drift)
│       ├── migrations/
│       │   └── migration_v1.dart    # начальная схема (onCreate)
│       └── tables/
│           ├── exercises_table.dart
│           ├── workout_plans_table.dart
│           ├── workout_days_table.dart
│           ├── workout_day_exercises_table.dart
│           ├── workout_sessions_table.dart
│           └── set_logs_table.dart
└── features/
    ├── exercises/
    │   ├── data/
    │   │   ├── exercise_repository.dart        # абстрактный интерфейс
    │   │   └── drift_exercise_repository.dart  # реализация через Drift
    │   └── providers/
    │       └── exercise_providers.dart
    ├── workout_plans/
    │   └── data/  # аналогично
    ├── workout_sessions/
    │   └── data/  # аналогично
    └── set_logs/
        └── data/  # аналогично
```

## Repository-слой

Каждая фича получает интерфейс + Drift-реализацию:

```dart
abstract class WorkoutSessionRepository {
  Stream<List<WorkoutSession>> watchAll();
  Future<WorkoutSession?> findById(String id);
  Future<void> upsert(WorkoutSession session);
  Future<void> delete(String id);
  Future<List<WorkoutSession>> findUnsynced(); // для Sync Engine
}

class DriftWorkoutSessionRepository implements WorkoutSessionRepository {
  DriftWorkoutSessionRepository(this._db);
  final AppDatabase _db;
}
```

`watchAll()` возвращает `Stream` — Drift автоматически эмитит новые значения при изменении таблицы.  
`findUnsynced()` — единственный метод специфичный для синхронизации.

## Riverpod

```dart
final appDatabaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

final workoutSessionRepositoryProvider = Provider<WorkoutSessionRepository>(
  (ref) => DriftWorkoutSessionRepository(ref.read(appDatabaseProvider)),
);
```

`AppDatabase` — синглтон через `Provider`. Репозитории получают его через `ref.read`.

## Миграции

```dart
@DriftDatabase(tables: [...])
class AppDatabase extends _$AppDatabase {
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // await m.addColumn(...)
      }
    },
  );
}
```

Каждая новая версия — отдельный `if (from < N)` блок.

## Тестирование

- **Тесты репозиториев** — `NativeDatabase.memory()` (реальный SQLite in-memory, ~1мс). Проверяют SQL-запросы, миграции, Drift-кодогенерацию.
- **Тесты фич/UI** — `MockWorkoutSessionRepository` (мок интерфейса). Убирают зависимость от БД на уровне бизнес-логики и экранов.

## Out of Scope

- Шифрование БД (SQLCipher)
- Полнотекстовый поиск
- Экспорт/импорт данных
