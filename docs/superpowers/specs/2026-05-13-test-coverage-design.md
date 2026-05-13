# Test Coverage Design — Repository Pattern + Service Tests

**Date:** 2026-05-13  
**Scope:** All service packages in `backend/internal/`

---

## Context

Currently only two packages have tests:
- `internal/api` — 83.3% (shared HTTP helpers)
- `internal/auth` — 25.3% (middleware only; service and handler untested)

All other packages (`exercises`, `plans`, `sessions`, `sets`) have 0% coverage.

Handlers are thin (decode → call service → map error to status) and are not worth testing in isolation. All meaningful logic lives in the service layer.

---

## Approach

**Repository interface pattern (Approach A):** each package gets a `repository.go` file containing:
1. A `XxxRepository` interface that defines the storage contract
2. A `gormXxxRepo` struct that implements it via GORM

`service.go` is refactored to accept the interface instead of `*gorm.DB`. `cmd/api/main.go` is updated to pass `gormXxxRepo{db}` when constructing services. No new packages are introduced.

---

## File Layout Changes

```
internal/
  auth/
    repository.go       ← new: UserRepository + gormUserRepo
    service.go          ← refactor: *gorm.DB → UserRepository
    service_test.go     ← new
  exercises/
    repository.go       ← new: ExerciseRepository + gormExerciseRepo
    service.go          ← refactor
    service_test.go     ← new
  plans/
    repository.go       ← new: PlanRepository + gormPlanRepo
    service.go          ← refactor
    service_test.go     ← new
  sessions/
    repository.go       ← new: SessionRepository + gormSessionRepo
    service.go          ← refactor
    service_test.go     ← new
  sets/
    repository.go       ← new: SetRepository + gormSetRepo
    service.go          ← refactor
    service_test.go     ← new
```

`cmd/api/main.go` passes concrete repo structs to `NewService(...)` instead of raw `*gorm.DB`.

---

## Repository Interfaces

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

## Test Cases

### auth/service_test.go

| Method | Case |
|--------|------|
| `Register` | success → returns JWT string |
| `Register` | password < 6 chars → error |
| `Register` | invalid email → error |
| `Register` | repo returns unique violation → `ErrEmailTaken` |
| `Register` | repo returns other error → propagated |
| `Login` | success → returns JWT string |
| `Login` | user not found → `ErrInvalidCredentials` |
| `Login` | wrong password → `ErrInvalidCredentials` |

### exercises/service_test.go

| Method | Case |
|--------|------|
| `List` | cache fresh → provider not called |
| `List` | cache stale → calls provider, then reads from repo |
| `List` | provider returns error → still reads from repo |
| `List` | muscle filter → passed through to repo |

### plans/service_test.go

| Method | Case |
|--------|------|
| `ListPlans` | success |
| `ListPlans` | repo error → propagated |
| `CreatePlan` | success |
| `DeletePlan` | success |
| `ListDays` | success |
| `CreateDay` | success |
| `AddExercise` | success |

### sessions/service_test.go

| Method | Case |
|--------|------|
| `List` | success |
| `Create` | success — userID assigned to session |
| `Finish` | success |
| `Delete` | success |
| each | repo error → propagated |

### sets/service_test.go

| Method | Case |
|--------|------|
| `List` | success |
| `Create` | success — sessionID assigned |
| `Update` | success — FindByID called first, then Update |
| `Update` | FindByID error → propagated |
| `Delete` | success |
| each | repo error → propagated |

---

## Error Handling

- Service methods propagate repo errors as-is, except `auth` which maps specific DB errors to domain errors (`ErrEmailTaken`, `ErrInvalidCredentials`).
- Mock implementations in tests return configurable `error` values to exercise all error paths.
- `isUniqueViolation` in `auth/service.go` is tested indirectly via the `Register` unique violation case.

---

## Out of Scope

- Handler tests (`handler.go`) — too thin to justify the mock overhead.
- Integration tests against real PostgreSQL — separate concern, not part of this change.
- `internal/config` and `internal/db` — trivial wrappers around `os.Getenv` and GORM open; not worth mocking.
