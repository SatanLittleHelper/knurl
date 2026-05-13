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
	"github.com/satanlittlehelper/knurl/backend/internal/exercises"
	"github.com/satanlittlehelper/knurl/backend/internal/plans"
	"github.com/satanlittlehelper/knurl/backend/internal/sessions"
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

	exerciseSvc := exercises.NewService(database, exercises.StubProvider{})
	exerciseHandler := exercises.NewHandler(exerciseSvc)

	planSvc := plans.NewService(database)
	planHandler := plans.NewHandler(planSvc)

	sessionSvc := sessions.NewService(database)
	sessionHandler := sessions.NewHandler(sessionSvc)

	r := chi.NewRouter()
	r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})

	r.Post("/auth/register", authHandler.Register)
	r.Post("/auth/login", authHandler.Login)

	r.Group(func(r chi.Router) {
		r.Use(auth.Middleware(cfg.JWTSecret))
		r.Get("/exercises", exerciseHandler.List)
		r.Get("/plans", planHandler.ListPlans)
		r.Post("/plans", planHandler.CreatePlan)
		r.Delete("/plans/{id}", planHandler.DeletePlan)
		r.Get("/plans/{id}/days", planHandler.ListDays)
		r.Post("/plans/{id}/days", planHandler.CreateDay)
		r.Post("/plans/{id}/days/{dayId}/exercises", planHandler.AddExercise)
		r.Get("/sessions", sessionHandler.List)
		r.Post("/sessions", sessionHandler.Create)
		r.Patch("/sessions/{id}/finish", sessionHandler.Finish)
		r.Delete("/sessions/{id}", sessionHandler.Delete)
	})

	addr := fmt.Sprintf(":%s", cfg.Port)
	log.Printf("server started on %s", addr)
	log.Fatal(http.ListenAndServe(addr, r))
}
