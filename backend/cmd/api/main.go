package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/joho/godotenv"
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

	_ = database

	r := chi.NewRouter()
	r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})

	addr := fmt.Sprintf(":%s", cfg.Port)
	log.Printf("server started on %s", addr)
	log.Fatal(http.ListenAndServe(addr, r))
}
