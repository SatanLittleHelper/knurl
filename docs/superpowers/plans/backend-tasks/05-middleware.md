# Задача 5: Middleware авторизации

**Что строим:** Middleware проверяет JWT в заголовке `Authorization: Bearer <token>` и передаёт `userID` дальше через контекст запроса.

---

## Что такое middleware

Middleware — это функция-обёртка вокруг HTTP-обработчика. В Chi middleware применяется к группе маршрутов через `r.Use(...)`. Каждый запрос проходит через middleware перед тем как дойти до обработчика.

```
Запрос → Middleware (проверка JWT) → Handler (бизнес-логика)
                ↓ если токен невалидный
            401 Unauthorized (до Handler не доходит)
```

---

## Как userID передаётся через контекст

В Go `context.Context` — стандартный способ передавать данные вдоль цепочки вызовов. Middleware извлекает `userID` из токена и кладёт его в контекст. Handler читает `userID` из контекста.

Это позволяет handler'у получить `userID` без глобальных переменных и без изменения сигнатуры функций.

---

## Файлы

- Создать: `backend/internal/auth/middleware.go`
- Изменить: `backend/cmd/api/main.go`

---

## Шаги

- [ ] **Шаг 1: Создать `internal/auth/middleware.go`**

```go
package auth

import (
	"context"
	"net/http"
	"strings"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

// contextKey — приватный тип для ключей контекста.
// Использование приватного типа вместо string предотвращает конфликт ключей
// с другими пакетами, которые тоже могут что-то класть в контекст.
type contextKey string

const userIDKey contextKey = "userID"

// Middleware возвращает HTTP-middleware для проверки JWT.
// Принимает jwtSecret как параметр — это делает middleware переиспользуемым и тестируемым.
func Middleware(jwtSecret string) func(http.Handler) http.Handler {
	secret := []byte(jwtSecret)

	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			// Читаем заголовок Authorization
			header := r.Header.Get("Authorization")

			// Токен должен быть в формате "Bearer <token>"
			if !strings.HasPrefix(header, "Bearer ") {
				http.Error(w, "unauthorized", http.StatusUnauthorized)
				return
			}

			tokenStr := strings.TrimPrefix(header, "Bearer ")

			// jwt.Parse — разбирает и проверяет токен.
			// Функция keyFunc возвращает секрет для проверки подписи.
			// Здесь же проверяем что алгоритм подписи именно HMAC (а не например "none" — известная уязвимость JWT).
			token, err := jwt.Parse(tokenStr, func(t *jwt.Token) (any, error) {
				if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
					return nil, jwt.ErrSignatureInvalid
				}
				return secret, nil
			})
			if err != nil || !token.Valid {
				http.Error(w, "unauthorized", http.StatusUnauthorized)
				return
			}

			// Извлекаем user_id из payload токена ("sub" = subject)
			sub, err := token.Claims.GetSubject()
			if err != nil {
				http.Error(w, "unauthorized", http.StatusUnauthorized)
				return
			}

			userID, err := uuid.Parse(sub)
			if err != nil {
				http.Error(w, "unauthorized", http.StatusUnauthorized)
				return
			}

			// Кладём userID в контекст и передаём запрос дальше
			ctx := context.WithValue(r.Context(), userIDKey, userID)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// UserIDFromCtx извлекает userID из контекста.
// Возвращает (uuid, true) если userID есть, (zero, false) если нет.
// Handler'ы вызывают эту функцию чтобы узнать кто делает запрос.
func UserIDFromCtx(ctx context.Context) (uuid.UUID, bool) {
	id, ok := ctx.Value(userIDKey).(uuid.UUID)
	return id, ok
}
```

- [ ] **Шаг 2: Обновить `cmd/api/main.go` — добавить защищённую группу маршрутов**

```go
package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/joho/godotenv"
	"github.com/satanlittlehelper/knurl/backend/internal/auth"
	"github.com/satanlittlehelper/knurl/backend/internal/config"
	"github.com/satanlittlehelper/knurl/backend/internal/db"
)

func main() {
	_ = godotenv.Load()
	cfg := config.Load()

	database, err := db.Connect(cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("db connect: %v", err)
	}

	authSvc := auth.NewService(database, cfg.JWTSecret)
	authHandler := auth.NewHandler(authSvc)

	r := chi.NewRouter()
	r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})

	// Публичные маршруты — без проверки токена
	r.Post("/auth/register", authHandler.Register)
	r.Post("/auth/login", authHandler.Login)

	// Защищённая группа — все маршруты внутри требуют валидный JWT.
	// r.Group создаёт под-роутер с отдельным набором middleware.
	// auth.Middleware применяется ко всем маршрутам внутри группы.
	r.Group(func(r chi.Router) {
		r.Use(auth.Middleware(cfg.JWTSecret))

		// Защищённые маршруты будут добавляться здесь в следующих задачах
	})

	addr := fmt.Sprintf(":%s", cfg.Port)
	log.Printf("server started on %s", addr)
	log.Fatal(http.ListenAndServe(addr, r))
}
```

- [ ] **Шаг 3: Проверить что незащищённый запрос отклоняется**

```bash
curl -s http://localhost:8080/exercises -w "\nHTTP %{http_code}\n"
```

Ожидаемо: `HTTP 404` (маршрут `/exercises` ещё не создан — это нормально, главное не 401 от middleware публичных маршрутов).

После добавления защищённых маршрутов в следующих задачах — проверим что без токена возвращается `401`.
