# План реализации: Repository-интерфейс и тесты сервисов

> **Для агентных исполнителей:** ОБЯЗАТЕЛЬНЫЙ НАВ-СКИЛЛ: используй superpowers:subagent-driven-development (рекомендуется) или superpowers:executing-plans для пошагового выполнения.

**Цель:** Ввести паттерн Repository-интерфейс во все сервисные пакеты и покрыть сервисную логику unit-тестами без обращения к реальной БД.

**Архитектура:** В каждом пакете появляется `repository.go` с интерфейсом `XxxRepository` и GORM-реализацией `gormXxxRepo`. `service.go` рефакторится — принимает интерфейс вместо `*gorm.DB`. `cmd/api/main.go` передаёт конкретные repo-конструкторы.

**Стек:** Go, GORM, chi, github.com/golang-jwt/jwt/v5, github.com/jackc/pgx/v5/pgconn, golang.org/x/crypto/bcrypt

---

## Файловая структура

| Файл | Действие |
|------|----------|
| `backend/internal/auth/repository.go` | создать |
| `backend/internal/auth/service.go` | изменить |
| `backend/internal/auth/service_test.go` | создать |
| `backend/internal/exercises/repository.go` | создать |
| `backend/internal/exercises/service.go` | изменить |
| `backend/internal/exercises/service_test.go` | создать |
| `backend/internal/plans/repository.go` | создать |
| `backend/internal/plans/service.go` | изменить |
| `backend/internal/plans/service_test.go` | создать |
| `backend/internal/sessions/repository.go` | создать |
| `backend/internal/sessions/service.go` | изменить |
| `backend/internal/sessions/service_test.go` | создать |
| `backend/internal/sets/repository.go` | создать |
| `backend/internal/sets/service.go` | изменить |
| `backend/internal/sets/service_test.go` | создать |
| `backend/cmd/api/main.go` | изменить (5 строк) |

---

## Задача 1: пакет auth

**Файлы:**
- Создать: `backend/internal/auth/repository.go`
- Изменить: `backend/internal/auth/service.go`
- Создать: `backend/internal/auth/service_test.go`
- Изменить: `backend/cmd/api/main.go`

- [ ] **Шаг 1: Написать service_test.go (тест не скомпилируется — NewService пока принимает *gorm.DB)**

```go
// backend/internal/auth/service_test.go
package auth_test

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/satanlittlehelper/knurl/backend/internal/auth"
	"golang.org/x/crypto/bcrypt"
)

type mockUserRepo struct {
	createErr error
	foundUser *auth.User
	findErr   error
}

func (m *mockUserRepo) Create(_ context.Context, _ *auth.User) error {
	return m.createErr
}

func (m *mockUserRepo) FindByEmail(_ context.Context, _ string) (*auth.User, error) {
	return m.foundUser, m.findErr
}

const testJWTSecret = "a-secret-key-that-is-at-least-32-chars!"

func TestRegister_Success(t *testing.T) {
	svc := auth.NewService(&mockUserRepo{}, testJWTSecret)
	token, err := svc.Register(context.Background(), "user@example.com", "password123")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if token == "" {
		t.Fatal("expected non-empty token")
	}
}

func TestRegister_ShortPassword(t *testing.T) {
	svc := auth.NewService(&mockUserRepo{}, testJWTSecret)
	_, err := svc.Register(context.Background(), "user@example.com", "abc")
	if err == nil {
		t.Fatal("expected error for short password")
	}
}

func TestRegister_InvalidEmail(t *testing.T) {
	svc := auth.NewService(&mockUserRepo{}, testJWTSecret)
	_, err := svc.Register(context.Background(), "not-an-email", "password123")
	if err == nil {
		t.Fatal("expected error for invalid email")
	}
}

func TestRegister_EmailTaken(t *testing.T) {
	repo := &mockUserRepo{createErr: &pgconn.PgError{Code: "23505"}}
	svc := auth.NewService(repo, testJWTSecret)
	_, err := svc.Register(context.Background(), "user@example.com", "password123")
	if !errors.Is(err, auth.ErrEmailTaken) {
		t.Fatalf("expected ErrEmailTaken, got %v", err)
	}
}

func TestRegister_RepoError(t *testing.T) {
	repo := &mockUserRepo{createErr: errors.New("db error")}
	svc := auth.NewService(repo, testJWTSecret)
	_, err := svc.Register(context.Background(), "user@example.com", "password123")
	if err == nil || errors.Is(err, auth.ErrEmailTaken) {
		t.Fatalf("expected generic error, got %v", err)
	}
}

func TestLogin_Success(t *testing.T) {
	hash, _ := bcrypt.GenerateFromPassword([]byte("password123"), bcrypt.DefaultCost)
	user := &auth.User{ID: uuid.New(), Email: "user@example.com", PasswordHash: string(hash)}
	svc := auth.NewService(&mockUserRepo{foundUser: user}, testJWTSecret)
	token, err := svc.Login(context.Background(), "user@example.com", "password123")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if token == "" {
		t.Fatal("expected non-empty token")
	}
}

func TestLogin_UserNotFound(t *testing.T) {
	repo := &mockUserRepo{findErr: errors.New("record not found")}
	svc := auth.NewService(repo, testJWTSecret)
	_, err := svc.Login(context.Background(), "user@example.com", "password123")
	if !errors.Is(err, auth.ErrInvalidCredentials) {
		t.Fatalf("expected ErrInvalidCredentials, got %v", err)
	}
}

func TestLogin_WrongPassword(t *testing.T) {
	hash, _ := bcrypt.GenerateFromPassword([]byte("correct-password"), bcrypt.DefaultCost)
	user := &auth.User{ID: uuid.New(), Email: "user@example.com", PasswordHash: string(hash)}
	svc := auth.NewService(&mockUserRepo{foundUser: user}, testJWTSecret)
	_, err := svc.Login(context.Background(), "user@example.com", "wrong-password")
	if !errors.Is(err, auth.ErrInvalidCredentials) {
		t.Fatalf("expected ErrInvalidCredentials, got %v", err)
	}
}
```

