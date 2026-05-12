.PHONY: run migrate-up migrate-down

run:
	go run ./cmd/api

migrate-up:
	go run github.com/pressly/goose/v3/cmd/goose -dir internal/db/migrations postgres "$(DATABASE_URL)" up

migrate-down:
	go run github.com/pressly/goose/v3/cmd/goose -dir internal/db/migrations postgres "$(DATABASE_URL)" down
