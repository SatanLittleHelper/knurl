# Дизайн: покрытие тестами — паттерн Repository + тесты сервисов

**Дата:** 2026-05-13  
**Область:** все сервисные пакеты в `backend/internal/`

---

## Контекст

На данный момент тесты есть только в двух пакетах:
- `internal/api` — 83.3% (общие HTTP-хелперы)
- `internal/auth` — 25.3% (только middleware; сервис и хендлер не покрыты)

Остальные пакеты (`exercises`, `plans`, `sessions`, `sets`) — 0% покрытия.

Хендлеры тонкие (декодировать → вызвать сервис → замапить ошибку на статус) и не стоят затрат на моки. Вся значимая логика находится в сервисном слое.

---

## Подход

**Паттерн Repository-интерфейс (Вариант A):** каждый пакет получает файл `repository.go`, содержащий:
1. Интерфейс `XxxRepository` — контракт хранилища
2. Структуру `gormXxxRepo` — реализация через GORM

`service.go` рефакторится: вместо `*gorm.DB` принимает интерфейс. `cmd/api/main.go` обновляется — при создании сервисов передаётся `gormXxxRepo{db}`. Новые пакеты не создаются.

---

## Изменения в файловой структуре

```
internal/
  auth/
    repository.go       ← новый: UserRepository + gormUserRepo
    service.go          ← рефактор: *gorm.DB → UserRepository
    service_test.go     ← новый
  exercises/
    repository.go       ← новый: ExerciseRepository + gormExerciseRepo
    service.go          ← рефактор
    service_test.go     ← новый
  plans/
    repository.go       ← новый: PlanRepository + gormPlanRepo
    service.go          ← рефактор
    service_test.go     ← новый
  sessions/
    repository.go       ← новый: SessionRepository + gormSessionRepo
    service.go          ← рефактор
    service_test.go     ← новый
  sets/
    repository.go       ← новый: SetRepository + gormSetRepo
    service.go          ← рефактор
    service_test.go     ← новый
```

`cmd/api/main.go` передаёт конкретные repo-структуры в `NewService(...)` вместо голого `*gorm.DB`.

---

## Интерфейсы репозиториев

### auth
```go
type UserRepository interface {
    Create(ctx context.Context, user *User) error
    FindByEmail(ctx context.Context, email string) (*User, error)
}
```

### exercises
```go
type ExerciseRepository interface {
    Upsert(ctx context.Context, exercises []Exercise) error
    List(muscle string) ([]Exercise, error)
}
```

### plans
```go
type PlanRepository interface {
    ListPlans(userID uuid.UUID) ([]WorkoutPlan, error)
    CreatePlan(plan WorkoutPlan) (WorkoutPlan, error)
    DeletePlan(id, userID uuid.UUID) error
    ListDays(planID uuid.UUID) ([]WorkoutDay, error)
    CreateDay(day WorkoutDay) (WorkoutDay, error)
    AddExercise(ex PlannedExercise) (PlannedExercise, error)
}
```

### sessions
```go
type SessionRepository interface {
    List(userID uuid.UUID) ([]WorkoutSession, error)
    Create(sess *WorkoutSession) error
    Finish(id, userID uuid.UUID, at time.Time) error
    Delete(id, userID uuid.UUID) error
}
```

### sets
```go
type SetRepository interface {
    List(sessionID uuid.UUID) ([]SetLog, error)
    Create(log *SetLog) error
    FindByID(id uuid.UUID) (SetLog, error)
    Update(log SetLog) (SetLog, error)
    Delete(id uuid.UUID) error
}
```

---

## Тест-кейсы

### auth/service_test.go

| Метод | Кейс |
|-------|------|
| `Register` | успех → возвращает JWT-строку |
| `Register` | пароль < 6 символов → ошибка |
| `Register` | невалидный email → ошибка |
| `Register` | repo вернул unique violation → `ErrEmailTaken` |
| `Register` | repo вернул другую ошибку → проброс |
| `Login` | успех → возвращает JWT-строку |
| `Login` | пользователь не найден → `ErrInvalidCredentials` |
| `Login` | неверный пароль → `ErrInvalidCredentials` |

### exercises/service_test.go

| Метод | Кейс |
|-------|------|
| `List` | кэш свежий → провайдер не вызывается |
| `List` | кэш протух → вызывает провайдер, затем читает из repo |
| `List` | провайдер вернул ошибку → всё равно читает из repo |
| `List` | фильтр по muscle → передаётся в repo |

### plans/service_test.go

| Метод | Кейс |
|-------|------|
| `ListPlans` | успех |
| `ListPlans` | ошибка repo → проброс |
| `CreatePlan` | успех |
| `DeletePlan` | успех |
| `ListDays` | успех |
| `CreateDay` | успех |
| `AddExercise` | успех |

### sessions/service_test.go

| Метод | Кейс |
|-------|------|
| `List` | успех |
| `Create` | успех — userID присваивается сессии |
| `Finish` | успех |
| `Delete` | успех |
| каждый | ошибка repo → проброс |

### sets/service_test.go

| Метод | Кейс |
|-------|------|
| `List` | успех |
| `Create` | успех — sessionID присваивается |
| `Update` | успех — сначала вызывается FindByID, затем Update |
| `Update` | ошибка FindByID → проброс |
| `Delete` | успех |
| каждый | ошибка repo → проброс |

---

## Обработка ошибок

- Методы сервисов пробрасывают ошибки repo как есть, кроме `auth` — там конкретные DB-ошибки маппятся в доменные (`ErrEmailTaken`, `ErrInvalidCredentials`).
- Моки в тестах возвращают настраиваемые значения `error` для покрытия всех путей ошибок.
- `isUniqueViolation` в `auth/service.go` тестируется косвенно через кейс unique violation в `Register`.

---

## Вне области

- Тесты хендлеров (`handler.go`) — слишком тонкие, не оправдывают мок-оверхед.
- Интеграционные тесты против реального PostgreSQL — отдельная задача.
- `internal/config` и `internal/db` — тривиальные обёртки, не требуют тестирования.
