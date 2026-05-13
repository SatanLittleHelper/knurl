# Middleware api.Error Unification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Заменить все `http.Error` в `auth/middleware.go` на `api.Error`, чтобы 401-ответы middleware возвращали JSON вместо plain-text.

**Architecture:** Одно изменение в одном файле. `api.Error` уже существует в пакете `internal/api` (добавлен в PR #1). Middleware получает импорт этого пакета и все 4 вызова `http.Error` заменяются на `api.Error`.

**Tech Stack:** Go 1.25, `net/http`, `net/http/httptest`, `github.com/golang-jwt/jwt/v5`

**Prerequisite:** Эта ветка должна базироваться на `feature/api-respond-unification` (или `main` после мёржа PR #1), где уже существует `api.Error`.

---

## File Map

| Файл | Действие |
|---|---|
| `internal/auth/middleware.go` | Modify: заменить 4 `http.Error` на `api.Error`, добавить импорт `api` |
| `internal/auth/middleware_test.go` | Create: тесты, проверяющие JSON-формат 401-ответов |

---

### Task 1: Написать failing тесты для middleware

**Files:**
- Create: `internal/auth/middleware_test.go`

- [ ] **Step 1: Создать файл `internal/auth/middleware_test.go`**

```go
package auth_test

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/satanlittlehelper/knurl/backend/internal/auth"
)

const testSecret = "test-secret"

func makeToken(subject string, secret string, valid bool) string {
	claims := jwt.RegisteredClaims{
		Subject:   subject,
		ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Hour)),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	signingKey := []byte(secret)
	if !valid {
		signingKey = []byte("wrong-secret")
	}
	signed, _ := token.SignedString(signingKey)
	return signed
}

func assertJSONUnauthorized(t *testing.T, w *httptest.ResponseRecorder) {
	t.Helper()
	if w.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d", w.Code)
	}
	if ct := w.Header().Get("Content-Type"); ct != "application/json" {
		t.Fatalf("expected Content-Type application/json, got %s", ct)
	}
	body := strings.TrimSpace(w.Body.String())
	if body != `{"error":"unauthorized"}` {
		t.Fatalf("unexpected body: %s", body)
	}
}

func nextHandler() http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})
}

func TestMiddleware_MissingAuthorizationHeader(t *testing.T) {
	handler := auth.Middleware(testSecret)(nextHandler())
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	w := httptest.NewRecorder()
	handler.ServeHTTP(w, req)
	assertJSONUnauthorized(t, w)
}

func TestMiddleware_NoBearerPrefix(t *testing.T) {
	handler := auth.Middleware(testSecret)(nextHandler())
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req.Header.Set("Authorization", "Basic abc123")
	w := httptest.NewRecorder()
	handler.ServeHTTP(w, req)
	assertJSONUnauthorized(t, w)
}

func TestMiddleware_InvalidToken(t *testing.T) {
	handler := auth.Middleware(testSecret)(nextHandler())
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req.Header.Set("Authorization", "Bearer "+makeToken("user-id", testSecret, false))
	w := httptest.NewRecorder()
	handler.ServeHTTP(w, req)
	assertJSONUnauthorized(t, w)
}

func TestMiddleware_SubjectNotUUID(t *testing.T) {
	claims := jwt.RegisteredClaims{
		Subject:   "not-a-uuid",
		ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Hour)),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	signed, _ := token.SignedString([]byte(testSecret))

	handler := auth.Middleware(testSecret)(nextHandler())
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req.Header.Set("Authorization", "Bearer "+signed)
	w := httptest.NewRecorder()
	handler.ServeHTTP(w, req)
	assertJSONUnauthorized(t, w)
}

func TestMiddleware_ValidToken_PassesThrough(t *testing.T) {
	userID := "550e8400-e29b-41d4-a716-446655440000"
	handler := auth.Middleware(testSecret)(nextHandler())
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req.Header.Set("Authorization", "Bearer "+makeToken(userID, testSecret, true))
	w := httptest.NewRecorder()
	handler.ServeHTTP(w, req)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", w.Code)
	}
}
```

- [ ] **Step 2: Запустить тесты — убедиться, что падают**

```bash
go -C backend test ./internal/auth/...
```

Ожидаемый результат: тесты `TestMiddleware_*` падают — middleware возвращает `text/plain`, а не `application/json`.

---

### Task 2: Обновить `middleware.go` и убедиться, что тесты проходят

**Files:**
- Modify: `internal/auth/middleware.go`

- [ ] **Step 1: Заменить содержимое `internal/auth/middleware.go`**

```go
package auth

import (
	"context"
	"net/http"
	"strings"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/satanlittlehelper/knurl/backend/internal/api"
)

type contextKey string

const userIDKey contextKey = "userID"

func Middleware(jwtSecret string) func(http.Handler) http.Handler {
	secret := []byte(jwtSecret)

	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			header := r.Header.Get("Authorization")

			if !strings.HasPrefix(header, "Bearer ") {
				api.Error(w, http.StatusUnauthorized, "unauthorized")
				return
			}

			tokenStr := strings.TrimPrefix(header, "Bearer ")

			token, err := jwt.Parse(tokenStr, func(t *jwt.Token) (any, error) {
				if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
					return nil, jwt.ErrSignatureInvalid
				}
				return secret, nil
			})
			if err != nil || !token.Valid {
				api.Error(w, http.StatusUnauthorized, "unauthorized")
				return
			}

			sub, err := token.Claims.GetSubject()
			if err != nil {
				api.Error(w, http.StatusUnauthorized, "unauthorized")
				return
			}

			userID, err := uuid.Parse(sub)
			if err != nil {
				api.Error(w, http.StatusUnauthorized, "unauthorized")
				return
			}

			ctx := context.WithValue(r.Context(), userIDKey, userID)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

func UserIDFromCtx(ctx context.Context) (uuid.UUID, bool) {
	id, ok := ctx.Value(userIDKey).(uuid.UUID)
	return id, ok
}
```

- [ ] **Step 2: Запустить тесты — убедиться, что проходят**

```bash
go -C backend test ./internal/auth/...
```

Ожидаемый результат:
```
ok  github.com/satanlittlehelper/knurl/backend/internal/auth
```

- [ ] **Step 3: Полная сборка**

```bash
go -C backend build ./...
```

Ожидаемый результат: успешная компиляция без ошибок.

- [ ] **Step 4: Закоммитить**

```bash
git add backend/internal/auth/middleware.go backend/internal/auth/middleware_test.go
git commit -m "feat: use api.Error in auth middleware, add middleware tests"
```
