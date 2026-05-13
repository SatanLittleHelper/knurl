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
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	api.Respond(w, plans)
}

func (h *Handler) CreatePlan(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromCtx(r.Context())
	var body struct {
		Name string `json:"name"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil || body.Name == "" {
		http.Error(w, "name required", http.StatusBadRequest)
		return
	}
	plan, err := h.svc.CreatePlan(userID, body.Name)
	if err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusCreated)
	api.Respond(w, plan)
}

func (h *Handler) DeletePlan(w http.ResponseWriter, r *http.Request) {
	userID, _ := auth.UserIDFromCtx(r.Context())
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		http.Error(w, "invalid id", http.StatusBadRequest)
		return
	}
	if err := h.svc.DeletePlan(id, userID); err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) ListDays(w http.ResponseWriter, r *http.Request) {
	planID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		http.Error(w, "invalid id", http.StatusBadRequest)
		return
	}
	days, err := h.svc.ListDays(planID)
	if err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	api.Respond(w, days)
}

func (h *Handler) CreateDay(w http.ResponseWriter, r *http.Request) {
	planID, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		http.Error(w, "invalid id", http.StatusBadRequest)
		return
	}
	var body struct {
		DayOfWeek int `json:"day_of_week"`
	}
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "bad request", http.StatusBadRequest)
		return
	}
	day, err := h.svc.CreateDay(planID, body.DayOfWeek)
	if err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusCreated)
	api.Respond(w, day)
}

func (h *Handler) AddExercise(w http.ResponseWriter, r *http.Request) {
	dayID, err := uuid.Parse(chi.URLParam(r, "dayId"))
	if err != nil {
		http.Error(w, "invalid day id", http.StatusBadRequest)
		return
	}
	var body PlannedExercise
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		http.Error(w, "bad request", http.StatusBadRequest)
		return
	}
	body.DayID = dayID
	ex, err := h.svc.AddExercise(body)
	if err != nil {
		http.Error(w, "internal error", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusCreated)
	api.Respond(w, ex)
}
