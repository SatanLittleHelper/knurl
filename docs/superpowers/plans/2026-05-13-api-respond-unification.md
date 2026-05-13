# API Respond Unification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Унифицировать все HTTP-ответы во всех хендлерах через три функции пакета `api`: `Respond`, `Error`, `NoContent`.

**Architecture:** Пакет `internal/api` предоставляет три функции-помощника. Все хендлеры импортируют только этот пакет для формирования ответов — никаких прямых вызовов `json.NewEncoder`, `http.Error`, или `w.WriteHeader` с телом.

**Tech Stack:** Go 1.25, `net/http`, `encoding/json`, `net/http/httptest` (для тестов)

---

## File Map

| Файл | Действие |
|---|---|
| `internal/api/respond.go` | Modify: обновить `Respond`, добавить `Error` и `NoContent` |
| `internal/api/respond_test.go` | Create: юнит-тесты для всех трёх функций |
| `internal/plans/handler.go` | Modify: обновить вызовы `api.Respond` (добавить статус), заменить `http.Error` на `api.Error`, `w.WriteHeader(204)` на `api.NoContent` |
| `internal/auth/handler.go` | Modify: убрать `writeError`, заменить ручной encode на `api.Respond`/`api.Error` |
| `internal/sessions/handler.go` | Modify: заменить ручной encode на `api.Respond`/`api.Error`/`api.NoContent` |
| `internal/exercises/handler.go` | Modify: заменить ручной encode на `api.Respond`/`api.Error` |
| `internal/sets/handler.go` | Modify: заменить ручной encode на `api.Respond`/`api.Error`/`api.NoContent` |

---

### Task 1: Обновить `api/respond.go` и добавить тесты

**Files:**
- Modify: `internal/api/respond.go`
- Create: `internal/api/respond_test.go`

- [ ] **Step 1: Написать failing тесты**

Создать файл `internal/api/respond_test.go`:

```go
package api_test

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/satanlittlehelper/knurl/backend/internal/api"
)

func TestRespond_SetsStatusAndBody(t *testing.T) {
	w := httptest.NewRecorder()
	api.Respond(w, http.StatusOK, map[string]string{"key": "value"})

	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", w.Code)
	}
	if ct := w.Header().Get("Content-Type"); ct != "application/json" {
		t.Fatalf("expected application/json, got %s", ct)
	}
	body := strings.TrimSpace(w.Body.String())
	if body != `{"key":"value"}` {
		t.Fatalf("unexpected body: %s", body)
	}
}

func TestRespond_Created(t *testing.T) {
	w := httptest.NewRecorder()
	api.Respond(w, http.StatusCreated, map[string]string{"id": "1"})

	if w.Code != http.StatusCreated {
		t.Fatalf("expected 201, got %d", w.Code)
	}
}

func TestError_SetsStatusAndErrorBody(t *testing.T) {
	w := httptest.NewRecorder()
	api.Error(w, http.StatusBadRequest, "bad request")

	if w.Code != http.StatusBadRequest {
		t.Fatalf("expected 400, got %d", w.Code)
	}
	if ct := w.Header().Get("Content-Type"); ct != "application/json" {
		t.Fatalf("expected application/json, got %s", ct)
	}
	body := strings.TrimSpace(w.Body.String())
	if body != `{"error":"bad request"}` {
		t.Fatalf("unexpected body: %s", body)
	}
}

func TestNoContent_Returns204WithEmptyBody(t *testing.T) {
	w := httptest.NewRecorder()
	api.NoContent(w)

	if w.Code != http.StatusNoContent {
		t.Fatalf("expected 204, got %d", w.Code)
	}
	if w.Body.Len() != 0 {
		t.Fatalf("expected empty body, got: %s", w.Body.String())
	}
}
```

- [ ] **Step 2: Запустить тесты — убедиться, что падают**

```bash
cd backend && go test ./internal/api/...
```

Ожидаемый результат: `FAIL` — функции с новыми сигнатурами ещё не существуют.

- [ ] **Step 3: Обновить `internal/api/respond.go`**

```go
package api

import (
	"encoding/json"
	"net/http"
)

func Respond(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(v) //nolint:errcheck
}

func Error(w http.ResponseWriter, status int, message string) {
	Respond(w, status, map[string]string{"error": message})
}

func NoContent(w http.ResponseWriter) {
	w.WriteHeader(http.StatusNoContent)
}
```

- [ ] **Step 4: Запустить тесты — убедиться, что проходят**

