package exercises

import (
	"net/http"

	"github.com/satanlittlehelper/knurl/backend/internal/api"
)

type Handler struct {
	svc *Service
}

func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

func (h *Handler) List(w http.ResponseWriter, r *http.Request) {
	muscle := r.URL.Query().Get("muscle")
	exercises, err := h.svc.List(r.Context(), muscle)
	if err != nil {
		api.Error(w, http.StatusInternalServerError, "internal error")
		return
	}
	api.Respond(w, http.StatusOK, exercises)
}