- [ ] **Шаг 2: Убедиться что не компилируется**

```bash
cd backend && go build ./internal/auth/...
```
Ожидание: ошибка компиляции — `mockUserRepo` не реализует `*gorm.DB`-принимающий интерфейс.

- [ ] **Шаг 3: Создать repository.go**

```go
// backend/internal/auth/repository.go
package auth

import (
	"context"

	"gorm.io/gorm"
)

type UserRepository interface {
	Create(ctx context.Context, user *User) error
	FindByEmail(ctx context.Context, email string) (*User, error)
}

type gormUserRepo struct {
	db *gorm.DB
}

func NewGormUserRepo(db *gorm.DB) UserRepository {
	return &gormUserRepo{db: db}
}

func (r *gormUserRepo) Create(ctx context.Context, user *User) error {
	return r.db.WithContext(ctx).Create(user).Error
}

func (r *gormUserRepo) FindByEmail(ctx context.Context, email string) (*User, error) {
	var user User
	if err := r.db.WithContext(ctx).Where("email = ?", email).First(&user).Error; err != nil {
		return nil, err
	}
	return &user, nil
}
```

- [ ] **Шаг 4: Рефакторить service.go — заменить *gorm.DB на UserRepository**

```go
// backend/internal/auth/service.go
package auth

import (
	"context"
	"errors"
	"log"
	"net/mail"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgconn"
	"golang.org/x/crypto/bcrypt"
)

var ErrInvalidCredentials = errors.New("invalid credentials")
var ErrEmailTaken = errors.New("email already taken")

type Service struct {
	repo      UserRepository
	jwtSecret []byte
}

func NewService(repo UserRepository, jwtSecret string) *Service {
	if len(jwtSecret) < 32 {
		log.Println("warning: JWT_SECRET is shorter than 32 bytes")
	}
	return &Service{repo: repo, jwtSecret: []byte(jwtSecret)}
}

func (s *Service) Register(ctx context.Context, email, password string) (string, error) {
	if len(password) < 6 {
		return "", errors.New("password must be at least 6 characters")
	}
	if _, err := mail.ParseAddress(email); err != nil {
		return "", errors.New("invalid email")
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return "", err
	}

	user := User{Email: email, PasswordHash: string(hash)}
	if err := s.repo.Create(ctx, &user); err != nil {
		if isUniqueViolation(err) {
			return "", ErrEmailTaken
		}
		return "", err
	}

	return s.issueToken(user.ID)
}

func (s *Service) Login(ctx context.Context, email, password string) (string, error) {
	user, err := s.repo.FindByEmail(ctx, email)
	if err != nil {
		return "", ErrInvalidCredentials
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password)); err != nil {
		return "", ErrInvalidCredentials
	}

	return s.issueToken(user.ID)
}

func (s *Service) issueToken(userID uuid.UUID) (string, error) {
	claims := jwt.MapClaims{
		"sub": userID.String(),
		"exp": time.Now().Add(30 * 24 * time.Hour).Unix(),
	}
	return jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString(s.jwtSecret)
}

func isUniqueViolation(err error) bool {
	var pgErr *pgconn.PgError
	return errors.As(err, &pgErr) && pgErr.Code == "23505"
}
```

- [ ] **Шаг 5: Обновить main.go — строку создания authSvc**

Заменить:
```go
authSvc := auth.NewService(database, cfg.JWTSecret)
```
На:
```go
authSvc := auth.NewService(auth.NewGormUserRepo(database), cfg.JWTSecret)
```

- [ ] **Шаг 6: Запустить тесты пакета auth**

