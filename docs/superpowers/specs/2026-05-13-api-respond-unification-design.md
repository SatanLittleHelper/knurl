# Design: Унификация ответов через api.Respond

## Цель

Убрать дублирование ручной JSON-сериализации по всем хендлерам. Использовать единый пакет `api` для всех HTTP-ответов — успешных, ошибочных и пустых.

## Изменения

### `internal/api/respond.go`

Три функции:

```go
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

### Хендлеры

Все ответы идут через `api`:

```go
// Успешные ответы с телом
api.Respond(w, http.StatusOK, data)
api.Respond(w, http.StatusCreated, data)

// Ошибки
api.Error(w, http.StatusBadRequest, "bad request")
api.Error(w, http.StatusInternalServerError, "internal error")

// Пустые ответы (delete, finish)
api.NoContent(w)
```

Затронутые файлы:
- `internal/api/respond.go` — добавить `Error` и `NoContent`, обновить `Respond`
- `internal/auth/handler.go` — убрать `writeError`, Register (201), Login (200), ошибки через `api.Error`
- `internal/sessions/handler.go` — List (200), Create (201), Finish/Delete через `api.NoContent`, ошибки через `api.Error`
- `internal/exercises/handler.go` — List (200), ошибки через `api.Error`
- `internal/sets/handler.go` — List (200), Create (201), Update (200), Delete через `api.NoContent`, ошибки через `api.Error`
- `internal/plans/handler.go` — обновить под новую сигнатуру, DeletePlan через `api.NoContent`, ошибки через `api.Error`

## Границы

- `writeError` в `auth/handler.go` — удалить полностью.
- Неиспользуемые импорты (`encoding/json`, `net/http` где заменяется) — удалить.
