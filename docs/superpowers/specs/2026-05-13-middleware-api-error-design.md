# Design: Унификация ошибок в auth/middleware.go

## Цель

Привести `auth/middleware.go` в соответствие с остальными хендлерами — заменить `http.Error` на `api.Error`, чтобы 401-ответы возвращали JSON вместо plain-text.

## Изменения

### `internal/auth/middleware.go`

Заменить все 4 вызова:
```go
http.Error(w, "unauthorized", http.StatusUnauthorized)
```
на:
```go
api.Error(w, http.StatusUnauthorized, "unauthorized")
```

Добавить импорт `github.com/satanlittlehelper/knurl/backend/internal/api`.

## Границы

- `UserIDFromCtx` и вся логика JWT не меняются.
- Текст ошибки `"unauthorized"` остаётся тем же.
- Только формат ответа меняется: `text/plain` → `{"error": "unauthorized"}`.