```bash
cd backend && go test ./internal/auth/...
```
Ожидание: все тесты проходят (`ok github.com/satanlittlehelper/knurl/backend/internal/auth`).

- [ ] **Шаг 7: Закоммитить**

```bash
git add backend/internal/auth/repository.go backend/internal/auth/service.go backend/internal/auth/service_test.go backend/cmd/api/main.go
git commit -m "test: auth — repository interface + service tests"
```

---

## Задача 2: пакет exercises

**Файлы:**
- Создать: `backend/internal/exercises/repository.go`
- Изменить: `backend/internal/exercises/service.go`
- Создать: `backend/internal/exercises/service_test.go`
- Изменить: `backend/cmd/api/main.go`

> Примечание: тесты в `package exercises` (не `exercises_test`), чтобы получить доступ к unexported полю `lastFetchedAt` для тестирования логики кэша.

- [ ] **Шаг 1: Написать service_test.go**

```go
// backend/internal/exercises/service_test.go
package exercises

import (
	"context"
	"errors"
	"testing"
	"time"
)

type mockExerciseRepo struct {
	upsertErr   error
	listResult  []Exercise
	listErr     error
	upsertCalls int
	lastMuscle  string
}

func (m *mockExerciseRepo) Upsert(_ context.Context, _ []Exercise) error {
	m.upsertCalls++
	return m.upsertErr
}

func (m *mockExerciseRepo) List(muscle string) ([]Exercise, error) {
	m.lastMuscle = muscle
	return m.listResult, m.listErr
}

type mockProvider struct {
	fetchResult []Exercise
	fetchErr    error
	fetchCalls  int
}

func (m *mockProvider) FetchAll(_ context.Context) ([]Exercise, error) {
	m.fetchCalls++
	return m.fetchResult, m.fetchErr
}

func TestList_CacheFresh_ProviderNotCalled(t *testing.T) {
	repo := &mockExerciseRepo{listResult: []Exercise{{ID: "squat", Name: "Squat"}}}
	provider := &mockProvider{}
	svc := &Service{repo: repo, provider: provider, lastFetchedAt: time.Now()}

	_, err := svc.List(context.Background(), "")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if provider.fetchCalls != 0 {
		t.Fatalf("expected provider not called, got %d calls", provider.fetchCalls)
	}
}

func TestList_CacheStale_ProviderCalled(t *testing.T) {
	exercises := []Exercise{{ID: "squat", Name: "Squat"}}
	repo := &mockExerciseRepo{listResult: exercises}
	provider := &mockProvider{fetchResult: exercises}
	svc := &Service{repo: repo, provider: provider}
	// lastFetchedAt нулевое — кэш устарел

	_, err := svc.List(context.Background(), "")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if provider.fetchCalls != 1 {
		t.Fatalf("expected provider called once, got %d", provider.fetchCalls)
	}
}

func TestList_ProviderError_StillReadsFromRepo(t *testing.T) {
	exercises := []Exercise{{ID: "squat", Name: "Squat"}}
	repo := &mockExerciseRepo{listResult: exercises}
	provider := &mockProvider{fetchErr: errors.New("api error")}
	svc := &Service{repo: repo, provider: provider}
	// устаревший кэш — провайдер вызовется, вернёт ошибку, но List всё равно читает из repo

	result, err := svc.List(context.Background(), "")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(result) != 1 {
		t.Fatalf("expected 1 exercise from repo, got %d", len(result))
	}
}

func TestList_MuscleFilter_PassedToRepo(t *testing.T) {
	repo := &mockExerciseRepo{}
	svc := &Service{repo: repo, provider: &mockProvider{}, lastFetchedAt: time.Now()}

	svc.List(context.Background(), "chest")

	if repo.lastMuscle != "chest" {
		t.Fatalf("expected muscle 'chest' passed to repo, got '%s'", repo.lastMuscle)
	}
}
```

- [ ] **Шаг 2: Убедиться что не компилируется**

```bash
cd backend && go build ./internal/exercises/...
```
Ожидание: ошибка — `Service` не имеет поля `repo`.

- [ ] **Шаг 3: Создать repository.go**

```go
// backend/internal/exercises/repository.go
package exercises

import (
	"context"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type ExerciseRepository interface {
	Upsert(ctx context.Context, exercises []Exercise) error
	List(muscle string) ([]Exercise, error)
}

type gormExerciseRepo struct {
	db *gorm.DB
}

func NewGormExerciseRepo(db *gorm.DB) ExerciseRepository {
	return &gormExerciseRepo{db: db}
}

func (r *gormExerciseRepo) Upsert(ctx context.Context, exercises []Exercise) error {
	return r.db.WithContext(ctx).Clauses(clause.OnConflict{UpdateAll: true}).Create(&exercises).Error
}

func (r *gormExerciseRepo) List(muscle string) ([]Exercise, error) {
	var exercises []Exercise
	query := r.db.Order("name")
	if muscle != "" {
		query = query.Where("muscle_group = ?", muscle)
	}
	return exercises, query.Find(&exercises).Error
}
```

