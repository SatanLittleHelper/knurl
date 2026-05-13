package sets

import (
	"encoding/json"
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/google/uuid"
	"github.com/satanlittlehelper/knurl/backend/internal/api"
)

type Handler struct{ svc *Service }

func NewHandler(svc *Service) *Handler { return &Handler{svc: svc} }

func (h *Handler) List(w http.ResponseWriter, r *http.Request) {
	sessionID, err := uuid.Parse(chi.URLParam(r, "sessionId"))
	if err != nil {
		api.Error(w, http.StatusBadRequest, "invalid session id")
		return
	}
	logs, err := h.svc.List(sessionID)
	if err != nil {
		api.Error(w, http.StatusInternalServerError, "internal error")
		return
	}
	api.Respond(w, http.StatusOK, logs)
}

func (h *Handler) Create(w http.ResponseWriter, r *http.Request) {
	sessionID, err := uuid.Parse(chi.URLParam(r, "sessionId"))
	if err != nil {
		api.Error(w, http.StatusBadRequest, "invalid session id")
		return
	}
	var body SetLog
	if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
		api.Error(w, http.StatusBadRequest, "bad request")
		return
	}
	log, err := h.svc.Create(sessionID, body)
	if err != nil {
		api.Error(w, http.StatusInternalServerError, "internal error")
		return
	}
	api.Respond(w, http.StatusCreated, log)
}

func (h *Handler) Update(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		api.Error(w, http.StatusBadRequest, "invalid id")
		return
	}
	var patch SetLog
	if err := json.NewDecoder(r.Body).Decode(&patch); err != nil {
		api.Error(w, http.StatusBadRequest, "bad request")
		return
	}
	log, err := h.svc.Update(id, patch)
	if err != nil {
		api.Error(w, http.StatusInternalServerError, "internal error")
		return
	}
	api.Respond(w, http.StatusOK, log)
}

func (h *Handler) Delete(w http.ResponseWriter, r *http.Request) {
	id, err := uuid.Parse(chi.URLParam(r, "id"))
	if err != nil {
		api.Error(w, http.StatusBadRequest, "invalid id")
		return
	}
	if err := h.svc.Delete(id); err != nil {
		api.Error(w, http.StatusInternalServerError, "internal error")
		return
	}
	api.NoContent(w)
}