```bash
cd backend && go test ./internal/api/...
```

Ожидаемый результат: `ok  github.com/satanlittlehelper/knurl/backend/internal/api`

- [ ] **Step 5: Закоммитить**

```bash
git add backend/internal/api/respond.go backend/internal/api/respond_test.go
git commit -m "feat: add Error and NoContent to api package, add status param to Respond"
```

---

### Task 2: Обновить `plans/handler.go`

**Files:**
- Modify: `internal/plans/handler.go`

`plans` уже использует `api.Respond`, но со старой сигнатурой (без статуса). Нужно добавить статус во все вызовы, заменить `http.Error` на `api.Error`, `w.WriteHeader(204)` на `api.NoContent`.

- [ ] **Step 1: Проверить, что проект не собирается (из-за изменения сигнатуры)**

```bash
cd backend && go build ./...
```

Ожидаемый результат: ошибки компиляции на `api.Respond(w, plans)` — слишком мало аргументов.

- [ ] **Step 2: Заменить содержимое `internal/plans/handler.go`**

```go
package plans

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/satanlittlehelper/knurl/backend/internal/api"
	"github.com/satanlittlehelper/knurl/backend/internal/auth"
)

type Handler struct{ svc *Service }

func NewHandler(svc *Service) *Handler { return &Handler{svc: svc} }

func (h *Handler) ListPlans(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromCtx(r.Context())
	plans, err := h.svc.ListPlans(userID)
	if err != nil {
		api.Error(w, http.StatusInternalServerError, "internal error")
		return
	}
	api.Respond(w, http.StatusOK, plans)
}

func (h *Handler) CreatePlan(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromCtx(r.Context())
	var body struct {
		Name string `json:"name"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Name == "" {
		api.Error(w, http.StatusBadRequest, "name required")
		return
	}
	plan, err := h.svc.CreatePlan(userID, body.Name)
	if err != nil {
		api.Error(w, http.StatusInternalServerError, "internal error")
		return
	}
	api.Respond(w, http.StatusCreated, plan)
}

func (h *Handler) DeletePlan(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromCtx(r.Context())
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		api.Error(w, http.StatusBadRequest, "invalid id")
		return
	}
	if err := h.svc.DeletePlan(id, userID); err != nil {
		api.Error(w, http.StatusInternalServerError, "internal error")
		return
	}
	api.NoContent(w)
}

func (h *Handler) ListDays(w http.ResponseWriter, r *http.Request) {
	planID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		api.Error(w, http.StatusBadRequest, "invalid id")
		return
	}
	days, err := h.svc.ListDays(planID)
	if err != nil {
		api.Error(w, http.StatusInternalServerError, "internal error")
		return
	}
	api.Respond(w, http.StatusOK, days)
}