- [ ] **Шаг 4: Рефакторить service.go**

```go
// backend/internal/exercises/service.go
package exercises

import (
	"context"
	"time"
)

const cacheTTL = 24 * time.Hour

type Service struct {
	repo          ExerciseRepository
	provider      ExerciseProvider
	lastFetchedAt time.Time
}

func NewService(repo ExerciseRepository, provider ExerciseProvider) *Service {
	return &Service{repo: repo, provider: provider}
}

func (s *Service) List(_ context.Context, muscle string) ([]Exercise, error) {
	if s.isCacheStale() {
		_ = s.refreshCache()
	}
	return s.repo.List(muscle)
}

func (s *Service) isCacheStale() bool {
	return s.lastFetchedAt.IsZero() || time.Since(s.lastFetchedAt) > cacheTTL
}

func (s *Service) refreshCache() error {
	exercises, err := s.provider.FetchAll(context.Background())
	if err != nil {
		return err
	}
	if err := s.repo.Upsert(context.Background(), exercises); err != nil {
		return err
	}
	s.lastFetchedAt = time.Now()
	return nil
}
```

- [ ] **Шаг 5: Обновить main.go — строку создания exerciseSvc**

Заменить:
```go
exerciseSvc := exercises.NewService(database, exercises.StubProvider{})
```
На:
```go
exerciseSvc := exercises.NewService(exercises.NewGormExerciseRepo(database), exercises.StubProvider{})
```

- [ ] **Шаг 6: Запустить тесты**

```bash
cd backend && go test ./internal/exercises/...
```
Ожидание: все 4 теста проходят.

- [ ] **Шаг 7: Закоммитить**

```bash
git add backend/internal/exercises/repository.go backend/internal/exercises/service.go backend/internal/exercises/service_test.go backend/cmd/api/main.go
git commit -m "test: exercises — repository interface + service tests"
```

---

## Задача 3: пакет plans

**Файлы:**
- Создать: `backend/internal/plans/repository.go`
- Изменить: `backend/internal/plans/service.go`
- Создать: `backend/internal/plans/service_test.go`
- Изменить: `backend/cmd/api/main.go`

- [ ] **Шаг 1: Написать service_test.go**

```go
// backend/internal/plans/service_test.go
package plans_test

import (
	"errors"
	"testing"

	"github.com/google/uuid"
	"github.com/satanlittlehelper/knurl/backend/internal/plans"
)

type mockPlanRepo struct {
	listPlansResult  []plans.WorkoutPlan
	createPlanResult plans.WorkoutPlan
	listDaysResult   []plans.WorkoutDay
	createDayResult  plans.WorkoutDay
	addExResult      plans.PlannedExercise
	err              error
}

func (m *mockPlanRepo) ListPlans(_ uuid.UUID) ([]plans.WorkoutPlan, error) {
	return m.listPlansResult, m.err
}
func (m *mockPlanRepo) CreatePlan(plan plans.WorkoutPlan) (plans.WorkoutPlan, error) {
	return m.createPlanResult, m.err
}
func (m *mockPlanRepo) DeletePlan(_, _ uuid.UUID) error { return m.err }
func (m *mockPlanRepo) ListDays(_ uuid.UUID) ([]plans.WorkoutDay, error) {
	return m.listDaysResult, m.err
}
func (m *mockPlanRepo) CreateDay(day plans.WorkoutDay) (plans.WorkoutDay, error) {
	return m.createDayResult, m.err
}
func (m *mockPlanRepo) AddExercise(ex plans.PlannedExercise) (plans.PlannedExercise, error) {
	return m.addExResult, m.err
}

func TestListPlans_Success(t *testing.T) {
	userID := uuid.New()
	want := []plans.WorkoutPlan{{UserID: userID, Name: "Plan A"}}
	svc := plans.NewService(&mockPlanRepo{listPlansResult: want})
	got, err := svc.ListPlans(userID)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(got) != 1 || got[0].Name != "Plan A" {
		t.Fatalf("unexpected result: %v", got)
	}
}

func TestListPlans_RepoError(t *testing.T) {
	svc := plans.NewService(&mockPlanRepo{err: errors.New("db error")})
	_, err := svc.ListPlans(uuid.New())
	if err == nil {
		t.Fatal("expected error")
	}
}

func TestCreatePlan_Success(t *testing.T) {
	userID := uuid.New()
	want := plans.WorkoutPlan{UserID: userID, Name: "My Plan"}
	svc := plans.NewService(&mockPlanRepo{createPlanResult: want})
	got, err := svc.CreatePlan(userID, "My Plan")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got.Name != "My Plan" {
		t.Fatalf("unexpected plan name: %s", got.Name)
	}
}

func TestDeletePlan_Success(t *testing.T) {
	svc := plans.NewService(&mockPlanRepo{})
	if err := svc.DeletePlan(uuid.New(), uuid.New()); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestListDays_Success(t *testing.T) {
	planID := uuid.New()
	want := []plans.WorkoutDay{{PlanID: planID, DayOfWeek: 1}}
	svc := plans.NewService(&mockPlanRepo{listDaysResult: want})
	got, err := svc.ListDays(planID)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(got) != 1 {
		t.Fatalf("expected 1 day, got %d", len(got))
	}
}

func TestCreateDay_Success(t *testing.T) {
	planID := uuid.New()
	want := plans.WorkoutDay{PlanID: planID, DayOfWeek: 3}
	svc := plans.NewService(&mockPlanRepo{createDayResult: want})
	got, err := svc.CreateDay(planID, 3)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got.DayOfWeek != 3 {
		t.Fatalf("expected day 3, got %d", got.DayOfWeek)
	}
}

func TestAddExercise_Success(t *testing.T) {
	ex := plans.PlannedExercise{ExerciseID: "squat", Sets: 3, Reps: 10}
	svc := plans.NewService(&mockPlanRepo{addExResult: ex})
	got, err := svc.AddExercise(ex)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got.ExerciseID != "squat" {
		t.Fatalf("unexpected exercise: %s", got.ExerciseID)
	}
}
```

