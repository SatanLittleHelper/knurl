# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Working with git

Never use `cd` before git commands. Never use `-C` flag with git. Just run `git status`, `git add .`, `git commit`, etc. directly — git finds the repo on its own.

## Commands

All commands run from the `backend/` directory.

```bash
# Run the server
make run

# Run all tests
go test ./...

# Run a single test file or package
go test ./internal/auth/...

# Run a specific test by name
go test ./internal/auth/... -run TestMiddleware

# Run tests with coverage
go test -coverprofile=coverage.out ./...

# Apply database migrations (requires DATABASE_URL env var)
make migrate-up

# Roll back last migration
make migrate-down
```

## Environment Setup

Copy `.env.example` to `.env` before running:
```
DATABASE_URL=postgres://postgres:postgres@localhost:5432/knurl?sslmode=disable
JWT_SECRET=change-me-in-production
PORT=8080
```

Start Postgres with Docker:
```bash
docker compose up -d
```

## Architecture

**Stack:** Go, chi router, GORM (PostgreSQL), JWT auth (HS256), goose migrations.

**Module path:** `github.com/satanlittlehelper/knurl/backend`

**Layer structure per domain package** (`internal/<domain>/`):
- `models.go` — GORM structs with `uuid` PKs and soft-delete via `gorm.DeletedAt`
- `service.go` — business logic, talks directly to `*gorm.DB`
- `handler.go` — HTTP layer, decodes requests, calls service, uses `api.Respond`/`api.Error`

**Shared utilities** (`internal/api/`):
- `api.Respond(w, status, v)` — JSON encode with Content-Type header
- `api.Error(w, status, message)` — `{"error": "..."}` response
- `api.NoContent(w)` — 204 with no body

All handlers must use these helpers — never write raw `json.NewEncoder` or `w.WriteHeader` in handlers.

**Auth flow:**
- `POST /auth/register` and `POST /auth/login` issue JWT tokens (30-day expiry)
- `auth.Middleware(jwtSecret)` validates Bearer tokens and injects `uuid.UUID` into context
- `auth.UserIDFromCtx(ctx)` extracts the user ID inside protected handlers

**Exercises domain** uses an `ExerciseProvider` interface with an in-memory 24-hour cache. Currently backed by `StubProvider`; swap with a real provider implementing `FetchAll(ctx) ([]Exercise, error)`.

**Database migrations** live in `internal/db/migrations/` and are managed via goose (`*.sql` files, numbered sequentially).

**All protected routes** share a single chi group with `auth.Middleware` applied. New protected routes go inside that group in `cmd/api/main.go`.
