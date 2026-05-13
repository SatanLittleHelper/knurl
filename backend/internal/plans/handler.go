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