- [ ] **Шаг 2: Убедиться что не компилируется**

```bash
cd backend && go build ./internal/plans/...
```
Ожидание: ошибка — `NewService` принимает `*gorm.DB`, а не `PlanRepository`.

- [ ] **Шаг 3: Создать repository.go**

```go
// backend/internal/plans/repository.go
package plans

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type PlanRepository interface {
	ListPlans(userID uuid.UUID) ([]WorkoutPlan, error)
	CreatePlan(plan WorkoutPlan) (WorkoutPlan, error)
	DeletePlan(id, userID uuid.UUID) error
	ListDays(planID uuid.UUID) ([]WorkoutDay, error)
	CreateDay(day WorkoutDay) (WorkoutDay, error)
	AddExercise(ex PlannedExercise) (PlannedExercise, error)
}

type gormPlanRepo struct {
	db *gorm.DB
}

func NewGormPlanRepo(db *gorm.DB) PlanRepository {
	return &gormPlanRepo{db: db}
}

func (r *gormPlanRepo) ListPlans(userID uuid.UUID) ([]WorkoutPlan, error) {
	var plans []WorkoutPlan
	return plans, r.db.Where("user_id = ?", userID).Order("created_at DESC").Find(&plans).Error
}

func (r *gormPlanRepo) CreatePlan(plan WorkoutPlan) (WorkoutPlan, error) {
	return plan, r.db.Create(&plan).Error
}

func (r *gormPlanRepo) DeletePlan(id, userID uuid.UUID) error {
	return r.db.Where("id = ? AND user_id = ?", id, userID).Delete(&WorkoutPlan{}).Error
}

func (r *gormPlanRepo) ListDays(planID uuid.UUID) ([]WorkoutDay, error) {
	var days []WorkoutDay
	return days, r.db.Where("plan_id = ?", planID).Order("day_of_week").Find(&days).Error
}

func (r *gormPlanRepo) CreateDay(day WorkoutDay) (WorkoutDay, error) {
	return day, r.db.Create(&day).Error
}

func (r *gormPlanRepo) AddExercise(ex PlannedExercise) (PlannedExercise, error) {
	return ex, r.db.Create(&ex).Error
}
```

- [ ] **Шаг 4: Рефакторить service.go**

```go
// backend/internal/plans/service.go
package plans

import "github.com/google/uuid"

type Service struct {
	repo PlanRepository
}

func NewService(repo PlanRepository) *Service { return &Service{repo: repo} }

func (s *Service) ListPlans(userID uuid.UUID) ([]WorkoutPlan, error) {
	return s.repo.ListPlans(userID)
}

func (s *Service) CreatePlan(userID uuid.UUID, name string) (WorkoutPlan, error) {
	return s.repo.CreatePlan(WorkoutPlan{UserID: userID, Name: name})
}

func (s *Service) DeletePlan(id, userID uuid.UUID) error {
	return s.repo.DeletePlan(id, userID)
}

func (s *Service) ListDays(planID uuid.UUID) ([]WorkoutDay, error) {
	return s.repo.ListDays(planID)
}

func (s *Service) CreateDay(planID uuid.UUID, dayOfWeek int) (WorkoutDay, error) {
	return s.repo.CreateDay(WorkoutDay{PlanID: planID, DayOfWeek: dayOfWeek})
}

func (s *Service) AddExercise(ex PlannedExercise) (PlannedExercise, error) {
	return s.repo.AddExercise(ex)
}
```