func (h *Handler) CreateDay(w http.ResponseWriter, r *http.Request) {
	planID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		api.Error(w, http.StatusBadRequest, "invalid id")
		return
	}
	var body struct {
		DayOfWeek int `json:"day_of_week"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		api.Error(w, http.StatusBadRequest, "bad request")
		return
	}
	day, err := h.svc.CreateDay(planID, body.DayOfWeek)
	if err != nil {
		api.Error(w, http.StatusInternalServerError, "internal error")
		return
	}
	api.Respond(w, http.StatusCreated, day)
}

func (h *Handler) AddExercise(w http.ResponseWriter, r *http.Request) {
	dayID, err := uuid.Parse(chi.URLParam(r, "dayId"))
	if err != nil {
		api.Error(w, http.StatusBadRequest, "invalid day id")
		return
	}
	var body PlannedExercise
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		api.Error(w, http.StatusBadRequest, "bad request")
		return
	}
	body.DayID = dayID
	ex, err := h.svc.AddExercise(body)
	if err != nil {
		api.Error(w, http.StatusInternalServerError, "internal error")
		return
	}
	api.Respond(w, http.StatusCreated, ex)
}
```

- [ ] **Step 3: Убедиться, что plans компилируется**

```bash
cd backend && go build ./internal/plans/...
```

Ожидаемый результат: успешная компиляция.

- [ ] **Step 4: Закоммитить**

```bash
git add backend/internal/plans/handler.go
git commit -m "feat: use api.Respond/Error/NoContent in plans handler"
```

---

### Task 3: Обновить `auth/handler.go`

**Files:**
- Modify: `internal/auth/handler.go`

Убрать локальную `writeError`, заменить всё на `api.Respond` и `api.Error`.

- [ ] **Step 1: Заменить содержимое `internal/auth/handler.go`**

```go
package auth

import (
	"encoding/json"
	"errors"
	"io"
	"log"
	"net/http"
	"strings"

	"github.com/satanlittlehelper/knurl/backend/internal/api"
)

type Handler struct {
	svc *Service
}

func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

type authRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

func (h *Handler) Register(w http.ResponseWriter, r *http.Request) {
	var req authRequest
	if err := json.NewDecoder(io.LimitReader(r.Body, 1024)).Decode(&req); err != nil {
		api.Error(w, http.StatusBadRequest, "bad request")
		return
	}
	req.Email = strings.TrimSpace(req.Email)
	if req.Email == "" || req.Password == "" {
		api.Error(w, http.StatusBadRequest, "email and password required")
		return
	}

	token, err := h.svc.Register(r.Context(), req.Email, req.Password)
	if errors.Is(err, ErrEmailTaken) {
		api.Error(w, http.StatusConflict, "email already taken")
		return
	}
	if err != nil {
		log.Printf("register: %v", err)
		api.Error(w, http.StatusInternalServerError, "internal error")
		return
	}

	api.Respond(w, http.StatusCreated, map[string]string{"token": token})
}

func (h *Handler) Login(w http.ResponseWriter, r *http.Request) {
	var req authRequest
	if err := json.NewDecoder(io.LimitReader(r.Body, 1024)).Decode(&req); err != nil {
		api.Error(w, http.StatusBadRequest, "bad request")
		return
	}
	req.Email = strings.TrimSpace(req.Email)

	token, err := h.svc.Login(r.Context(), req.Email, req.Password)
	if errors.Is(err, ErrInvalidCredentials) {
		api.Error(w, http.StatusUnauthorized, "invalid credentials")
		return
	}
	if err != nil {
		log.Printf("login: %v", err)
		api.Error(w, http.StatusInternalServerError, "internal error")
		return
	}

	api.Respond(w, http.StatusOK, map[string]string{"token": token})
}
```

- [ ] **Step 2: Убедиться, что auth компилируется**

```bash
cd backend && go build ./internal/auth/...
```

Ожидаемый результат: успешная компиляция.

- [ ] **Step 3: Закоммитить**

```bash
git add backend/internal/auth/handler.go
git commit -m "feat: use api.Respond/Error in auth handler, remove writeError"
```

---

### Task 4: Обновить `sessions/handler.go`

**Files:**
- Modify: `internal/sessions/handler.go`

- [ ] **Step 1: Заменить содержимое `internal/sessions/handler.go`**

```go
package sessions

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/satanlittlehelper/knurl/backend/internal/api"
	"github.com/satanlittlehelper/knurl/backend/internal/auth"
)

type Handler struct{ svc *Service }

func NewHandler(svc *Service) *Handler { return &Handler{svc: svc} }

func (h *Handler) List(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromCtx(r.Context())
	sessions, err := h.svc.List(userID)
	if err != nil {
		api.Error(w, http.StatusInternalServerError, "internal error")
		return
	}
	api.Respond(w, http.StatusOK, sessions)
}

func (h *Handler) Create(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromCtx(r.Context())
	var body WorkoutSession
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		api.Error(w, http.StatusBadRequest, "bad request")
		return
	}
	sess, err := h.svc.Create(userID, body)
	if err != nil {
		api.Error(w, http.StatusInternalServerError, "internal error")
		return
	}
	api.Respond(w, http.StatusCreated, sess)
}

func (h *Handler) Finish(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromCtx(r.Context())
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		api.Error(w, http.StatusBadRequest, "invalid id")
		return
	}
	if err := h.svc.Finish(id, userID); err != nil {
		api.Error(w, http.StatusInternalServerError, "internal error")
		return
	}
	api.NoContent(w)
}

func (h *Handler) Delete(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromCtx(r.Context())
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		api.Error(w, http.StatusBadRequest, "invalid id")
		return
	}
	if err := h.svc.Delete(id, userID); err != nil {
		api.Error(w, http.StatusInternalServerError, "internal error")
		return
	}
	api.NoContent(w)
}
```

- [ ] **Step 2: Убедиться, что sessions компилируется**

```bash
cd backend && go build ./internal/sessions/...
```

Ожидаемый результат: успешная компиляция.

- [ ] **Step 3: Закоммитить**

```bash
git add backend/internal/sessions/handler.go
git commit -m "feat: use api.Respond/Error/NoContent in sessions handler"
```

---

### Task 5: Обновить `exercises/handler.go`

**Files:**
- Modify: `internal/exercises/handler.go`

- [ ] **Step 1: Заменить содержимое `internal/exercises/handler.go`**

```go
package exercises

import (
	"net/http"

	"github.com/satanlittlehelper/knurl/backend/internal/api"
)

type Handler struct {
	svc *Service
}

func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

func (h *Handler) List(w http.ResponseWriter, r *http.Request) {
	muscle := r.URL.Query().Get("muscle")
	exercises, err := h.svc.List(r.Context(), muscle)
	if err != nil {
		api.Error(w, http.StatusInternalServerError, "internal error")
		return
	}
	api.Respond(w, http.StatusOK, exercises)
}
```

- [ ] **Step 2: Убедиться, что exercises компилируется**

```bash
cd backend && go build ./internal/exercises/...
```

Ожидаемый результат: успешная компиляция.

- [ ] **Step 3: Закоммитить**

```bash
git add backend/internal/exercises/handler.go
git commit -m "feat: use api.Respond/Error in exercises handler"
```

---

### Task 6: Обновить `sets/handler.go`

**Files:**
- Modify: `internal/sets/handler.go`

- [ ] **Step 1: Заменить содержимое `internal/sets/handler.go`**

```go
package sets

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/satanlittlehelper/knurl/backend/internal/api"
)

type Handler struct{ svc *Service }

func NewHandler(svc *Service) *Handler { return &Handler{svc: svc} }

func (h *Handler) List(w http.ResponseWriter, r *http.Request) {
	sessionID, err := uuid.Parse(chi.URLParam(r, "sessionId"))
	if err != nil {
		api.Error(w, http.StatusBadRequest, "invalid session id")
		return
	}
	logs, err := h.svc.List(sessionID)
	if err != nil {
		api.Error(w, http.StatusInternalServerError, "internal error")
		return
	}
	api.Respond(w, http.StatusOK, logs)
}

func (h *Handler) Create(w http.ResponseWriter, r *http.Request) {
	sessionID, err := uuid.Parse(chi.URLParam(r, "sessionId"))
	if err != nil {
		api.Error(w, http.StatusBadRequest, "invalid session id")
		return
	}
	var body SetLog
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		api.Error(w, http.StatusBadRequest, "bad request")
		return
	}
	log, err := h.svc.Create(sessionID, body)
	if err != nil {
		api.Error(w, http.StatusInternalServerError, "internal error")
		return
	}
	api.Respond(w, http.StatusCreated, log)
}

func (h *Handler) Update(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		api.Error(w, http.StatusBadRequest, "invalid id")
		return
	}
	var patch SetLog
	if err := json.NewDecoder(r.Body).Decode(&patch); err != nil {
		api.Error(w, http.StatusBadRequest, "bad request")
		return
	}
	log, err := h.svc.Update(id, patch)
	if err != nil {
		api.Error(w, http.StatusInternalServerError, "internal error")
		return
	}
	api.Respond(w, http.StatusOK, log)
}

func (h *Handler) Delete(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		api.Error(w, http.StatusBadRequest, "invalid id")
		return
	}
	if err := h.svc.Delete(id); err != nil {
		api.Error(w, http.StatusInternalServerError, "internal error")
		return
	}
	api.NoContent(w)
}
```

- [ ] **Step 2: Убедиться, что sets компилируется**

```bash
cd backend && go build ./internal/sets/...
```

Ожидаемый результат: успешная компиляция.

- [ ] **Step 3: Закоммитить**

```bash
git add backend/internal/sets/handler.go
git commit -m "feat: use api.Respond/Error/NoContent in sets handler"
```

---

### Task 7: Финальная проверка

- [ ] **Step 1: Полная сборка проекта**

```bash
cd backend && go build ./...
```

Ожидаемый результат: никаких ошибок.

- [ ] **Step 2: Все тесты проходят**

```bash
cd backend && go test ./...
```

Ожидаемый результат: `ok  github.com/satanlittlehelper/knurl/backend/internal/api`

- [ ] **Step 3: Убедиться, что нет прямых вызовов старых паттернов**

```bash
cd backend && grep -rn "json.NewEncoder\|w\.Header()\.Set.*application/json" internal/
```

Ожидаемый результат: пустой вывод — все паттерны заменены.