- [ ] **Шаг 5: Обновить main.go — строку создания planSvc**

Заменить:
```go
planSvc := plans.NewService(database)
```
На:
```go
planSvc := plans.NewService(plans.NewGormPlanRepo(database))
```

- [ ] **Шаг 6: Запустить тесты**

```bash
cd backend && go test ./internal/plans/...
```
Ожидание: все тесты проходят.

- [ ] **Шаг 7: Закоммитить**

```bash
git add backend/internal/plans/repository.go backend/internal/plans/service.go backend/internal/plans/service_test.go backend/cmd/api/main.go
git commit -m "test: plans — repository interface + service tests"
```

---

## Задача 4: пакет sessions

**Файлы:**
- Создать: `backend/internal/sessions/repository.go`
- Изменить: `backend/internal/sessions/service.go`
- Создать: `backend/internal/sessions/service_test.go`
- Изменить: `backend/cmd/api/main.go`

- [ ] **Шаг 1: Написать service_test.go**

```go
// backend/internal/sessions/service_test.go
package sessions_test

import (
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/satanlittlehelper/knurl/backend/internal/sessions"
)

type mockSessionRepo struct {
	listResult []sessions.WorkoutSession
	err        error
}

func (m *mockSessionRepo) List(_ uuid.UUID) ([]sessions.WorkoutSession, error) {
	return m.listResult, m.err
}
func (m *mockSessionRepo) Create(sess *sessions.WorkoutSession) error { return m.err }
func (m *mockSessionRepo) Finish(_, _ uuid.UUID, _ time.Time) error   { return m.err }
func (m *mockSessionRepo) Delete(_, _ uuid.UUID) error                 { return m.err }

func TestList_Success(t *testing.T) {
	userID := uuid.New()
	want := []sessions.WorkoutSession{{UserID: userID, StartedAt: time.Now()}}
	svc := sessions.NewService(&mockSessionRepo{listResult: want})
	got, err := svc.List(userID)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(got) != 1 {
		t.Fatalf("expected 1 session, got %d", len(got))
	}
}

func TestList_RepoError(t *testing.T) {
	svc := sessions.NewService(&mockSessionRepo{err: errors.New("db error")})
	_, err := svc.List(uuid.New())
	if err == nil {
		t.Fatal("expected error")
	}
}

func TestCreate_Success_UserIDAssigned(t *testing.T) {
	userID := uuid.New()
	svc := sessions.NewService(&mockSessionRepo{})
	sess := sessions.WorkoutSession{StartedAt: time.Now()}
	got, err := svc.Create(userID, sess)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got.UserID != userID {
		t.Fatalf("expected userID %s, got %s", userID, got.UserID)
	}
}

func TestCreate_RepoError(t *testing.T) {
	svc := sessions.NewService(&mockSessionRepo{err: errors.New("db error")})
	_, err := svc.Create(uuid.New(), sessions.WorkoutSession{})
	if err == nil {
		t.Fatal("expected error")
	}
}

func TestFinish_Success(t *testing.T) {
	svc := sessions.NewService(&mockSessionRepo{})
	if err := svc.Finish(uuid.New(), uuid.New()); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestFinish_RepoError(t *testing.T) {
	svc := sessions.NewService(&mockSessionRepo{err: errors.New("db error")})
	if err := svc.Finish(uuid.New(), uuid.New()); err == nil {
		t.Fatal("expected error")
	}
}

func TestDelete_Success(t *testing.T) {
	svc := sessions.NewService(&mockSessionRepo{})
	if err := svc.Delete(uuid.New(), uuid.New()); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestDelete_RepoError(t *testing.T) {
	svc := sessions.NewService(&mockSessionRepo{err: errors.New("db error")})
	if err := svc.Delete(uuid.New(), uuid.New()); err == nil {
		t.Fatal("expected error")
	}
}
```

- [ ] **Шаг 2: Убедиться что не компилируется**

```bash
cd backend && go build ./internal/sessions/...
```
Ожидание: ошибка — `NewService` принимает `*gorm.DB`.

- [ ] **Шаг 3: Создать repository.go**

```go
// backend/internal/sessions/repository.go
package sessions

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type SessionRepository interface {
	List(userID uuid.UUID) ([]WorkoutSession, error)
	Create(sess *WorkoutSession) error
	Finish(id, userID uuid.UUID, at time.Time) error
	Delete(id, userID uuid.UUID) error
}

type gormSessionRepo struct {
	db *gorm.DB
}

func NewGormSessionRepo(db *gorm.DB) SessionRepository {
	return &gormSessionRepo{db: db}
}

func (r *gormSessionRepo) List(userID uuid.UUID) ([]WorkoutSession, error) {
	var sessions []WorkoutSession
	return sessions, r.db.Where("user_id = ?", userID).Order("started_at DESC").Find(&sessions).Error
}

func (r *gormSessionRepo) Create(sess *WorkoutSession) error {
	return r.db.Create(sess).Error
}

func (r *gormSessionRepo) Finish(id, userID uuid.UUID, at time.Time) error {
	return r.db.Model(&WorkoutSession{}).
		Where("id = ? AND user_id = ?", id, userID).
		Update("finished_at", at).Error
}

func (r *gormSessionRepo) Delete(id, userID uuid.UUID) error {
	return r.db.Where("id = ? AND user_id = ?", id, userID).Delete(&WorkoutSession{}).Error
}
```

- [ ] **Шаг 4: Рефакторить service.go**

```go
// backend/internal/sessions/service.go
package sessions

import (
	"time"

	"github.com/google/uuid"
)

type Service struct{ repo SessionRepository }

func NewService(repo SessionRepository) *Service { return &Service{repo: repo} }

func (s *Service) List(userID uuid.UUID) ([]WorkoutSession, error) {
	return s.repo.List(userID)
}

func (s *Service) Create(userID uuid.UUID, sess WorkoutSession) (WorkoutSession, error) {
	sess.UserID = userID
	return sess, s.repo.Create(&sess)
}

func (s *Service) Finish(id, userID uuid.UUID) error {
	return s.repo.Finish(id, userID, time.Now())
}

func (s *Service) Delete(id, userID uuid.UUID) error {
	return s.repo.Delete(id, userID)
}
```

- [ ] **Шаг 5: Обновить main.go — строку создания sessionSvc**

Заменить:
```go
sessionSvc := sessions.NewService(database)
```
На:
```go
sessionSvc := sessions.NewService(sessions.NewGormSessionRepo(database))
```

- [ ] **Шаг 6: Запустить тесты**

```bash
cd backend && go test ./internal/sessions/...
```
Ожидание: все тесты проходят.

- [ ] **Шаг 7: Закоммитить**

```bash
git add backend/internal/sessions/repository.go backend/internal/sessions/service.go backend/internal/sessions/service_test.go backend/cmd/api/main.go
git commit -m "test: sessions — repository interface + service tests"
```

---

## Задача 5: пакет sets

**Файлы:**
- Создать: `backend/internal/sets/repository.go`
- Изменить: `backend/internal/sets/service.go`
- Создать: `backend/internal/sets/service_test.go`
- Изменить: `backend/cmd/api/main.go`

- [ ] **Шаг 1: Написать service_test.go**

```go
// backend/internal/sets/service_test.go
package sets_test

import (
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/satanlittlehelper/knurl/backend/internal/sets"
)

type mockSetRepo struct {
	listResult   []sets.SetLog
	findResult   sets.SetLog
	updateResult sets.SetLog
	err          error
	findErr      error
}

func (m *mockSetRepo) List(_ uuid.UUID) ([]sets.SetLog, error) {
	return m.listResult, m.err
}
func (m *mockSetRepo) Create(log *sets.SetLog) error { return m.err }
func (m *mockSetRepo) FindByID(_ uuid.UUID) (sets.SetLog, error) {
	return m.findResult, m.findErr
}
func (m *mockSetRepo) Update(_ sets.SetLog, _ sets.SetLog) (sets.SetLog, error) {
	return m.updateResult, m.err
}
func (m *mockSetRepo) Delete(_ uuid.UUID) error { return m.err }

func TestList_Success(t *testing.T) {
	sessionID := uuid.New()
	want := []sets.SetLog{{SessionID: sessionID, ExerciseID: "squat", SetNumber: 1, Reps: 10, CompletedAt: time.Now()}}
	svc := sets.NewService(&mockSetRepo{listResult: want})
	got, err := svc.List(sessionID)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(got) != 1 {
		t.Fatalf("expected 1 set, got %d", len(got))
	}
}

func TestList_RepoError(t *testing.T) {
	svc := sets.NewService(&mockSetRepo{err: errors.New("db error")})
	_, err := svc.List(uuid.New())
	if err == nil {
		t.Fatal("expected error")
	}
}

func TestCreate_Success_SessionIDAssigned(t *testing.T) {
	sessionID := uuid.New()
	svc := sets.NewService(&mockSetRepo{})
	log := sets.SetLog{ExerciseID: "squat", SetNumber: 1, Reps: 10, CompletedAt: time.Now()}
	got, err := svc.Create(sessionID, log)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got.SessionID != sessionID {
		t.Fatalf("expected sessionID %s, got %s", sessionID, got.SessionID)
	}
}

func TestCreate_RepoError(t *testing.T) {
	svc := sets.NewService(&mockSetRepo{err: errors.New("db error")})
	_, err := svc.Create(uuid.New(), sets.SetLog{})
	if err == nil {
		t.Fatal("expected error")
	}
}

func TestUpdate_Success(t *testing.T) {
	id := uuid.New()
	existing := sets.SetLog{ID: id, ExerciseID: "squat", SetNumber: 1, Reps: 8, CompletedAt: time.Now()}
	updated := sets.SetLog{ID: id, ExerciseID: "squat", SetNumber: 1, Reps: 10, CompletedAt: time.Now()}
	svc := sets.NewService(&mockSetRepo{findResult: existing, updateResult: updated})
	got, err := svc.Update(id, sets.SetLog{Reps: 10})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got.Reps != 10 {
		t.Fatalf("expected 10 reps, got %d", got.Reps)
	}
}

func TestUpdate_FindByIDError(t *testing.T) {
	svc := sets.NewService(&mockSetRepo{findErr: errors.New("not found")})
	_, err := svc.Update(uuid.New(), sets.SetLog{})
	if err == nil {
		t.Fatal("expected error")
	}
}

func TestUpdate_UpdateError(t *testing.T) {
	existing := sets.SetLog{ID: uuid.New(), CompletedAt: time.Now()}
	svc := sets.NewService(&mockSetRepo{findResult: existing, err: errors.New("db error")})
	_, err := svc.Update(existing.ID, sets.SetLog{Reps: 5})
	if err == nil {
		t.Fatal("expected error")
	}
}

func TestDelete_Success(t *testing.T) {
	svc := sets.NewService(&mockSetRepo{})
	if err := svc.Delete(uuid.New()); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestDelete_RepoError(t *testing.T) {
	svc := sets.NewService(&mockSetRepo{err: errors.New("db error")})
	if err := svc.Delete(uuid.New()); err == nil {
		t.Fatal("expected error")
	}
}
```

- [ ] **Шаг 2: Убедиться что не компилируется**

```bash
cd backend && go build ./internal/sets/...
```
Ожидание: ошибка — `NewService` принимает `*gorm.DB`.

- [ ] **Шаг 3: Создать repository.go**

```go
// backend/internal/sets/repository.go
package sets

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type SetRepository interface {
	List(sessionID uuid.UUID) ([]SetLog, error)
	Create(log *SetLog) error
	FindByID(id uuid.UUID) (SetLog, error)
	Update(existing SetLog, patch SetLog) (SetLog, error)
	Delete(id uuid.UUID) error
}

type gormSetRepo struct {
	db *gorm.DB
}

func NewGormSetRepo(db *gorm.DB) SetRepository {
	return &gormSetRepo{db: db}
}

func (r *gormSetRepo) List(sessionID uuid.UUID) ([]SetLog, error) {
	var logs []SetLog
	return logs, r.db.Where("session_id = ?", sessionID).Order("completed_at").Find(&logs).Error
}

func (r *gormSetRepo) Create(log *SetLog) error {
	return r.db.Create(log).Error
}

func (r *gormSetRepo) FindByID(id uuid.UUID) (SetLog, error) {
	var log SetLog
	return log, r.db.First(&log, "id = ?", id).Error
}

func (r *gormSetRepo) Update(existing SetLog, patch SetLog) (SetLog, error) {
	result := r.db.Model(&existing).Updates(patch)
	return existing, result.Error
}

func (r *gormSetRepo) Delete(id uuid.UUID) error {
	return r.db.Where("id = ?", id).Delete(&SetLog{}).Error
}
```

- [ ] **Шаг 4: Рефакторить service.go**

```go
// backend/internal/sets/service.go
package sets

import "github.com/google/uuid"

type Service struct{ repo SetRepository }

func NewService(repo SetRepository) *Service { return &Service{repo: repo} }

func (s *Service) List(sessionID uuid.UUID) ([]SetLog, error) {
	return s.repo.List(sessionID)
}

func (s *Service) Create(sessionID uuid.UUID, log SetLog) (SetLog, error) {
	log.SessionID = sessionID
	return log, s.repo.Create(&log)
}

func (s *Service) Update(id uuid.UUID, patch SetLog) (SetLog, error) {
	existing, err := s.repo.FindByID(id)
	if err != nil {
		return SetLog{}, err
	}
	patch.ID = id
	return s.repo.Update(existing, patch)
}

func (s *Service) Delete(id uuid.UUID) error {
	return s.repo.Delete(id)
}
```

- [ ] **Шаг 5: Обновить main.go — строку создания setSvc**

Заменить:
```go
setSvc := sets.NewService(database)
```
На:
```go
setSvc := sets.NewService(sets.NewGormSetRepo(database))
```

- [ ] **Шаг 6: Запустить все тесты проекта**

```bash
cd backend && go test ./...
```
Ожидание: все пакеты проходят (`ok` для `api`, `auth`, `exercises`, `plans`, `sessions`, `sets`).

- [ ] **Шаг 7: Закоммитить**

```bash
git add backend/internal/sets/repository.go backend/internal/sets/service.go backend/internal/sets/service_test.go backend/cmd/api/main.go
git commit -m "test: sets — repository interface + service tests"
```
